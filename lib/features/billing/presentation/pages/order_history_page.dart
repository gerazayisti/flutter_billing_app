import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/features/billing/data/models/order_model.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/utils/report_service.dart';
import 'package:billing_app/core/widgets/app_drawer.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // We listen to the orderBox directly for simplicity here or use a Bloc
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Ventes', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryColor),
            onPressed: () => _showExportOptions(context),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildDatePicker(),
          Expanded(child: _buildOrderList()),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(DateFormat('EEEE, d MMMM y').format(_selectedDate),
            style: const TextStyle(fontWeight: FontWeight.w600)),
          TextButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: const Text('Modifier'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    final orders = HiveDatabase.orderBox.values.where((order) {
      return order.date.year == _selectedDate.year &&
             order.date.month == _selectedDate.month &&
             order.date.day == _selectedDate.day;
    }).toList().reversed.toList();

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Aucune vente enregistrée ce jour.'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        title: Text('XAF ${order.totalAmount.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        subtitle: Text(DateFormat('HH:mm').format(order.date),
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('${item.quantity}x ${item.productName}${item.selectedVariant != null ? " (${item.selectedVariant})" : ""}')),
                Text('XAF ${(item.price * item.quantity).toStringAsFixed(0)}'),
              ],
            ),
          )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mode de paiement:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(order.paymentMethod.toUpperCase()),
            ],
          )
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exporter le Rapport CA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.today, color: Colors.blue),
              title: const Text('Rapport du Jour (Détaillé)'),
              onTap: () {
                Navigator.pop(context);
                ReportService.generateDailyReport(_selectedDate);
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_week, color: Colors.green),
              title: const Text('Rapport de la Semaine'),
              onTap: () {
                Navigator.pop(context);
                ReportService.generateWeeklyReport(_selectedDate);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.orange),
              title: const Text('Rapport Mensuel'),
              onTap: () {
                Navigator.pop(context);
                ReportService.generateMonthlyReport(_selectedDate);
              },
            ),
          ],
        ),
      ),
    );
  }
}
