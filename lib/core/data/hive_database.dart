import 'package:hive_flutter/hive_flutter.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/shop/data/models/shop_model.dart';
import '../../features/billing/data/models/order_model.dart';
import '../../features/billing/data/models/order_item_model.dart';
import '../../features/billing/data/models/held_order_model.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/payment/data/models/momo_transaction_model.dart';
import '../../features/stock/data/models/stock_movement_model.dart';
import '../../features/stock/data/models/supplier_model.dart';
import '../../features/stock/data/models/cash_register_closure_model.dart';
class HiveDatabase {
  static const String productBoxName = 'products';
  static const String shopBoxName = 'shop';
  static const String settingsBoxName = 'settings';
  static const String orderBoxName = 'orders';
  static const String heldOrderBoxName = 'heldOrders';
  static const String usersBoxName = 'users';
  static const String momoTransactionsBoxName = 'momoTransactions';
  static const String stockMovementsBoxName = 'stockMovements';
  static const String suppliersBoxName = 'suppliers';
  static const String cashClosuresBoxName = 'cashClosures';

  static late Box<ProductModel> productBox;
  static late Box<ShopModel> shopBox;
  static late Box settingsBox;
  static late Box<OrderModel> orderBox;
  static late Box<HeldOrderModel> heldOrderBox;
  static late Box<UserModel> usersBox;
  static late Box<MomoTransactionModel> momoTransactionsBox;
  static late Box<StockMovementModel> stockMovementsBox;
  static late Box<SupplierModel> suppliersBox;
  static late Box<CashRegisterClosureModel> cashClosuresBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(ShopModelAdapter());
    Hive.registerAdapter(OrderModelAdapter());
    Hive.registerAdapter(OrderItemModelAdapter());
    Hive.registerAdapter(HeldOrderModelAdapter());
    Hive.registerAdapter(HeldCartItemModelAdapter());
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(RoleAdapter());
    Hive.registerAdapter(MomoTransactionModelAdapter());
    Hive.registerAdapter(StockMovementModelAdapter());
    Hive.registerAdapter(SupplierModelAdapter());
    Hive.registerAdapter(CashRegisterClosureModelAdapter());

    // Open boxes
    productBox = await Hive.openBox<ProductModel>(productBoxName);
    shopBox = await Hive.openBox<ShopModel>(shopBoxName);
    settingsBox = await Hive.openBox(settingsBoxName);
    orderBox = await Hive.openBox<OrderModel>(orderBoxName);
    heldOrderBox = await Hive.openBox<HeldOrderModel>(heldOrderBoxName);
    usersBox = await Hive.openBox<UserModel>(usersBoxName);
    momoTransactionsBox = await Hive.openBox<MomoTransactionModel>(momoTransactionsBoxName);
    stockMovementsBox = await Hive.openBox<StockMovementModel>(stockMovementsBoxName);
    suppliersBox = await Hive.openBox<SupplierModel>(suppliersBoxName);
    cashClosuresBox = await Hive.openBox<CashRegisterClosureModel>(cashClosuresBoxName);
  }
}
