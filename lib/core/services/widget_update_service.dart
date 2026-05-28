import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../data/hive_database.dart';

class WidgetUpdateService {
  static const _appGroupId = 'group.com.example.billing_app';

  static Future<void> update() async {
    await HomeWidget.setAppGroupId(_appGroupId);
    await Future.wait([
      _writeSummary(),
      _writeLowStock(),
      _writeTopProduct(),
    ]);
    await HomeWidget.updateWidget(
      androidName: 'GestockSummaryWidget',
    );
    await HomeWidget.updateWidget(
      androidName: 'GestockLowStockWidget',
    );
    await HomeWidget.updateWidget(
      androidName: 'GestockTopProductWidget',
    );
  }

  static Future<void> _writeSummary() async {
    final today = DateTime.now();
    final orders = HiveDatabase.orderBox.values.where((o) =>
        o.date.year == today.year &&
        o.date.month == today.month &&
        o.date.day == today.day);

    final count = orders.length;
    final total = orders.fold<double>(0, (s, o) => s + o.totalAmount);
    final fmt = NumberFormat('#,###', 'fr_FR').format(total.round());

    await HomeWidget.saveWidgetData('summary_total', '$fmt FCFA');
    await HomeWidget.saveWidgetData('summary_count', '$count vente${count != 1 ? 's' : ''}');
  }

  static Future<void> _writeLowStock() async {
    final low = HiveDatabase.productBox.values
        .where((p) => p.stock <= p.minStockAlert)
        .length;

    await HomeWidget.saveWidgetData('low_stock_count', '$low');
    await HomeWidget.saveWidgetData(
        'low_stock_label', low == 0 ? 'Stock OK' : '$low produit${low != 1 ? 's' : ''} en alerte');
  }

  static Future<void> _writeTopProduct() async {
    final today = DateTime.now();
    final totals = <String, int>{};

    for (final order in HiveDatabase.orderBox.values) {
      if (order.date.year != today.year ||
          order.date.month != today.month ||
          order.date.day != today.day) continue;
      for (final item in order.items) {
        totals[item.productName] = (totals[item.productName] ?? 0) + item.quantity;
      }
    }

    if (totals.isEmpty) {
      await HomeWidget.saveWidgetData('top_product_name', 'Aucune vente');
      await HomeWidget.saveWidgetData('top_product_qty', '—');
    } else {
      final top = totals.entries.reduce((a, b) => a.value >= b.value ? a : b);
      await HomeWidget.saveWidgetData('top_product_name', top.key);
      await HomeWidget.saveWidgetData('top_product_qty', '${top.value} vendu${top.value != 1 ? 's' : ''}');
    }
  }
}
