import '../entities/momo_transaction.dart';
import '../entities/mobile_money_payment.dart';
import '../entities/shop_withdrawal.dart';

abstract class PaymentRepository {
  Future<void> saveTransaction(MomoTransaction transaction);
  Future<void> updateTransaction(MomoTransaction transaction);
  List<MomoTransaction> getTransactionsForOrder(String orderId);
  List<MomoTransaction> getRecentTransactions({int limit = 50});
  MomoTransaction? getTransactionById(String id);

  Future<MobileMoneyPayment> initiatePawaPayDeposit({
    required String saleId,
    required double amount,
    required String phoneNumberRaw,
  });

  Stream<MobileMoneyPayment> watchPawaPayDepositStatus(String depositId);

  Future<MobileMoneyPayment> checkPawaPayDepositStatus(String depositId);

  // --- Gestion des Retraits (Payouts) & Soldes ---
  Future<double> getShopBalance(String shopId);

  Future<ShopWithdrawal> initiatePawaPayPayout({
    required String shopId,
    required double amountRequested,
    required String phoneNumberRaw,
  });

  Stream<ShopWithdrawal> watchPawaPayPayoutStatus(String payoutId);

  Future<ShopWithdrawal> checkPawaPayPayoutStatus(String payoutId);
}
