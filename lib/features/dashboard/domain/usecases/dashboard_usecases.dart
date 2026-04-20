import 'package:billing_app/features/billing/data/models/order_model.dart';
import 'package:billing_app/features/billing/data/repositories/order_repository.dart';

/// Returns all orders from the local DB
class GetAllOrdersUseCase {
  final OrderRepository repository;
  GetAllOrdersUseCase(this.repository);
  Future<List<OrderModel>> call() => repository.getAllOrders();
}

/// Calculates the total revenue for today
class GetDailyRevenueUseCase {
  final OrderRepository repository;
  GetDailyRevenueUseCase(this.repository);

  Future<double> call() async {
    final orders = await repository.getAllOrders();
    final today = DateTime.now();
    final filtered = orders.where((o) =>
        o.date.year == today.year &&
        o.date.month == today.month &&
        o.date.day == today.day);
    double total = 0.0;
    for (final o in filtered) {
      total += o.totalAmount;
    }
    return total;
  }
}

/// Returns the revenue grouped by day for the last [days] days (for chart)
class GetWeeklySalesUseCase {
  final OrderRepository repository;
  GetWeeklySalesUseCase(this.repository);

  Future<Map<DateTime, double>> call({int days = 7}) async {
    final orders = await repository.getAllOrders();
    final now = DateTime.now();
    final result = <DateTime, double>{};

    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      result[day] = 0.0;
    }

    for (final order in orders) {
      final orderDay =
          DateTime(order.date.year, order.date.month, order.date.day);
      if (result.containsKey(orderDay)) {
        result[orderDay] = result[orderDay]! + order.totalAmount;
      }
    }
    return result;
  }
}

/// Returns top N sold products by quantity
class GetTopProductsUseCase {
  final OrderRepository repository;
  GetTopProductsUseCase(this.repository);

  Future<List<MapEntry<String, int>>> call({int top = 5}) async {
    final orders = await repository.getAllOrders();
    final counts = <String, int>{};
    for (final order in orders) {
      for (final item in order.items) {
        counts[item.productName] =
            (counts[item.productName] ?? 0) + item.quantity;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(top).toList();
  }
}
