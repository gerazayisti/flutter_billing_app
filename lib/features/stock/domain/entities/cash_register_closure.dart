import 'package:equatable/equatable.dart';

class CashRegisterClosure extends Equatable {
  static const double tvaRate = 0.1925;

  final String id;
  final DateTime closedAt;
  final DateTime periodStart;
  final String cashierId;
  final double cashTotal;
  final double orangeMoneyTotal;
  final double mtnMomoTotal;
  final double cardTotal;
  final double grandTotal;
  final int transactionCount;
  final String? notes;

  const CashRegisterClosure({
    required this.id,
    required this.closedAt,
    required this.periodStart,
    required this.cashierId,
    required this.cashTotal,
    required this.orangeMoneyTotal,
    required this.mtnMomoTotal,
    required this.cardTotal,
    required this.grandTotal,
    required this.transactionCount,
    this.notes,
  });

  // TVA-inclusive breakdown (prices include TVA at 19.25%)
  double get totalHT => grandTotal / (1 + tvaRate);
  double get tvaAmount => grandTotal - totalHT;

  @override
  List<Object?> get props =>
      [id, closedAt, grandTotal, transactionCount];
}
