import 'package:billing_app/core/data/hive_database.dart';
import '../../domain/entities/cash_register_closure.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/stock_repository.dart';
import '../models/cash_register_closure_model.dart';
import '../models/stock_movement_model.dart';
import '../models/supplier_model.dart';

class StockRepositoryImpl implements StockRepository {
  @override
  Future<void> addMovement(StockMovement movement) async {
    final model = StockMovementModel.fromEntity(movement);
    await HiveDatabase.stockMovementsBox.put(movement.id, model);
  }

  @override
  List<StockMovement> getMovementsForProduct(String productId) {
    return HiveDatabase.stockMovementsBox.values
        .where((m) => m.productId == productId)
        .map((m) => m.toEntity())
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  List<StockMovement> getRecentMovements({int limit = 100}) {
    final all = HiveDatabase.stockMovementsBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return all.take(limit).map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveSupplier(Supplier supplier) async {
    await HiveDatabase.suppliersBox.put(
        supplier.id, SupplierModel.fromEntity(supplier));
  }

  @override
  Future<void> deleteSupplier(String id) async {
    await HiveDatabase.suppliersBox.delete(id);
  }

  @override
  List<Supplier> getSuppliers() {
    return HiveDatabase.suppliersBox.values
        .map((m) => m.toEntity())
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Supplier? getSupplierById(String id) {
    return HiveDatabase.suppliersBox.get(id)?.toEntity();
  }

  @override
  Future<void> saveClosure(CashRegisterClosure closure) async {
    await HiveDatabase.cashClosuresBox.put(
        closure.id, CashRegisterClosureModel.fromEntity(closure));
  }

  @override
  List<CashRegisterClosure> getClosures({int limit = 30}) {
    final all = HiveDatabase.cashClosuresBox.values.toList()
      ..sort((a, b) => b.closedAt.compareTo(a.closedAt));
    return all.take(limit).map((m) => m.toEntity()).toList();
  }

  @override
  CashRegisterClosure? getLastClosure() {
    if (HiveDatabase.cashClosuresBox.isEmpty) return null;
    final all = HiveDatabase.cashClosuresBox.values.toList()
      ..sort((a, b) => b.closedAt.compareTo(a.closedAt));
    return all.first.toEntity();
  }
}
