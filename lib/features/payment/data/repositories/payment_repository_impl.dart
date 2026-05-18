import 'package:billing_app/core/data/hive_database.dart';
import '../../domain/entities/momo_transaction.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/momo_transaction_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
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
}
