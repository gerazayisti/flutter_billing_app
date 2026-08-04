import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/features/billing/data/models/order_model.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/utils/report_service.dart';
import 'package:billing_app/core/widgets/app_drawer.dart';
import 'package:billing_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:billing_app/features/auth/domain/entities/user.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(l10n.orderHistory, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
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
    final l10n = AppLocalizations.of(context)!;
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
            label: Text(l10n.edit),
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
    final l10n = AppLocalizations.of(context)!;
    
    // Get current logged-in user details
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isCashier = currentUser?.role == Role.cashier;

    // If cashier, fetch order IDs associated with their stock movements
    final cashierOrderIds = isCashier
        ? HiveDatabase.stockMovementsBox.values
            .where((m) => m.operatorId == currentUser?.id && m.orderId != null)
            .map((m) => m.orderId!)
            .toSet()
        : null;

    final orders = HiveDatabase.orderBox.values.where((order) {
      final matchesDate = order.date.year == _selectedDate.year &&
             order.date.month == _selectedDate.month &&
             order.date.day == _selectedDate.day;
      if (!matchesDate) return false;

      // If cashier, only display orders that they logged
      if (isCashier && cashierOrderIds != null) {
        return cashierOrderIds.contains(order.id);
      }
      return true;
    }).toList().reversed.toList();

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(l10n.noSalesRecorded),
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
    final l10n = AppLocalizations.of(context)!;
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
              Text('${l10n.paymentMode}:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(order.paymentMethod.toUpperCase()),
            ],
          )
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Get current logged-in user details
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isCashier = currentUser?.role == Role.cashier;

    // Filtered orders list function
    List<OrderModel>? getFilteredOrders(List<OrderModel> original) {
      if (!isCashier) return null;
      final cashierOrderIds = HiveDatabase.stockMovementsBox.values
          .where((m) => m.operatorId == currentUser?.id && m.orderId != null)
          .map((m) => m.orderId!)
          .toSet();
      return original.where((o) => cashierOrderIds.contains(o.id)).toList();
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.exportCAReport, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.today, color: AppTheme.primaryColor),
              title: Text(l10n.dailyReport),
              onTap: () {
                Navigator.pop(context);
                final dailyOrders = HiveDatabase.orderBox.values.where((o) => 
                  o.date.year == _selectedDate.year && 
                  o.date.month == _selectedDate.month && 
                  o.date.day == _selectedDate.day
                ).toList();
                ReportService.generateDailyReport(
                  _selectedDate, 
                  l10n, 
                  ordersList: getFilteredOrders(dailyOrders)
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_week, color: AppTheme.primaryDark),
              title: Text(l10n.weeklyReport),
              onTap: () {
                Navigator.pop(context);
                final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
                final endOfWeek = startOfWeek.add(const Duration(days: 6));
                final weeklyOrders = HiveDatabase.orderBox.values.where((o) => 
                  o.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && 
                  o.date.isBefore(endOfWeek.add(const Duration(days: 1)))
                ).toList();
                ReportService.generateWeeklyReport(
                  _selectedDate, 
                  l10n, 
                  ordersList: getFilteredOrders(weeklyOrders)
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: AppTheme.textPrimary),
              title: Text(l10n.monthlyReport),
              onTap: () {
                Navigator.pop(context);
                final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
                final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
                final monthlyOrders = HiveDatabase.orderBox.values.where((o) => 
                  o.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) && 
                  o.date.isBefore(endOfMonth.add(const Duration(days: 1)))
                ).toList();
                ReportService.generateMonthlyReport(
                  _selectedDate, 
                  l10n, 
                  ordersList: getFilteredOrders(monthlyOrders)
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
