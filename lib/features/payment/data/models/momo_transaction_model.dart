import 'package:hive/hive.dart';
import '../../domain/entities/momo_transaction.dart';

part 'momo_transaction_model.g.dart';

@HiveType(typeId: 8)
class MomoTransactionModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String? orderId;
  @HiveField(2)
  final String operatorName; // 'orange' | 'mtn'
  @HiveField(3)
  final String customerPhone;
  @HiveField(4)
  final double amount;
  @HiveField(5)
  String statusName; // stored as string for forward compat
  @HiveField(6)
  String? reference;
  @HiveField(7)
  String? externalId;
  @HiveField(8)
  final DateTime initiatedAt;
  @HiveField(9)
  DateTime? confirmedAt;
  @HiveField(10)
  String? errorMessage;
  @HiveField(11)
  final String cashierId;

  MomoTransactionModel({
    required this.id,
    this.orderId,
    required this.operatorName,
    required this.customerPhone,
    required this.amount,
    required this.statusName,
    this.reference,
    this.externalId,
    required this.initiatedAt,
    this.confirmedAt,
    this.errorMessage,
    required this.cashierId,
  });

  factory MomoTransactionModel.fromEntity(MomoTransaction t) {
    return MomoTransactionModel(
      id: t.id,
      orderId: t.orderId,
      operatorName: t.operator.name,
      customerPhone: t.customerPhone,
      amount: t.amount,
      statusName: t.status.name,
      reference: t.reference,
      externalId: t.externalId,
      initiatedAt: t.initiatedAt,
      confirmedAt: t.confirmedAt,
      errorMessage: t.errorMessage,
      cashierId: t.cashierId,
    );
  }

  MomoTransaction toEntity() {
    return MomoTransaction(
      id: id,
      orderId: orderId,
      operator: MomoOperator.values.firstWhere(
          (e) => e.name == operatorName,
          orElse: () => MomoOperator.mtn),
      customerPhone: customerPhone,
      amount: amount,
      status: MomoStatus.values.firstWhere(
          (e) => e.name == statusName,
          orElse: () => MomoStatus.pending),
      reference: reference,
      externalId: externalId,
      initiatedAt: initiatedAt,
      confirmedAt: confirmedAt,
      errorMessage: errorMessage,
      cashierId: cashierId,
    );
  }
}
