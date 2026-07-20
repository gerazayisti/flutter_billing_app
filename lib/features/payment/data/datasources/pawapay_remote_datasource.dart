import 'package:supabase_flutter/supabase_flutter.dart';

class PawaPayRemoteDataSource {
  final SupabaseClient _client;

  PawaPayRemoteDataSource(this._client);

  Future<Map<String, dynamic>> initiateDeposit({
    required String saleId,
    required double amount,
    required String phoneNumberRaw,
  }) async {
    final response = await _client.functions.invoke(
      'pawapay-initiate-deposit',
      body: {
        'saleId': saleId,
        'amount': amount,
        'phoneNumberRaw': phoneNumberRaw,
        'metadata': [
          {'team': 'gestock_plus'},
          {'saleId': saleId}
        ]
      },
    );

    if (response.status != 200) {
      throw Exception('Erreur initiation paiement: ${response.data}');
    }
    return response.data as Map<String, dynamic>;
  }

  /// Écoute Supabase Realtime sur la ligne de paiement
  Stream<Map<String, dynamic>> watchDepositStatus(String depositId) {
    return _client
        .from('mobile_money_payments')
        .stream(primaryKey: ['id'])
        .eq('deposit_id', depositId)
        .map((rows) => rows.first);
  }

  /// Récupère manuellement le statut depuis l'API de pawaPay via l'Edge Function de vérification
  Future<Map<String, dynamic>> checkDepositStatus(String depositId) async {
    final response = await _client.functions.invoke(
      'pawapay-check-status',
      body: {'depositId': depositId},
    );

    if (response.status != 200) {
      throw Exception('Erreur de polling de transaction: ${response.data}');
    }
    return response.data as Map<String, dynamic>;
  }

  /// Récupère le solde virtuel actuel d'une boutique.
  /// Cherche d'abord par correspondance exacte, puis par préfixe,
  /// puis retourne la somme de tous les soldes si un seul shop existe.
  Future<double> getShopBalance(String shopId) async {
    // 1. Correspondance exacte
    final exact = await _client
        .from('shop_balances')
        .select('balance')
        .eq('shop_id', shopId)
        .maybeSingle();
    if (exact != null) return (exact['balance'] as num).toDouble();

    // 2. Correspondance par préfixe (le shopId est un préfixe du shop_id en BD)
    final prefixed = await _client
        .from('shop_balances')
        .select('shop_id, balance')
        .ilike('shop_id', '$shopId%');
    if (prefixed != null && (prefixed as List).isNotEmpty) {
      double total = 0.0;
      for (final row in prefixed) {
        total += (row['balance'] as num).toDouble();
      }
      return total;
    }

    // 3. Si un seul shop dans la table, retourner son solde
    final all = await _client
        .from('shop_balances')
        .select('shop_id, balance');
    if (all != null && (all as List).length == 1) {
      return (all.first['balance'] as num).toDouble();
    }

    return 0.0;
  }

  /// Initie un retrait (payout) de boutique
  Future<Map<String, dynamic>> initiatePayout({
    required String shopId,
    required double amountRequested,
    required String phoneNumberRaw,
  }) async {
    final response = await _client.functions.invoke(
      'pawapay-initiate-payout',
      body: {
        'shopId': shopId,
        'amountRequested': amountRequested,
        'phoneNumberRaw': phoneNumberRaw,
        // Format Liste d'objets requis par l'API pawaPay v2 / Hackathon
        'metadata': [
          {'team': 'gestock_plus'},
          {'shopId': shopId}
        ]
      },
    );

    if (response.status != 200) {
      throw Exception('Erreur initiation retrait: ${response.data}');
    }
    return response.data as Map<String, dynamic>;
  }

  /// Récupère manuellement le statut d'un retrait (payout)
  Future<Map<String, dynamic>> checkPayoutStatus(String payoutId) async {
    final response = await _client.functions.invoke(
      'pawapay-check-payout-status',
      body: {'payoutId': payoutId},
    );

    if (response.status != 200) {
      throw Exception('Erreur polling retrait: ${response.data}');
    }
    return response.data as Map<String, dynamic>;
  }

  /// Écoute les changements sur un retrait spécifique
  Stream<Map<String, dynamic>> watchWithdrawalStatus(String payoutId) {
    return _client
        .from('shop_withdrawals')
        .stream(primaryKey: ['id'])
        .eq('payout_id', payoutId)
        .map((rows) => rows.first);
  }

  /// Récupère tous les retraits d'une boutique
  Future<List<Map<String, dynamic>>> getShopWithdrawals(String shopId) async {
    final response = await _client
        .from('shop_withdrawals')
        .select('*')
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
}
