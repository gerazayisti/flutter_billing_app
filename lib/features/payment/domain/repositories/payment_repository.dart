import '../entities/momo_transaction.dart';

abstract class PaymentRepository {
  Future<void> saveTransaction(MomoTransaction transaction);
  Future<void> updateTransaction(MomoTransaction transaction);
  List<MomoTransaction> getTransactionsForOrder(String orderId);
  List<MomoTransaction> getRecentTransactions({int limit = 50});
  MomoTransaction? getTransactionById(String id);
}
