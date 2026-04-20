import 'package:hive/hive.dart';

part 'order_item_model.g.dart';

@HiveType(typeId: 3)
class OrderItemModel extends HiveObject {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final String? selectedVariant;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.selectedVariant,
  });
}
