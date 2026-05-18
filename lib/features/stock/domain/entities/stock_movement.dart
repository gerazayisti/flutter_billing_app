import 'package:equatable/equatable.dart';

enum MovementType {
  saleOut,       // Auto-recorded when a POS order is saved
  manualOut,     // Stock manager deduction
  restockIn,     // Restock from supplier
  adjustmentIn,  // Positive manual adjustment
  adjustmentOut, // Negative manual adjustment
  returnIn,      // Customer return
}

extension MovementTypeX on MovementType {
  bool get isIn =>
      this == MovementType.restockIn ||
      this == MovementType.adjustmentIn ||
      this == MovementType.returnIn;

  bool get isOut =>
      this == MovementType.saleOut ||
      this == MovementType.manualOut ||
      this == MovementType.adjustmentOut;

  String get name => switch (this) {
        MovementType.saleOut => 'saleOut',
        MovementType.manualOut => 'manualOut',
        MovementType.restockIn => 'restockIn',
        MovementType.adjustmentIn => 'adjustmentIn',
        MovementType.adjustmentOut => 'adjustmentOut',
        MovementType.returnIn => 'returnIn',
      };

  static MovementType fromName(String name) => switch (name) {
        'saleOut' => MovementType.saleOut,
        'manualOut' => MovementType.manualOut,
        'restockIn' => MovementType.restockIn,
        'adjustmentIn' => MovementType.adjustmentIn,
        'adjustmentOut' => MovementType.adjustmentOut,
        'returnIn' => MovementType.returnIn,
        _ => MovementType.adjustmentOut,
      };
}

class StockMovement extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final MovementType type;
  final int quantity;
  final String operatorId;
  final DateTime date;
  final String? supplierId;
  final String? supplierName;
  final String? orderId;
  final String? note;
  final double? unitCost;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.operatorId,
    required this.date,
    this.supplierId,
    this.supplierName,
    this.orderId,
    this.note,
    this.unitCost,
  });

  @override
  List<Object?> get props =>
      [id, productId, type, quantity, operatorId, date];
}
