import 'package:get_it/get_it.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/product/domain/usecases/product_usecases.dart';
import '../../features/product/presentation/bloc/product_bloc.dart';
import '../../features/shop/data/repositories/shop_repository_impl.dart';
import '../../features/shop/domain/repositories/shop_repository.dart';
import '../../features/shop/domain/usecases/shop_usecases.dart';
import '../../features/shop/presentation/bloc/shop_bloc.dart';
import '../../features/settings/data/repositories/printer_repository_impl.dart';
import '../../features/settings/domain/repositories/printer_repository.dart';
import '../../features/settings/presentation/bloc/printer_bloc.dart';
import '../../features/billing/data/repositories/order_repository.dart';
import '../../features/billing/data/repositories/held_order_repository.dart';
import '../../features/billing/domain/usecases/save_order_usecase.dart';
import '../../features/billing/presentation/bloc/billing_bloc.dart';
import '../../features/dashboard/domain/usecases/dashboard_usecases.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/auth/presentation/bloc/user_management_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/settings/presentation/bloc/locale_bloc.dart';
import '../../features/payment/data/repositories/payment_repository_impl.dart';
import '../../features/payment/domain/repositories/payment_repository.dart';
import '../../features/payment/presentation/bloc/payment_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Features - Product ─────────────────────────────────────────────────────
  sl.registerFactory(
    () => ProductBloc(
      getProductsUseCase: sl(),
      addProductUseCase: sl(),
      updateProductUseCase: sl(),
      deleteProductUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => GetProductByBarcodeUseCase(sl()));
  sl.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl());

  // ── Features - Shop ────────────────────────────────────────────────────────
  sl.registerFactory(
    () => ShopBloc(
      getShopUseCase: sl(),
      updateShopUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetShopUseCase(sl()));
  sl.registerLazySingleton(() => UpdateShopUseCase(sl()));
  sl.registerLazySingleton<ShopRepository>(() => ShopRepositoryImpl());

  // ── Features - Settings / Printer ─────────────────────────────────────────
  sl.registerFactory(() => PrinterBloc(repository: sl()));
  sl.registerLazySingleton<PrinterRepository>(() => PrinterRepositoryImpl());

  // ── Features - Billing / Orders ───────────────────────────────────────────
  sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl());
  sl.registerLazySingleton(() => HeldOrderRepository());
  sl.registerLazySingleton(() => SaveOrderUseCase(sl()));
  sl.registerFactory(
    () => BillingBloc(
      getProductByBarcodeUseCase: sl(),
      saveOrderUseCase: sl(),
      heldOrderRepository: sl(),
    ),
  );

  // ── Features - Dashboard ──────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetAllOrdersUseCase(sl()));
  sl.registerLazySingleton(() => GetDailyRevenueUseCase(sl()));
  sl.registerLazySingleton(() => GetWeeklySalesUseCase(sl()));
  sl.registerLazySingleton(() => GetTopProductsUseCase(sl()));
  sl.registerFactory(
    () => DashboardBloc(
      getDailyRevenue: sl(),
      getWeeklySales: sl(),
      getTopProducts: sl(),
      getAllOrders: sl(),
    ),
  );

  // ── Features - Auth ───────────────────────────────────────────────────────
  sl.registerFactory(() => AuthBloc());
  sl.registerFactory(() => UserManagementBloc());
  sl.registerFactory(() => LocaleBloc());

  // ── Features - Payment (Mobile Money) ─────────────────────────────────────
  sl.registerLazySingleton<PaymentRepository>(() => PaymentRepositoryImpl());
  sl.registerFactory(() => PaymentBloc(repository: sl()));
}
