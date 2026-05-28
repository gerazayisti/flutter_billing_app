import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/subscription/domain/subscription.dart';
import '../services/subscription_service.dart';

/// Couche cloud pour les abonnements Gestock+.
///
/// Activation  : verifyAndActivate() → Edge Function verify-subscription
///               → vérifie paiement FreemoPay API → écrit dans Supabase
/// Synchronisation : pullAndCache() → lit depuis Supabase → écrit dans Hive
class SupabaseSubscriptionService {
  SupabaseClient get _client => Supabase.instance.client;

  // ── Activation via Edge Function ──────────────────────────────────────────

  /// Vérifie la référence FreemoPay côté serveur et active l'abonnement.
  /// Retourne [null] si l'activation a réussi, ou un message d'erreur.
  Future<String?> verifyAndActivate({
    required String shopId,
    required String reference,
    required SubscriptionTier tier,
    required BillingCycle cycle,
  }) async {
    if (shopId.isEmpty) {
      return 'Boutique non connectée. Reconnectez-vous et réessayez.';
    }

    try {
      final response = await _client.functions.invoke(
        'verify-subscription',
        body: {
          'reference': reference,
          'shop_id':   shopId,
          'tier':      tier.name,
          'cycle':     cycle.name,
        },
      );

      // La fonction retourne 200 avec { start_date, expiry_date, tier, cycle }
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

      // Sauvegarde locale dans Hive
      await SubscriptionService.save(info);
      return null; // succès

    } on FunctionException catch (e) {
      // La Edge Function a retourné une erreur (400, 500)
      final details = e.details;
      if (details is Map) {
        return details['error'] as String? ?? 'Vérification du paiement échouée';
      }
      return 'Paiement non valide ou référence introuvable';
    } catch (_) {
      return 'Pas de connexion. Vérifiez votre internet et réessayez.';
    }
  }

  // ── Synchronisation au login ──────────────────────────────────────────────

  /// Télécharge l'abonnement depuis Supabase et le sauvegarde dans Hive.
  /// Ignoré silencieusement si hors-ligne ou si aucun abonnement actif.
  Future<void> pullAndCache(String shopId) async {
    try {
      final row = await _client
          .from('subscriptions')
          .select()
          .eq('shop_id', shopId)
          .maybeSingle();

      if (row == null) return;

      final startRaw  = row['start_date'] as String?;
      final expiryRaw = row['expiry_date'] as String?;
      if (startRaw == null || expiryRaw == null) return;

      final info = SubscriptionInfo(
        tier: SubscriptionTier.values.firstWhere(
          (t) => t.name == (row['tier'] as String),
          orElse: () => SubscriptionTier.trial,
        ),
        cycle: BillingCycle.values.firstWhere(
          (c) => c.name == (row['billing_cycle'] as String? ?? 'monthly'),
          orElse: () => BillingCycle.monthly,
        ),
        startDate:          DateTime.parse(startRaw),
        expiryDate:         DateTime.parse(expiryRaw),
        freemopayReference: row['freemopay_reference'] as String?,
      );

      await SubscriptionService.save(info);
    } catch (_) {}
  }
}
