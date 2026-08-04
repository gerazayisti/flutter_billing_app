import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/features/stock/presentation/bloc/stock_bloc.dart';
import 'package:billing_app/features/stock/domain/entities/stock_movement.dart';
import 'package:billing_app/features/reports/utils/inventory_exporter.dart';
import 'package:intl/intl.dart';
import 'package:billing_app/l10n/app_localizations.dart';

enum ReportPeriod { today, thisWeek, thisMonth, custom }

class InventoryReportPage extends StatefulWidget {
  const InventoryReportPage({super.key});

  @override
  State<InventoryReportPage> createState() => _InventoryReportPageState();
}

class _InventoryReportPageState extends State<InventoryReportPage> {
  ReportPeriod _period = ReportPeriod.thisMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case ReportPeriod.thisWeek:
        return now.subtract(Duration(days: now.weekday - 1)).copyWith(
            hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
      case ReportPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case ReportPeriod.custom:
        return _customStartDate ?? DateTime(now.year, now.month, 1);
    }
  }

  DateTime get _endDate {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case ReportPeriod.thisWeek:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case ReportPeriod.thisMonth:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case ReportPeriod.custom:
        final end = _customEndDate ?? now;
        return DateTime(end.year, end.month, end.day, 23, 59, 59);
    }
  }

  String get _shopName {
    final shopBox = HiveDatabase.shopBox;
    return shopBox.values.isNotEmpty ? shopBox.values.first.name : 'Ma Boutique';
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final start = _customStartDate ?? DateTime(now.year, now.month, 1);
    final end = _customEndDate ?? DateTime(now.year, now.month, now.day);

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: DateTimeRange(
        start: start,
        end: end,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _period = ReportPeriod.custom;
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    } else {
      if (_customStartDate == null) {
        setState(() {
          _period = ReportPeriod.thisMonth;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(l10n.inventoryReport,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: BlocBuilder<StockBloc, StockState>(
        builder: (context, state) {
          final movements = state.movements
              .where((m) =>
                  m.date.isAfter(_startDate) && m.date.isBefore(_endDate))
              .toList();

          int totalIn = 0;
          int totalOut = 0;
          for (var m in movements) {
            if (m.type.isIn) {
              totalIn += m.quantity;
            } else {
              totalOut += m.quantity;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.selectPeriod,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),

                // Dropdown pour la période
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ReportPeriod>(
                      value: _period,
                      isExpanded: true,
                      icon: const Icon(Icons.calendar_today,
                          color: AppTheme.primaryColor, size: 20),
                      items: [
                        DropdownMenuItem(
                            value: ReportPeriod.today, child: Text(l10n.today)),
                        DropdownMenuItem(
                            value: ReportPeriod.thisWeek,
                            child: Text(l10n.thisWeek)),
                        DropdownMenuItem(
                            value: ReportPeriod.thisMonth,
                            child: Text(l10n.thisMonth)),
                        DropdownMenuItem(
                            value: ReportPeriod.custom,
                            child: Text(l10n.customPeriod)),
                      ],
                      onChanged: (ReportPeriod? newValue) {
                        if (newValue == ReportPeriod.custom) {
                          _selectCustomDateRange();
                        } else if (newValue != null) {
                          setState(() {
                            _period = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.analytics_outlined,
                            size: 48, color: AppTheme.primaryColor),
                        const SizedBox(height: 16),
                        Text(l10n.periodOverview,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                            '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(l10n.movements,
                                movements.length.toString(), AppTheme.primaryColor),
                            _buildStatItem(
                                l10n.entries, '+$totalIn', AppTheme.primaryColor),
                            _buildStatItem(
                                l10n.exits, '-$totalOut', AppTheme.primaryColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                Text(l10n.downloadReport,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => InventoryExporter.exportMovementReportPDF(
                            movements, _startDate, _endDate, _shopName),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(l10n.exportPdf),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => InventoryExporter.exportMovementReportCSV(
                            movements, _startDate, _endDate, _shopName),
                        icon: const Icon(Icons.table_chart),
                        label: Text(l10n.exportExcel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 24, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
