import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'config/routes/app_routes.dart';
import 'core/data/hive_database.dart';
import 'core/service_locator.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/billing/presentation/bloc/billing_bloc.dart';
import 'features/product/presentation/bloc/product_bloc.dart';
import 'features/shop/presentation/bloc/shop_bloc.dart';
import 'features/settings/presentation/bloc/printer_bloc.dart';
import 'features/settings/presentation/bloc/printer_event.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/settings/presentation/bloc/locale_bloc.dart';
import 'features/stock/presentation/bloc/stock_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveDatabase.init();
  await di.init();
  await initializeDateFormatting('fr', null);
  await initializeDateFormatting('en', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocaleBloc>(
            create: (context) => di.sl<LocaleBloc>()..add(LoadLocaleEvent())),
        BlocProvider<ProductBloc>(
            create: (context) => di.sl<ProductBloc>()..add(LoadProducts())),
        BlocProvider<ShopBloc>(
            create: (context) => di.sl<ShopBloc>()..add(LoadShopEvent())),
        BlocProvider<BillingBloc>(
            create: (context) => di.sl<BillingBloc>()..add(LoadHeldOrdersEvent())),
        BlocProvider<PrinterBloc>(
            create: (context) => di.sl<PrinterBloc>()..add(InitPrinterEvent())),
        BlocProvider<AuthBloc>(
            create: (context) => di.sl<AuthBloc>()),
        BlocProvider<StockBloc>(
            create: (context) => di.sl<StockBloc>()),
      ],
      child: BlocBuilder<LocaleBloc, LocaleState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'Gestock+',
            locale: state.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr'),
              Locale('en'),
            ],
            theme: AppTheme.lightTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
