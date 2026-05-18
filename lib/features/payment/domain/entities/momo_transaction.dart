import 'package:equatable/equatable.dart';

enum MomoOperator { orange, mtn }

enum MomoStatus { pending, confirmed, failed, manualConfirm, cancelled }

class MomoTransaction extends Equatable {
  final String id;
  final String? orderId;
  final MomoOperator operator;
  final String customerPhone;
  final double amount;
  final MomoStatus status;
  final String? reference;
  final String? externalId;
  final DateTime initiatedAt;
  final DateTime? confirmedAt;
  final String? errorMessage;
  final String cashierId;

  const MomoTransaction({
    required this.id,
    this.orderId,
    required this.operator,
    required this.customerPhone,
    required this.amount,
    required this.status,
    this.reference,
    this.externalId,
    required this.initiatedAt,
    this.confirmedAt,
    this.errorMessage,
    required this.cashierId,
  });

  MomoTransaction copyWith({
    String? orderId,
    MomoStatus? status,
    String? reference,
    String? externalId,
    DateTime? confirmedAt,
    String? errorMessage,
  }) {
    return MomoTransaction(
      id: id,
      orderId: orderId ?? this.orderId,
      operator: operator,
      customerPhone: customerPhone,
      amount: amount,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      externalId: externalId ?? this.externalId,
      initiatedAt: initiatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      cashierId: cashierId,
    );
  }

  bool get isTerminal =>
      status == MomoStatus.confirmed ||
      status == MomoStatus.failed ||
      status == MomoStatus.cancelled ||
      status == MomoStatus.manualConfirm;

  @override
  List<Object?> get props => [id, status, reference, confirmedAt];
}
