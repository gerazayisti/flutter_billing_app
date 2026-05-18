import 'package:hive_flutter/hive_flutter.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/shop/data/models/shop_model.dart';
import '../../features/billing/data/models/order_model.dart';
import '../../features/billing/data/models/order_item_model.dart';
import '../../features/billing/data/models/held_order_model.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/domain/entities/user.dart';
import '../utils/pin_hasher.dart';

class HiveDatabase {
  static const String productBoxName = 'products';
  static const String shopBoxName = 'shop';
  static const String settingsBoxName = 'settings';
  static const String orderBoxName = 'orders';
  static const String heldOrderBoxName = 'heldOrders';
  static const String usersBoxName = 'users';

  static late Box<ProductModel> productBox;
  static late Box<ShopModel> shopBox;
  static late Box settingsBox;
  static late Box<OrderModel> orderBox;
  static late Box<HeldOrderModel> heldOrderBox;
  static late Box<UserModel> usersBox;

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

    // Open boxes
    productBox = await Hive.openBox<ProductModel>(productBoxName);
    shopBox = await Hive.openBox<ShopModel>(shopBoxName);
    settingsBox = await Hive.openBox(settingsBoxName);
    orderBox = await Hive.openBox<OrderModel>(orderBoxName);
    heldOrderBox = await Hive.openBox<HeldOrderModel>(heldOrderBoxName);
    usersBox = await Hive.openBox<UserModel>(usersBoxName);

    // Seed default owner if no users exist
    if (usersBox.isEmpty) {
      await usersBox.put('owner', UserModel(
        id: 'owner',
        name: 'Propriétaire',
        pinCode: PinHasher.hash('0000'),
        role: Role.owner,
      ));
    }
  }
}
