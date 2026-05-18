import 'package:hive/hive.dart';
import '../../domain/entities/stock_movement.dart';

part 'stock_movement_model.g.dart';

@HiveType(typeId: 9)
class StockMovementModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String productId;
  @HiveField(2) String productName;
  @HiveField(3) String typeName;
  @HiveField(4) int quantity;
  @HiveField(5) String operatorId;
  @HiveField(6) DateTime date;
  @HiveField(7) String? supplierId;
  @HiveField(8) String? supplierName;
  @HiveField(9) String? orderId;
  @HiveField(10) String? note;
  @HiveField(11) double? unitCost;

  StockMovementModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.typeName,
    required this.quantity,
    required this.operatorId,
    required this.date,
    this.supplierId,
    this.supplierName,
    this.orderId,
    this.note,
    this.unitCost,
  });

  factory StockMovementModel.fromEntity(StockMovement e) => StockMovementModel(
        id: e.id,
        productId: e.productId,
        productName: e.productName,
        typeName: e.type.name,
        quantity: e.quantity,
        operatorId: e.operatorId,
        date: e.date,
        supplierId: e.supplierId,
        supplierName: e.supplierName,
        orderId: e.orderId,
        note: e.note,
        unitCost: e.unitCost,
      );

  StockMovement toEntity() => StockMovement(
        id: id,
        productId: productId,
        productName: productName,
        type: MovementTypeX.fromName(typeName),
        quantity: quantity,
        operatorId: operatorId,
        date: date,
        supplierId: supplierId,
        supplierName: supplierName,
        orderId: orderId,
        note: note,
        unitCost: unitCost,
      );
}
