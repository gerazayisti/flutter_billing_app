import 'package:flutter/material.dart';
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
import '../../features/payment/presentation/pages/credit_score_page.dart';
import '../../features/subscription/presentation/bloc/subscription_bloc.dart';
import '../../features/boutiques/presentation/pages/boutiques_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/pages/pin_login_page.dart';
import '../../features/auth/presentation/pages/pin_setup_page.dart';
import '../../core/data/hive_database.dart';
import '../../features/settings/presentation/pages/help_page.dart';
import '../../features/sync/presentation/pages/cloud_setup_page.dart';
import '../../features/payment/presentation/pages/wallet_page.dart';
import '../../features/reports/presentation/pages/inventory_report_page.dart';
import '../../features/payment/presentation/bloc/wallet_bloc.dart';
import '../../features/payment/presentation/bloc/wallet_event.dart';
import '../../features/payment/presentation/pages/enter_phone_number_page.dart';
import '../../features/payment/presentation/bloc/mobile_money_bloc.dart';
final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final hasSeenOnboarding = HiveDatabase.settingsBox.get('has_seen_onboarding', defaultValue: false) as bool;
    if (!hasSeenOnboarding) {
      if (state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }
      return null;
    }

    final s = HiveDatabase.settingsBox;
    final pin = s.get('user_pin', defaultValue: '') as String;
    final isPinVerified = s.get('is_pin_verified', defaultValue: false) as bool;

    if (pin.isNotEmpty && !isPinVerified) {
      final lastActiveStr = s.get('last_active_time', defaultValue: '') as String;
      if (lastActiveStr.isNotEmpty) {
        final lastActive = DateTime.parse(lastActiveStr);
        final diff = DateTime.now().difference(lastActive);

        if (diff.inHours < 24) {
          if (state.matchedLocation != '/pin-login') {
            return '/pin-login';
          }
        } else {
          // Plus de 24h : déconnexion Supabase + nettoyage PIN local
          try {
            Supabase.instance.client.auth.signOut();
          } catch (_) {}
          s.delete('user_pin');
          s.delete('last_active_time');
          s.put('is_pin_verified', false);
          if (state.matchedLocation != '/') {
            return '/';
          }
        }
      }
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
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
      builder: (context, state) => const SubscriptionPage(),
    ),
    GoRoute(
      path: '/boutiques',
      builder: (context, state) => const BoutiquesPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpPage(),
    ),
    GoRoute(
      path: '/cloud-setup',
      builder: (context, state) => const CloudSetupPage(),
    ),
    GoRoute(
      path: '/wallet',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<WalletBloc>()..add(LoadWalletDataEvent()),
        child: const WalletPage(),
      ),
    ),
    GoRoute(
      path: '/credit-score',
      builder: (context, state) => const CreditScorePage(),
    ),
    GoRoute(
      path: '/pin-login',
      builder: (context, state) => const PinLoginPage(),
    ),
    GoRoute(
      path: '/pin-setup',
      builder: (context, state) => const PinSetupPage(),
    ),
    GoRoute(
      path: '/inventory-report',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<StockBloc>()..add(LoadStockEvent()),
        child: const InventoryReportPage(),
      ),
    ),
    GoRoute(
      path: '/payment/momo',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final saleId = extra?['saleId'] as String? ?? 'sale_${DateTime.now().millisecondsSinceEpoch}';
        final amount = (extra?['amount'] as num?)?.toDouble() ?? 0.0;
        final onConfirmed = extra?['onConfirmed'] as VoidCallback? ?? () {};

        return BlocProvider(
          create: (_) => sl<MobileMoneyBloc>(),
          child: EnterPhoneNumberPage(
            saleId: saleId,
            amount: amount,
            onConfirmed: onConfirmed,
          ),
        );
      },
    ),
  ],
);
