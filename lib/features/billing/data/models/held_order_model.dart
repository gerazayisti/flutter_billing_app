import 'package:hive/hive.dart';
import 'package:billing_app/features/product/data/models/product_model.dart';

part 'held_order_model.g.dart';

@HiveType(typeId: 5)
class HeldOrderModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final DateTime savedAt;
  
  @HiveField(2)
  final List<HeldCartItemModel> items;

  HeldOrderModel({
    required this.id,
    required this.savedAt,
    required this.items,
  });
}

@HiveType(typeId: 6)
class HeldCartItemModel extends HiveObject {
  @HiveField(0)
  final ProductModel product;
  
  @HiveField(1)
  final int quantity;

  @HiveField(2)
  final String? selectedVariant;

  HeldCartItemModel({
    required this.product,
    required this.quantity,
    this.selectedVariant,
  });
}
