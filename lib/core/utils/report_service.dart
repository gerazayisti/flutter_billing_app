import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/features/billing/data/models/order_model.dart';
import 'package:billing_app/features/product/data/models/product_model.dart';
import 'package:billing_app/l10n/app_localizations.dart';

class ReportService {
  static Future<void> generateDailyReport(DateTime date, AppLocalizations l10n, {List<OrderModel>? ordersList}) async {
    final orders = ordersList ?? _getOrdersForDate(date);
    final pdf = await _buildReportPdf(
      title: '${l10n.dailyReport} - ${DateFormat('dd/MM/yyyy').format(date)}',
      orders: orders,
      showDetails: true,
      l10n: l10n,
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<void> generateWeeklyReport(DateTime date, AppLocalizations l10n, {List<OrderModel>? ordersList}) async {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    final orders = ordersList ?? HiveDatabase.orderBox.values.where((o) => 
      o.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && 
      o.date.isBefore(endOfWeek.add(const Duration(days: 1)))
    ).toList();

    final pdf = await _buildReportPdf(
      title: '${l10n.weeklyReport} - ${l10n.weekLabel} ${l10n.generatedAt} ${DateFormat('dd/MM').format(startOfWeek)}',
      orders: orders,
      showDetails: true,
      recaps: _getDailyRecaps(orders),
      recapTitle: l10n.periodRecap,
      l10n: l10n,
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<void> generateMonthlyReport(DateTime date, AppLocalizations l10n, {List<OrderModel>? ordersList}) async {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final endOfMonth = DateTime(date.year, date.month + 1, 0);
    
    final orders = ordersList ?? HiveDatabase.orderBox.values.where((o) => 
      o.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) && 
      o.date.isBefore(endOfMonth.add(const Duration(days: 1)))
    ).toList();

    final pdf = await _buildReportPdf(
      title: '${l10n.monthlyReport} - ${DateFormat('MMMM yyyy').format(date)}',
      orders: orders,
      showDetails: true,
      recaps: _getWeeklyRecaps(orders, l10n),
      recapTitle: l10n.periodRecap,
      l10n: l10n,
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static List<OrderModel> _getOrdersForDate(DateTime date) {
    return HiveDatabase.orderBox.values.where((o) => 
      o.date.year == date.year && 
      o.date.month == date.month && 
      o.date.day == date.day
    ).toList();
  }

  static Map<String, double> _getDailyRecaps(List<OrderModel> orders) {
    final Map<String, double> recaps = {};
    for (var o in orders) {
      final key = DateFormat('EEEE dd/MM').format(o.date);
      recaps[key] = (recaps[key] ?? 0) + o.totalAmount;
    }
    return recaps;
  }

  static Map<String, double> _getWeeklyRecaps(List<OrderModel> orders, AppLocalizations l10n) {
    final Map<String, double> recaps = {};
    for (var o in orders) {
      final weekNum = ((o.date.day - 1) / 7).floor() + 1;
      final key = '${l10n.weekLabel} $weekNum';
      recaps[key] = (recaps[key] ?? 0) + o.totalAmount;
    }
    return recaps;
  }

  static Map<String, double> _getCategoryBreakdown(List<OrderModel> orders, AppLocalizations l10n) {
    final Map<String, double> breakdown = {};
    final products = HiveDatabase.productBox.values.toList();

    for (var order in orders) {
      for (var item in order.items) {
        final product = products.firstWhere((p) => p.id == item.productId, 
          orElse: () => ProductModel(id: '', name: item.productName, barcode: '', price: item.price, stock: 0, category: l10n.unknownCategory, minStockAlert: 0, variants: const []));
        
        final category = product.category;
        breakdown[category] = (breakdown[category] ?? 0) + (item.price * item.quantity);
      }
    }
    return breakdown;
  }

  static Future<pw.Document> _buildReportPdf({
    required String title,
    required List<OrderModel> orders,
    required AppLocalizations l10n,
    bool showDetails = false,
    Map<String, double>? recaps,
    String? recapTitle,
  }) async {
    final pdf = pw.Document();
    final totalCA = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    final categoryBreakdown = _getCategoryBreakdown(orders, l10n);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          pw.Text('${l10n.generatedAt} : ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
          pw.Divider(),
          
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${l10n.totalRevenue} :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.Text('XAF ${totalCA.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.blue)),
            ],
          ),
          pw.SizedBox(height: 20),

          // Category Breakdown
          pw.Header(level: 1, text: l10n.categoryBreakdown),
          pw.TableHelper.fromTextArray(
            headers: [l10n.categoryLabel, l10n.revenueLabel, '%'],
            data: categoryBreakdown.entries.map((e) => [
              e.key, 
              e.value.toStringAsFixed(0),
              '${(e.value / (totalCA > 0 ? totalCA : 1) * 100).toStringAsFixed(1)}%'
            ]).toList(),
          ),
          pw.SizedBox(height: 20),

          // Recaps (Daily/Weekly)
          if (recaps != null) ...[
            pw.Header(level: 1, text: recapTitle!),
            pw.TableHelper.fromTextArray(
              headers: [l10n.periodLabel, l10n.cumulativeLabel],
              data: recaps.entries.map((e) => [e.key, e.value.toStringAsFixed(0)]).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // Detailed Transactions
          if (showDetails) ...[
            pw.Header(level: 1, text: l10n.transactionList),
            pw.TableHelper.fromTextArray(
              headers: ['ID', l10n.dateHeader, l10n.modeLabel, l10n.amountLabel],
              data: orders.map((o) => [
                o.id.substring(0, 8),
                DateFormat('dd/MM HH:mm').format(o.date),
                o.paymentMethod.toUpperCase(),
                o.totalAmount.toStringAsFixed(0)
              ]).toList(),
            ),
          ],
        ],
      ),
    );

    return pdf;
  }
}
