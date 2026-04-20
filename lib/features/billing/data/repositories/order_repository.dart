import 'package:billing_app/features/billing/data/models/order_model.dart';
import 'package:billing_app/core/data/hive_database.dart';

abstract class OrderRepository {
  Future<void> saveOrder(OrderModel order);
  Future<List<OrderModel>> getAllOrders();
}

class OrderRepositoryImpl implements OrderRepository {
  @override
  Future<void> saveOrder(OrderModel order) async {
    await HiveDatabase.orderBox.put(order.id, order);
  }

  @override
  Future<List<OrderModel>> getAllOrders() async {
    return HiveDatabase.orderBox.values.toList();
  }
}
