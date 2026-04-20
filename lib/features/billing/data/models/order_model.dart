import 'package:hive/hive.dart';
import '../models/order_item_model.dart';

part 'order_model.g.dart';

@HiveType(typeId: 2)
class OrderModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double totalAmount;

  @HiveField(3)
  final List<OrderItemModel> items;

  @HiveField(4, defaultValue: 'cash')
  final String paymentMethod;

  OrderModel({
    required this.id,
    required this.date,
    required this.items,
    required this.totalAmount,
    this.paymentMethod = 'cash',
  });
}
