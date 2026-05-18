import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/service_locator.dart';
import '../../features/billing/presentation/pages/home_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';
import '../../features/shop/presentation/pages/shop_details_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/billing/presentation/pages/scanner_page.dart';
import '../../features/billing/presentation/pages/checkout_page.dart';
import '../../features/product/domain/entities/product.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/pages/owner_dashboard_page.dart';
import '../../features/dashboard/presentation/pages/stock_manager_dashboard_page.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/dashboard/presentation/bloc/dashboard_event.dart';
import '../../features/auth/presentation/pages/email_login_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/user_management_bloc.dart';
import '../../features/auth/presentation/pages/user_management_page.dart';
import '../../features/billing/presentation/pages/order_history_page.dart';
import '../../features/stock/presentation/pages/stock_movements_page.dart';
import '../../features/stock/presentation/pages/cash_closure_page.dart';
import '../../features/stock/presentation/bloc/stock_bloc.dart';
import '../../features/notifications/presentation/pages/notification_page.dart';
import '../../features/subscription/presentation/pages/subscription_page.dart';
import '../../features/subscription/presentation/bloc/subscription_bloc.dart';
import '../../features/boutiques/presentation/pages/boutiques_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const EmailLoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpPage(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>?;
        if (extra == null) return const SignUpPage();
        return OtpVerificationPage(
          email: extra['email'] ?? '',
          ownerName: extra['ownerName'] ?? '',
          shopName: extra['shopName'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutPage(),
    ),
    GoRoute(
      path: '/scanner',
      builder: (context, state) => const ScannerPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductListPage(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddProductPage(),
        ),
        GoRoute(
          path: 'edit/:id',
          builder: (context, state) {
            final product = state.extra as Product?;
            if (product == null) return const ProductListPage();
            return EditProductPage(product: product);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopDetailsPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<DashboardBloc>()..add(const LoadDashboardEvent()),
        child: const DashboardPage(),
      ),
    ),
    GoRoute(
      path: '/owner-dashboard',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<DashboardBloc>()..add(const LoadDashboardEvent()),
        child: const OwnerDashboardPage(),
      ),
    ),
    GoRoute(
      path: '/stock-manager-dashboard',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<DashboardBloc>()..add(const LoadDashboardEvent()),
        child: const StockManagerDashboardPage(),
      ),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrderHistoryPage(),
    ),
    GoRoute(
      path: '/users',
      builder: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final shopId =
            authState is AuthAuthenticated ? authState.shopId : '';
        return BlocProvider(
          create: (_) =>
              sl<UserManagementBloc>()..add(LoadUsersEvent(shopId)),
          child: const UserManagementPage(),
        );
      },
    ),
    GoRoute(
      path: '/stock',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<StockBloc>()..add(LoadStockEvent()),
        child: const StockMovementsPage(),
      ),
    ),
    GoRoute(
      path: '/cash-closure',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<StockBloc>()..add(LoadStockEvent()),
        child: const CashClosurePage(),
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationPage(),
    ),
    GoRoute(
      path: '/subscription',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<SubscriptionBloc>()..add(const LoadSubscriptionEvent()),
        child: const SubscriptionPage(),
      ),
    ),
    GoRoute(
      path: '/boutiques',
      builder: (context, state) => const BoutiquesPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
);
