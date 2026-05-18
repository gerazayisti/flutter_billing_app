import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:billing_app/l10n/app_localizations.dart';

import '../../../../core/theme/app_color_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../../product/domain/entities/product.dart';
import '../../../../core/utils/report_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const LoadDashboardEvent());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = AppColorConfig.accentColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: accent),
            );
          }
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, accent),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    if (state.lowStockProducts.isNotEmpty) ...[
                      _SectionTitle(title: '${l10n.stockAlerts} ⚠️'),
                      const SizedBox(height: 12),
                      _StockAlertsCard(
                          products: state.lowStockProducts, accent: Colors.red),
                      const SizedBox(height: 24),
                    ],
                    _KpiRow(
                      dailyRevenue: state.dailyRevenue,
                      totalOrders: state.recentOrders.length,
                      accent: accent,
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(title: l10n.revenueRecap),
                    const SizedBox(height: 12),
                    _CaRecapCard(state: state, accent: accent),
                    const SizedBox(height: 24),
                    _SectionTitle(title: l10n.recentHistory),
                    const SizedBox(height: 12),
                    _RecentOrdersCard(orders: state.recentOrders, accent: accent),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, Color accent) {
    final l10n = AppLocalizations.of(context)!;
    return SliverAppBar(
      expandedHeight: 120,
      collapsedHeight: 60,
      pinned: true,
      backgroundColor: accent,
      title: Text(
        l10n.dashboard,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
          onPressed: () => _showExportOptions(context),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () =>
              context.read<DashboardBloc>().add(const LoadDashboardEvent()),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, Color.lerp(accent, Colors.black, 0.2)!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            Text(l10n.generateReport, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _ReportTile(
              icon: Icons.today,
              color: AppTheme.primaryColor,
              title: l10n.dailyReport,
              onTap: () {
                Navigator.pop(context);
                ReportService.generateDailyReport(DateTime.now(), l10n);
              },
            ),
            _ReportTile(
              icon: Icons.view_week,
              color: AppTheme.primaryDark,
              title: l10n.weeklyReport,
              onTap: () {
                Navigator.pop(context);
                ReportService.generateWeeklyReport(DateTime.now(), l10n);
              },
            ),
            _ReportTile(
              icon: Icons.calendar_month,
              color: AppTheme.primaryColor,
              title: l10n.monthlyReport,
              onTap: () {
                Navigator.pop(context);
                ReportService.generateMonthlyReport(DateTime.now(), l10n);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  const _ReportTile({required this.icon, required this.color, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _KpiRow extends StatelessWidget {
  final double dailyRevenue;
  final int totalOrders;
  final Color accent;

  const _KpiRow({
    required this.dailyRevenue,
    required this.totalOrders,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = NumberFormat.currency(symbol: '', decimalDigits: 0);
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: l10n.dailyRevenue,
            value: currency.format(dailyRevenue),
            icon: Icons.trending_up_rounded,
            accent: accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            label: l10n.recentSales,
            value: "$totalOrders",
            icon: Icons.receipt_long_rounded,
            accent: AppTheme.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final darker = Color.lerp(accent, Colors.black, 0.15)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, darker],
          begin: Alignment.topLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A2E),
      ),
    );
  }
}

class _RecentOrdersCard extends StatelessWidget {
  final List orders;
  final Color accent;

  const _RecentOrdersCard({required this.orders, required this.accent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (orders.isEmpty) {
      return _EmptyCard(text: l10n.recentHistory);
    }

    final currency = NumberFormat.currency(symbol: '', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: orders.asMap().entries.map((entry) {
          final idx = entry.key;
          final order = entry.value;
          final isLast = idx == orders.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: Color(0xFFF0F0F5))),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_rounded, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.items.length} ${l10n.itemsLabel}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy • HH:mm').format(order.date),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  currency.format(order.totalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: accent,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StockAlertsCard extends StatelessWidget {
  final List<Product> products;
  final Color accent;

  const _StockAlertsCard({required this.products, required this.accent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: products.take(5).map<Widget>((p) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.1),
              child: Icon(Icons.warning_amber_rounded, color: accent, size: 20),
            ),
            title: Text(p.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text('${l10n.inventory}: ${p.stock} (Min: ${p.minStockAlert})',
                style: const TextStyle(fontSize: 11)),
            trailing: Text(l10n.restockLabel,
                style: TextStyle(
                    color: accent, fontWeight: FontWeight.bold, fontSize: 10)),
          );
        }).toList(),
      ),
    );
  }
}

class _CaRecapCard extends StatelessWidget {
  final DashboardState state;
  final Color accent;

  const _CaRecapCard({required this.state, required this.accent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cur = NumberFormat.currency(symbol: 'XAF ', decimalDigits: 0);
    final weeklyCA = state.weeklySales.values.fold<double>(0, (sum, val) => sum + val);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          _CaItem(label: l10n.today, value: cur.format(state.dailyRevenue), color: AppTheme.primaryColor),
          const Divider(height: 24),
          _CaItem(label: l10n.thisWeek, value: cur.format(weeklyCA), color: AppTheme.primaryDark),
          const Divider(height: 24),
          _CaItem(label: l10n.thisMonth, value: cur.format(weeklyCA * 4), color: AppTheme.primaryLight),
        ],
      ),
    );
  }
}

class _CaItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CaItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
