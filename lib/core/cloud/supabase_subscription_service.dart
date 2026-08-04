import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:billing_app/core/data/hive_database.dart';
import '../../features/subscription/domain/subscription.dart';
import '../services/subscription_service.dart';

/// Couche cloud pour les abonnements Gestock+.
///
/// Activation  : verifyAndActivate() → Edge Function verify-subscription
///               → vérifie paiement FreemoPay API → écrit dans Supabase
/// Synchronisation : pullAndCache() / ensureTrialOrSync() → lit/écrit depuis Supabase → écrit dans Hive
class SupabaseSubscriptionService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Assure qu'une ligne d'abonnement existe dans la table Supabase 'subscriptions'.
  /// Si absente (nouvel inscrit / boutique en essai), insère automatiquement la ligne d'essai (30 jours)
  /// dans la base de données Supabase avec shop_id, tier ('trial'), start_date et expiry_date.
  /// Si présente, synchronise les dates et l'état vers Hive.
  Future<void> ensureTrialOrSync(String shopId) async {
    String validShopId = shopId;

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final member = await _client
            .from('shop_members')
            .select('shop_id')
            .eq('user_id', user.id)
            .maybeSingle();
        if (member != null && member['shop_id'] != null) {
          validShopId = member['shop_id'] as String;
          await HiveDatabase.settingsBox.put('cloud_shop_id', validShopId);
        }
      }

      if (validShopId.isEmpty) return;

      final row = await _client
          .from('subscriptions')
          .select()
          .eq('shop_id', validShopId)
          .maybeSingle();

      if (row == null) {
        final startRaw = HiveDatabase.settingsBox.get('subscription_trial_start') as String?;
        final startDate = startRaw != null ? DateTime.parse(startRaw) : DateTime.now();
        if (startRaw == null) {
          await HiveDatabase.settingsBox.put('subscription_trial_start', startDate.toIso8601String());
        }
        final expiryDate = startDate.add(const Duration(days: 30));

        await _client.from('subscriptions').upsert({
          'shop_id': validShopId,
          'tier': 'trial',
          'billing_cycle': 'monthly',
          'start_date': startDate.toIso8601String(),
          'expiry_date': expiryDate.toIso8601String(),
          'freemopay_reference': 'TRIAL_30_DAYS',
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'shop_id');
      } else {
        final startRaw = row['start_date'] as String?;
        final expiryRaw = row['expiry_date'] as String?;
        if (startRaw != null && expiryRaw != null) {
          final info = SubscriptionInfo(
            tier: SubscriptionTier.values.firstWhere(
              (t) => t.name == (row['tier'] as String),
              orElse: () => SubscriptionTier.trial,
            ),
            cycle: BillingCycle.values.firstWhere(
              (c) => c.name == (row['billing_cycle'] as String? ?? 'monthly'),
              orElse: () => BillingCycle.monthly,
            ),
            startDate: DateTime.parse(startRaw),
            expiryDate: DateTime.parse(expiryRaw),
            freemopayReference: row['freemopay_reference'] as String?,
          );
          await SubscriptionService.save(info);
        }
      }
    } catch (_) {}
  }

  // ── Activation via Edge Function ──────────────────────────────────────────

  /// Vérifie la référence FreemoPay côté serveur et active l'abonnement.
  /// Retourne [null] si l'activation a réussi, ou un message d'erreur.
  Future<String?> verifyAndActivate({
    required String shopId,
    required String reference,
    required SubscriptionTier tier,
    required BillingCycle cycle,
  }) async {
    String validShopId = shopId;
    final user = _client.auth.currentUser;
    if (user != null) {
      final member = await _client
          .from('shop_members')
          .select('shop_id')
          .eq('user_id', user.id)
          .maybeSingle();
      if (member != null && member['shop_id'] != null) {
        validShopId = member['shop_id'] as String;
      }
    }

    if (validShopId.isEmpty) {
      return 'Boutique non connectée. Reconnectez-vous et réessayez.';
    }

    try {
      final response = await _client.functions.invoke(
        'verify-subscription',
        body: {
          'reference': reference,
          'shop_id':   validShopId,
          'tier':      tier.name,
          'cycle':     cycle.name,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) return 'Réponse invalide du serveur';

      final startRaw  = data['start_date'] as String?;
      final expiryRaw = data['expiry_date'] as String?;
      if (startRaw == null || expiryRaw == null) return 'Données d\'activation incomplètes';

      final info = SubscriptionInfo(
        tier:               tier,
        cycle:              cycle,
        startDate:          DateTime.parse(startRaw),
        expiryDate:         DateTime.parse(expiryRaw),
        freemopayReference: reference,
      );

      await SubscriptionService.save(info);
      return null;

    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map) {
        return details['error'] as String? ?? 'Vérification du paiement échouée';
      }
      return 'Paiement non valide ou référence introuvable';
    } catch (_) {
      return 'Pas de connexion. Vérifiez votre internet et réessayez.';
    }
  }

  // ── Synchronisation ────────────────────────────────────────────────────────

  Future<void> pullAndCache(String shopId) async {
    await ensureTrialOrSync(shopId);
  }
}
