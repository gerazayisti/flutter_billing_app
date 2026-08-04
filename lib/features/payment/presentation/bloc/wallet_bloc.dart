import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/data/hive_database.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/entities/shop_withdrawal.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final PaymentRepository paymentRepository;
  Timer? _pollingTimer;

  WalletBloc({required this.paymentRepository}) : super(const WalletState()) {
    on<LoadWalletDataEvent>(_onLoadWalletData);
    on<InitiateWithdrawalEvent>(_onInitiateWithdrawal);
    on<CheckPendingWithdrawalsEvent>(_onCheckPendingWithdrawals);
  }

  Future<void> _onLoadWalletData(
      LoadWalletDataEvent event, Emitter<WalletState> emit) async {
    emit(state.copyWith(status: WalletStatus.loading, errorMessage: ''));
    try {
      final s = HiveDatabase.settingsBox;
      var shopId = s.get('cloud_shop_id', defaultValue: '') as String;
      
      final localShop = HiveDatabase.shopBox.values.isNotEmpty ? HiveDatabase.shopBox.values.first : null;
      final localShopName = localShop != null ? localShop.name.toLowerCase().replaceAll(RegExp(r'\s+'), '_') : '';
      
      if (shopId.isEmpty) {
        if (localShopName.isEmpty) {
          throw Exception("Boutique non identifiée.");
        }
        shopId = localShopName;
      }

      final resp = await Supabase.instance.client.functions.invoke(
        'pawapay-get-balance',
        body: {'shopId': shopId},
      );

      double balance = 0.0;
      String actualShopId = shopId;

      if (resp.status == 200) {
        final data = resp.data as Map<String, dynamic>;
        balance = (data['balance'] as num? ?? 0).toDouble();
        actualShopId = data['shop_id'] as String? ?? shopId;
        if (data['shop_id'] != null) s.put('cloud_shop_id', data['shop_id']);
      }

      final query = Supabase.instance.client.from('shop_withdrawals').select();
      
      final List<dynamic> remoteData = await query
          .or('shop_id.eq.$actualShopId,shop_id.eq.$shopId,shop_id.eq.$localShopName')
          .order('created_at', ascending: false);

      final withdrawals = remoteData.map((json) => ShopWithdrawal(
        payoutId: json['payout_id'] ?? '',
        shopId: json['shop_id'] ?? '',
        phoneNumber: json['phone_number'] ?? '',
        provider: json['provider'] ?? '',
        grossAmount: (json['gross_amount'] as num? ?? 0).toDouble(),
        feeAmount: (json['fee_amount'] as num? ?? 0).toDouble(),
        netAmount: (json['net_amount'] as num? ?? 0).toDouble(),
        status: _mapStatus(json['status']),
        createdAt: DateTime.parse(json['created_at']),
      )).toList();

      emit(state.copyWith(
        status: WalletStatus.loaded,
        balance: balance,
        withdrawals: withdrawals,
        shopId: actualShopId,
      ));

      _startPollingIfNeeded();
    } catch (e) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: "Impossible de récupérer le solde. Vérifiez votre connexion.",
      ));
      _loadLocalWithdrawals(emit);
    }
  }

  void _loadLocalWithdrawals(Emitter<WalletState> emit) {
    final items = HiveDatabase.shopWithdrawalsBox.values
        .map((m) => m.toEntity())
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    emit(state.copyWith(withdrawals: items));
  }

  Future<void> _onInitiateWithdrawal(
      InitiateWithdrawalEvent event, Emitter<WalletState> emit) async {
    emit(state.copyWith(isWithdrawing: true, withdrawalSuccessMessage: null, withdrawalErrorMessage: null));
    try {
      await paymentRepository.initiatePawaPayPayout(
        shopId: state.shopId,
        amountRequested: event.amount,
        phoneNumberRaw: event.phoneNumber,
      );
      
      emit(state.copyWith(
        isWithdrawing: false,
        withdrawalSuccessMessage: 'Retrait initié avec succès !',
      ));
      add(LoadWalletDataEvent()); // Refresh balance and list
    } catch (e) {
      emit(state.copyWith(
        isWithdrawing: false,
        withdrawalErrorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCheckPendingWithdrawals(
      CheckPendingWithdrawalsEvent event, Emitter<WalletState> emit) async {
    final pending = state.withdrawals.where((w) =>
      w.status == WithdrawalStatus.pending || w.status == WithdrawalStatus.accepted
    ).toList();

    if (pending.isEmpty) {
      _pollingTimer?.cancel();
      return;
    }

    bool hasChanged = false;
    for (var w in pending) {
      try {
        final updated = await paymentRepository.checkPawaPayPayoutStatus(w.payoutId);
        if (updated.status != w.status) {
          hasChanged = true;
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    }

    if (hasChanged) {
      add(LoadWalletDataEvent());
    }
  }

  void _startPollingIfNeeded() {
    _pollingTimer?.cancel();
    final hasPending = state.withdrawals.any((w) =>
      w.status == WithdrawalStatus.pending || w.status == WithdrawalStatus.accepted
    );
    
    if (hasPending) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        add(CheckPendingWithdrawalsEvent());
      });
    }
  }

  WithdrawalStatus _mapStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED': return WithdrawalStatus.completed;
      case 'ACCEPTED': return WithdrawalStatus.accepted;
      case 'FAILED': return WithdrawalStatus.failed;
      default: return WithdrawalStatus.pending;
    }
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
