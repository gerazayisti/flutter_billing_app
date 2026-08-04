import 'package:supabase_flutter/supabase_flutter.dart';

class FreemoPayRemoteDataSource {
  final SupabaseClient _client;

  FreemoPayRemoteDataSource(this._client);

  /// Initie un dépôt / paiement Mobile Money via FreeMoPay API
  Future<Map<String, dynamic>> initiateDeposit({
    required String saleId,
    required double amount,
    required String phoneNumberRaw,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'freemopay-initiate-deposit',
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
      if (response.status == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback sur pawapay-initiate-deposit si la fonction freemopay n'est pas encore déployée
    }

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
      throw Exception('Erreur initiation paiement FreeMoPay: ${response.data}');
    }
    return response.data as Map<String, dynamic>;
  }

  /// Écoute Supabase Realtime sur la ligne de paiement Mobile Money
  Stream<Map<String, dynamic>> watchDepositStatus(String depositId) {
    return _client
        .from('mobile_money_payments')
        .stream(primaryKey: ['id'])
        .eq('deposit_id', depositId)
        .map((rows) => rows.first);
  }

  /// Récupère manuellement le statut depuis l'API FreeMoPay
  Future<Map<String, dynamic>> checkDepositStatus(String depositId) async {
    try {
      final response = await _client.functions.invoke(
        'freemopay-check-status',
        body: {'depositId': depositId},
      );
      if (response.status == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback sur pawapay-check-status
    }

    final response = await _client.functions.invoke(
      'pawapay-check-status',
      body: {'depositId': depositId},
    );

    if (response.status != 200) {
      throw Exception('Erreur de vérification FreeMoPay: ${response.data}');
    }
    return response.data as Map<String, dynamic>;
  }

  /// Récupère le solde virtuel actuel d'une boutique
  Future<double> getShopBalance(String shopId) async {
    final exact = await _client
        .from('shop_balances')
        .select('balance')
        .eq('shop_id', shopId)
        .maybeSingle();
    if (exact != null) return (exact['balance'] as num).toDouble();

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

    final all = await _client.from('shop_balances').select('shop_id, balance');
    if (all != null && (all as List).length == 1) {
      return (all.first['balance'] as num).toDouble();
    }

    return 0.0;
  }

  /// Initie un retrait (payout) de boutique via FreeMoPay
  Future<Map<String, dynamic>> initiatePayout({
    required String shopId,
    required double amountRequested,
    required String phoneNumberRaw,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'freemopay-initiate-payout',
        body: {
          'shopId': shopId,
          'amountRequested': amountRequested,
          'phoneNumberRaw': phoneNumberRaw,
        },
      );
      if (response.status == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback
    }

    final response = await _client.functions.invoke(
      'pawapay-initiate-payout',
      body: {
        'shopId': shopId,
        'amountRequested': amountRequested,
        'phoneNumberRaw': phoneNumberRaw,
      },
    );

    if (response.status != 200) {
      throw Exception('Erreur initiation retrait FreeMoPay: ${response.data}');
    }
    return response.data as Map<String, dynamic>;
  }

  /// Récupère manuellement le statut d'un retrait FreeMoPay
  Future<Map<String, dynamic>> checkPayoutStatus(String payoutId) async {
    try {
      final response = await _client.functions.invoke(
        'freemopay-check-payout-status',
        body: {'payoutId': payoutId},
      );
      if (response.status == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback
    }

    final response = await _client.functions.invoke(
      'pawapay-check-payout-status',
      body: {'payoutId': payoutId},
    );

    if (response.status != 200) {
      throw Exception('Erreur de vérification du retrait: ${response.data}');
    }
    return response.data as Map<String, dynamic>;
  }
}
