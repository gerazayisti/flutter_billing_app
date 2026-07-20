import 'package:billing_app/core/data/hive_database.dart';
import '../../domain/entities/momo_transaction.dart';
import '../../domain/entities/mobile_money_payment.dart';
import '../../domain/entities/shop_withdrawal.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/momo_transaction_model.dart';
import '../models/shop_withdrawal_model.dart';
import '../datasources/pawapay_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PawaPayRemoteDataSource _remote;

  PaymentRepositoryImpl(this._remote);

  @override
  Future<void> saveTransaction(MomoTransaction transaction) async {
    final model = MomoTransactionModel.fromEntity(transaction);
    await HiveDatabase.momoTransactionsBox.put(transaction.id, model);
  }

  @override
  Future<void> updateTransaction(MomoTransaction transaction) async {
    final existing = HiveDatabase.momoTransactionsBox.get(transaction.id);
    if (existing == null) return;

    existing.orderId = transaction.orderId;
    existing.statusName = transaction.status.name;
    existing.reference = transaction.reference;
    existing.externalId = transaction.externalId;
    existing.confirmedAt = transaction.confirmedAt;
    existing.errorMessage = transaction.errorMessage;
    await existing.save();
  }

  @override
  List<MomoTransaction> getTransactionsForOrder(String orderId) {
    return HiveDatabase.momoTransactionsBox.values
        .where((m) => m.orderId == orderId)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  List<MomoTransaction> getRecentTransactions({int limit = 50}) {
    final all = HiveDatabase.momoTransactionsBox.values.toList();
    all.sort((a, b) => b.initiatedAt.compareTo(a.initiatedAt));
    return all.take(limit).map((m) => m.toEntity()).toList();
  }

  @override
  MomoTransaction? getTransactionById(String id) {
    return HiveDatabase.momoTransactionsBox.get(id)?.toEntity();
  }

  @override
  Future<MobileMoneyPayment> initiatePawaPayDeposit({
    required String saleId,
    required double amount,
    required String phoneNumberRaw,
  }) async {
    final json = await _remote.initiateDeposit(
      saleId: saleId,
      amount: amount,
      phoneNumberRaw: phoneNumberRaw,
    );

    if (json['status'] == 'REJECTED') {
      return MobileMoneyPayment(
        depositId: json['depositId'],
        status: PaymentStatus.failed,
        pinPrompt: json['pinPrompt'] ?? 'AUTOMATIC',
        pinPromptRevivable: json['pinPromptRevivable'] ?? false,
        failureCode: json['failureReason']?['failureCode'],
        failureMessage: json['failureReason']?['failureMessage'],
      );
    }

    return MobileMoneyPayment(
      depositId: json['depositId'],
      status: _parseStatus(json['status'] as String? ?? 'ACCEPTED'),
      pinPrompt: json['pinPrompt'] ?? 'AUTOMATIC',
      pinPromptRevivable: json['pinPromptRevivable'] ?? false,
      pinPromptInstructions: json['pinPromptInstructions'],
      nameDisplayedToCustomer: json['nameDisplayedToCustomer'],
    );
  }

  @override
  Stream<MobileMoneyPayment> watchPawaPayDepositStatus(String depositId) {
    return _remote.watchDepositStatus(depositId).map((row) {
      final status = _parseStatus(row['status'] as String);
      return MobileMoneyPayment(
        depositId: row['deposit_id'],
        status: status,
        pinPrompt: 'AUTOMATIC',
        pinPromptRevivable: false,
        failureCode: row['failure_code'],
        failureMessage: row['failure_message'],
      );
    });
  }

  @override
  Future<MobileMoneyPayment> checkPawaPayDepositStatus(String depositId) async {
    final json = await _remote.checkDepositStatus(depositId);
    final status = _parseStatus(json['status'] as String? ?? 'ACCEPTED');

    return MobileMoneyPayment(
      depositId: json['depositId'],
      status: status,
      pinPrompt: 'AUTOMATIC',
      pinPromptRevivable: false,
      failureCode: json['failureReason']?['failureCode'],
      failureMessage: json['failureReason']?['failureMessage'],
    );
  }

  @override
  Future<double> getShopBalance(String shopId) async {
    return _remote.getShopBalance(shopId);
  }

  @override
  Future<ShopWithdrawal> initiatePawaPayPayout({
    required String shopId,
    required double amountRequested,
    required String phoneNumberRaw,
  }) async {
    final json = await _remote.initiatePayout(
      shopId: shopId,
      amountRequested: amountRequested,
      phoneNumberRaw: phoneNumberRaw,
    );

    final withdrawal = ShopWithdrawal(
      payoutId: json['payoutId'],
      shopId: shopId,
      phoneNumber: phoneNumberRaw,
      provider: json['provider'] ?? 'UNKNOWN',
      grossAmount: amountRequested,
      feeAmount: (json['feeAmount'] as num?)?.toDouble() ?? (amountRequested * 0.01),
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? (amountRequested * 0.99),
      status: _parseWithdrawalStatus(json['status'] as String? ?? 'ACCEPTED'),
      failureCode: json['failureReason']?['failureCode'],
      failureMessage: json['failureReason']?['failureMessage'],
      createdAt: DateTime.now(),
    );

    // Persister localement pour le suivi
    await HiveDatabase.shopWithdrawalsBox.put(
      withdrawal.payoutId,
      ShopWithdrawalModel.fromEntity(withdrawal),
    );

    return withdrawal;
  }

  @override
  Stream<ShopWithdrawal> watchPawaPayPayoutStatus(String payoutId) {
    return _remote.watchWithdrawalStatus(payoutId).map((row) {
      final status = _parseWithdrawalStatus(row['status'] as String);
      return ShopWithdrawal(
        payoutId: row['payout_id'],
        shopId: row['shop_id'],
        phoneNumber: row['phone_number'],
        provider: row['provider'],
        grossAmount: (row['gross_amount'] as num).toDouble(),
        feeAmount: (row['fee_amount'] as num).toDouble(),
        netAmount: (row['net_amount'] as num).toDouble(),
        status: status,
        failureCode: row['failure_code'],
        failureMessage: row['failure_message'],
        createdAt: DateTime.parse(row['created_at']),
      );
    });
  }

  @override
  Future<ShopWithdrawal> checkPawaPayPayoutStatus(String payoutId) async {
    final json = await _remote.checkPayoutStatus(payoutId);
    final status = _parseWithdrawalStatus(json['status'] as String? ?? 'ACCEPTED');

    final existing = HiveDatabase.shopWithdrawalsBox.get(payoutId);
    
    final updated = ShopWithdrawal(
      payoutId: payoutId,
      shopId: json['metadata']?['shopId'] ?? existing?.shopId ?? 'UNKNOWN',
      phoneNumber: json['recipient']?['accountDetails']?['phoneNumber'] ?? existing?.phoneNumber ?? '',
      provider: json['recipient']?['accountDetails']?['provider'] ?? existing?.provider ?? '',
      grossAmount: double.tryParse(json['metadata']?['grossAmount'] ?? '0') ?? existing?.grossAmount ?? 0,
      feeAmount: existing?.feeAmount ?? 0.0,
      netAmount: double.tryParse(json['amount'] ?? '0') ?? existing?.netAmount ?? 0,
      status: status,
      failureCode: json['failureReason']?['failureCode'],
      failureMessage: json['failureReason']?['failureMessage'],
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    // Mettre à jour le cache local
    await HiveDatabase.shopWithdrawalsBox.put(
      payoutId,
      ShopWithdrawalModel.fromEntity(updated),
    );

    return updated;
  }

  WithdrawalStatus _parseWithdrawalStatus(String s) {
    switch (s) {
      case 'COMPLETED':
        return WithdrawalStatus.completed;
      case 'FAILED':
        return WithdrawalStatus.failed;
      case 'PROCESSING':
        return WithdrawalStatus.pending;
      case 'ACCEPTED':
      case 'ENQUEUED':
        return WithdrawalStatus.accepted;
      default:
        return WithdrawalStatus.pending;
    }
  }

  PaymentStatus _parseStatus(String s) {
    switch (s) {
      case 'COMPLETED':
        return PaymentStatus.completed;
      case 'FAILED':
        return PaymentStatus.failed;
      case 'PROCESSING':
        return PaymentStatus.processing;
      case 'ACCEPTED':
        return PaymentStatus.accepted;
      default:
        return PaymentStatus.pending;
    }
  }
}
