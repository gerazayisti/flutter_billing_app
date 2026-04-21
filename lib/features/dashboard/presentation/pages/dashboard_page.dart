import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_color_config.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../../product/domain/entities/product.dart';
import '../../../../core/widgets/app_drawer.dart';
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
                      _SectionTitle(title: 'Alertes de Stock ⚠️'),
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
                    _SectionTitle(title: 'Récapitulatif Chiffre d\'Affaires'),
                    const SizedBox(height: 12),
                    _CaRecapCard(state: state, accent: accent),
                    const SizedBox(height: 24),
                    _SectionTitle(title: 'Historique récent'),
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
    return SliverAppBar(
      expandedHeight: 120,
      collapsedHeight: 60,
      pinned: true,
      backgroundColor: accent,
      title: const Text(
        'Tableau de bord',
        style: TextStyle(
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
            const Text('Générer Rapport Financier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _ReportTile(
              icon: Icons.today,
              color: Colors.blue,
              title: 'Rapport Journalier (CA)',
              onTap: () {
                Navigator.pop(context);
                ReportService.generateDailyReport(DateTime.now());
              },
            ),
            _ReportTile(
              icon: Icons.view_week,
              color: Colors.green,
              title: 'Rapport Hebdomadaire (CA)',
              onTap: () {
                Navigator.pop(context);
                ReportService.generateWeeklyReport(DateTime.now());
              },
            ),
            _ReportTile(
              icon: Icons.calendar_month,
              color: Colors.orange,
              title: 'Rapport Mensuel (CA)',
              onTap: () {
                Navigator.pop(context);
                ReportService.generateMonthlyReport(DateTime.now());
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
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// ─── KPI Row ──────────────────────────────────────────────────────────────────
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
    final currency = NumberFormat.currency(symbol: '', decimalDigits: 0);
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: "CA du jour",
            value: currency.format(dailyRevenue),
            icon: Icons.trending_up_rounded,
            accent: accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            label: "Ventes récentes",
            value: "$totalOrders",
            icon: Icons.receipt_long_rounded,
            accent: Color.lerp(accent, Colors.teal, 0.5)!,
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

// ─── Section Title ─────────────────────────────────────────────────────────────
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

// ─── Weekly Chart ──────────────────────────────────────────────────────────────
class _WeeklyChartCard extends StatelessWidget {
  final Map<DateTime, double> weeklySales;
  final Color accent;

  const _WeeklyChartCard({required this.weeklySales, required this.accent});

  @override
  Widget build(BuildContext context) {
    final entries = weeklySales.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxY = entries.isEmpty
        ? 100.0
        : (entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.3)
            .clamp(100.0, double.infinity);

    final lighter = Color.lerp(accent, Colors.white, 0.4)!;

    final bars = entries.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.value,
            gradient: LinearGradient(
              colors: [accent, lighter],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 18,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: accent.withValues(alpha: 0.08),
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: entries.isEmpty
          ? const Center(
              child: Text(
                'Pas encore de données',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: bars,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (val, _) => Text(
                        val.toInt().toString(),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            // Use simple 'E' format without locale for safety
                            DateFormat('E').format(entries[idx].key),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ─── Top Products ──────────────────────────────────────────────────────────────
class _TopProductsCard extends StatelessWidget {
  final List<MapEntry<String, int>> topProducts;
  final Color accent;

  const _TopProductsCard({required this.topProducts, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (topProducts.isEmpty) {
      return const _EmptyCard(text: 'Aucun produit vendu pour le moment');
    }

    final maxQty = topProducts.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: topProducts.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final name = entry.value.key;
          final qty = entry.value.value;
          final ratio = maxQty > 0 ? qty / maxQty : 0.0;
          final medal = rank == 1
              ? '🥇'
              : rank == 2
                  ? '🥈'
                  : rank == 3
                      ? '🥉'
                      : '  $rank.';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                    width: 32,
                    child: Text(medal,
                        style: const TextStyle(fontSize: 18))),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio.toDouble(),
                          minHeight: 6,
                          backgroundColor: accent.withValues(alpha: 0.1),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('$qty vendu${qty > 1 ? 's' : ''}',
                    style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Recent Orders ─────────────────────────────────────────────────────────────
class _RecentOrdersCard extends StatelessWidget {
  final List orders;
  final Color accent;

  const _RecentOrdersCard({required this.orders, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const _EmptyCard(text: 'Aucune vente enregistrée');
    }

    final currency = NumberFormat.currency(symbol: '', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                        '${order.items.length} article${order.items.length > 1 ? 's' : ''}',
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

// ─── Stock Alerts ──────────────────────────────────────────────────────────────
class _StockAlertsCard extends StatelessWidget {
  final List<Product> products;
  final Color accent;

  const _StockAlertsCard({required this.products, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
            subtitle: Text('Stock: ${p.stock} (Min: ${p.minStockAlert})',
                style: const TextStyle(fontSize: 11)),
            trailing: Text('REAPPRO.',
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
    final cur = NumberFormat.currency(symbol: 'XAF ', decimalDigits: 0);
    // Weekly CA
    final weeklyCA = state.weeklySales.values.fold<double>(0, (sum, val) => sum + val);
    // Monthly CA (Mock/Approx from weekly sales for now, or we'd need a separate usecase)
    // Actually, in a real app, the DashboardBloc would provide separate day/week/month totals.
    // For now, let's treat the 7-day total as "Week" and we'll assume Monthly CA is tracked in Hive.
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _CaItem(label: 'Aujourd\'hui', value: cur.format(state.dailyRevenue), color: Colors.blue),
          const Divider(height: 24),
          _CaItem(label: 'Cette Semaine', value: cur.format(weeklyCA), color: Colors.green),
          const Divider(height: 24),
          _CaItem(label: 'Ce Mois (Est.)', value: cur.format(weeklyCA * 4), color: Colors.orange), // Simplified estimation
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
