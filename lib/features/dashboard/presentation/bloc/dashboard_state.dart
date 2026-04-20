import 'package:equatable/equatable.dart';
import 'package:billing_app/features/billing/data/models/order_model.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';

// ---------- State ----------
class DashboardState extends Equatable {
  final bool isLoading;
  final double dailyRevenue;
  final Map<DateTime, double> weeklySales;
  final List<MapEntry<String, int>> topProducts;
  final List<OrderModel> recentOrders;
  final List<Product> lowStockProducts;
  final String? error;

  const DashboardState({
    this.isLoading = false,
    this.dailyRevenue = 0.0,
    this.weeklySales = const {},
    this.topProducts = const [],
    this.recentOrders = const [],
    this.lowStockProducts = const [],
    this.error,
  });

  DashboardState copyWith({
    bool? isLoading,
    double? dailyRevenue,
    Map<DateTime, double>? weeklySales,
    List<MapEntry<String, int>>? topProducts,
    List<OrderModel>? recentOrders,
    List<Product>? lowStockProducts,
    String? error,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
      weeklySales: weeklySales ?? this.weeklySales,
      topProducts: topProducts ?? this.topProducts,
      recentOrders: recentOrders ?? this.recentOrders,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        dailyRevenue,
        weeklySales,
        topProducts,
        recentOrders,
        lowStockProducts,
        error
      ];
}
