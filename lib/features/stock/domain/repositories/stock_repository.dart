import '../entities/stock_movement.dart';
import '../entities/supplier.dart';
import '../entities/cash_register_closure.dart';

abstract class StockRepository {
  // Stock movements
  Future<void> addMovement(StockMovement movement);
  List<StockMovement> getMovementsForProduct(String productId);
  List<StockMovement> getRecentMovements({int limit = 100});

  // Suppliers
  Future<void> saveSupplier(Supplier supplier);
  Future<void> deleteSupplier(String id);
  List<Supplier> getSuppliers();
  Supplier? getSupplierById(String id);

  // Cash register closures
  Future<void> saveClosure(CashRegisterClosure closure);
  List<CashRegisterClosure> getClosures({int limit = 30});
  CashRegisterClosure? getLastClosure();
}
