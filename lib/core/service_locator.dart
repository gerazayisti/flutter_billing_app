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
import '../../features/stock/data/repositories/stock_repository_impl.dart';
import '../../features/stock/domain/repositories/stock_repository.dart';
import '../../features/stock/presentation/bloc/stock_bloc.dart';
import 'cloud/supabase_sync_service.dart';
import 'cloud/cloud_sync_service.dart';
import 'cloud/supabase_auth_service.dart';
import 'cloud/supabase_subscription_service.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';
import '../features/subscription/presentation/bloc/subscription_bloc.dart';
import '../features/sync/presentation/bloc/sync_bloc.dart';
import '../features/payment/data/datasources/freemopay_remote_datasource.dart';
import '../features/payment/data/datasources/pawapay_remote_datasource.dart';
import '../features/payment/data/repositories/payment_repository_impl.dart';
import '../features/payment/domain/repositories/payment_repository.dart';
import '../features/payment/presentation/bloc/mobile_money_bloc.dart';
import '../features/payment/presentation/bloc/wallet_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../features/onboarding/domain/usecases/onboarding_usecases.dart';


final sl = GetIt.instance;

Future<void> init() async {
  // ── Onboarding ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<OnboardingRepository>(() => OnboardingRepositoryImpl());
  sl.registerLazySingleton(() => HasSeenOnboardingUseCase(sl()));
  sl.registerLazySingleton(() => CompleteOnboardingUseCase(sl()));

  // ── Auth ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SupabaseAuthService>(() => SupabaseAuthService());
  sl.registerFactory(() => AuthBloc(authService: sl(), syncService: sl<SupabaseSyncService>()));
  sl.registerFactory(() => UserManagementBloc(authService: sl()));
  sl.registerFactory(() => LocaleBloc());

  // ── Features - Product ─────────────────────────────────────────────────────
  sl.registerFactory(
    () => ProductBloc(
      getProductsUseCase: sl(),
      addProductUseCase: sl(),
      updateProductUseCase: sl(),
      deleteProductUseCase: sl(),
      syncService: sl<CloudSyncService>(),
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
      syncService: sl<CloudSyncService>(),
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
      syncService: sl<CloudSyncService>(),
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

  // ── Features - Stock & Reporting ──────────────────────────────────────────
  sl.registerLazySingleton<StockRepository>(() => StockRepositoryImpl());
  sl.registerFactory(() => StockBloc(repository: sl(), syncService: sl<CloudSyncService>()));

  // ── Notifications ─────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => NotificationBloc());

  // ── Subscription ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<SupabaseSubscriptionService>(
      () => SupabaseSubscriptionService());
  sl.registerFactory(
      () => SubscriptionBloc(subscriptionService: sl()));

  // ── Cloud Sync ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SupabaseSyncService>(() => SupabaseSyncService());
  sl.registerLazySingleton<CloudSyncService>(() => sl<SupabaseSyncService>());
  sl.registerFactory(() => SyncBloc(syncService: sl<SupabaseSyncService>()));

  // ── FreeMoPay Mobile Money ──────────────────────────────────────────────────
  sl.registerLazySingleton<FreemoPayRemoteDataSource>(
    () => FreemoPayRemoteDataSource(Supabase.instance.client),
  );
  sl.registerLazySingleton<PawaPayRemoteDataSource>(
    () => PawaPayRemoteDataSource(Supabase.instance.client),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(sl<FreemoPayRemoteDataSource>()),
  );
  sl.registerFactory<MobileMoneyBloc>(
    () => MobileMoneyBloc(sl<PaymentRepository>()),
  );
  sl.registerFactory<WalletBloc>(
    () => WalletBloc(paymentRepository: sl<PaymentRepository>()),
  );
}
