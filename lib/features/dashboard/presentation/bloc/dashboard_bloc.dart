import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
import '../../domain/usecases/dashboard_usecases.dart';
import '../../../../core/data/hive_database.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDailyRevenueUseCase getDailyRevenue;
  final GetWeeklySalesUseCase getWeeklySales;
  final GetTopProductsUseCase getTopProducts;
  final GetAllOrdersUseCase getAllOrders;

  DashboardBloc({
    required this.getDailyRevenue,
    required this.getWeeklySales,
    required this.getTopProducts,
    required this.getAllOrders,
  }) : super(const DashboardState()) {
    on<LoadDashboardEvent>(_onLoad);
  }

  Future<void> _onLoad(
      LoadDashboardEvent event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final daily = await getDailyRevenue();
      final weekly = await getWeeklySales();
      final top = await getTopProducts();
      final orders = await getAllOrders();
      // Show 10 most recent orders
      final recent = orders..sort((a, b) => b.date.compareTo(a.date));

      // Compute low stock products
      final allProducts = HiveDatabase.productBox.values.toList();
      final lowStock = allProducts
          .where((p) => p.stock <= p.minStockAlert)
          .map((p) => p.toEntity())
          .toList();

      emit(state.copyWith(
        isLoading: false,
        dailyRevenue: daily,
        weeklySales: weekly,
        topProducts: top,
        recentOrders: recent.take(10).toList(),
        lowStockProducts: lowStock,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
