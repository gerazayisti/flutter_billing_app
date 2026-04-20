import 'package:billing_app/features/billing/data/models/order_model.dart';
import 'package:billing_app/features/billing/data/repositories/order_repository.dart';

class SaveOrderUseCase {
  final OrderRepository repository;

  SaveOrderUseCase(this.repository);

  Future<void> call(OrderModel order) => repository.saveOrder(order);
}
