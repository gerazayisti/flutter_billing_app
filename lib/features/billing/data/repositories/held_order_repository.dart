import 'package:hive/hive.dart';
import '../models/held_order_model.dart';
import '../../../../core/data/hive_database.dart';

class HeldOrderRepository {
  Box<HeldOrderModel> get _box => HiveDatabase.heldOrderBox;

  Future<void> saveHeldOrder(HeldOrderModel order) async {
    await _box.put(order.id, order);
  }

  List<HeldOrderModel> getAllHeldOrders() {
    return _box.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> deleteHeldOrder(String id) async {
    await _box.delete(id);
  }
}
