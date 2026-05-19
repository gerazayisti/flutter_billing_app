import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/theme/app_color_config.dart';
import 'package:billing_app/features/auth/domain/entities/user.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/l10n/app_localizations.dart';

class InteractiveGuideCard extends StatefulWidget {
  final User user;
  const InteractiveGuideCard({super.key, required this.user});

  @override
  State<InteractiveGuideCard> createState() => _InteractiveGuideCardState();
}

class _InteractiveGuideCardState extends State<InteractiveGuideCard> {
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    final key = 'has_seen_guide_${widget.user.id}';
    _isDismissed = HiveDatabase.settingsBox.get(key, defaultValue: false) as bool;
  }

  void _dismissGuide() {
    final key = 'has_seen_guide_${widget.user.id}';
    HiveDatabase.settingsBox.put(key, true);
    setState(() {
      _isDismissed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final accent = AppColorConfig.accentColor;
    final role = widget.user.role;
    final l10n = AppLocalizations.of(context)!;

    final List<_GuideTask> tasks = [];
    if (role == Role.owner) {
      tasks.addAll([
        _GuideTask(
          title: l10n.stepOwner1Title,
          route: '/products/add',
          icon: Icons.inventory_2_outlined,
          isCompleted: HiveDatabase.productBox.isNotEmpty,
        ),
        _GuideTask(
          title: l10n.stepOwner2Title,
          route: '/home',
          icon: Icons.point_of_sale_rounded,
          isCompleted: HiveDatabase.orderBox.isNotEmpty,
        ),
        _GuideTask(
          title: l10n.stepOwner3Title,
          route: '/settings',
          icon: Icons.print_rounded,
          isCompleted: HiveDatabase.settingsBox.get('printer_mac') != null,
        ),
        _GuideTask(
          title: l10n.stepOwner4Title,
          route: '/users',
          icon: Icons.people_outline_rounded,
          isCompleted: HiveDatabase.usersBox.values.any((u) => u.role != Role.owner),
        ),
      ]);
    } else if (role == Role.cashier) {
      final hasDoneSale = HiveDatabase.stockMovementsBox.values.any(
        (m) => m.operatorId == widget.user.id && m.typeName == 'saleOut',
      );
      tasks.addAll([
        _GuideTask(
          title: l10n.stepCashier1Title,
          route: '/home',
          icon: Icons.point_of_sale_rounded,
          isCompleted: hasDoneSale,
        ),
        _GuideTask(
          title: l10n.stepCashier2Title,
          route: '/settings',
          icon: Icons.print_rounded,
          isCompleted: HiveDatabase.settingsBox.get('printer_mac') != null,
        ),
        _GuideTask(
          title: l10n.stepCashier3Title,
          route: '/orders',
          icon: Icons.history_rounded,
          isCompleted: hasDoneSale,
        ),
      ]);
    } else {
      // Stock Manager
      final hasMovements = HiveDatabase.stockMovementsBox.values.any(
        (m) => m.operatorId == widget.user.id,
      );
      tasks.addAll([
        _GuideTask(
          title: l10n.stepManager1Title,
          route: '/products',
          icon: Icons.inventory_2_outlined,
          isCompleted: HiveDatabase.productBox.isNotEmpty,
        ),
        _GuideTask(
          title: l10n.stepManager2Title,
          route: '/stock',
          icon: Icons.swap_horiz_rounded,
          isCompleted: hasMovements,
        ),
        _GuideTask(
          title: l10n.stepManager3Title,
          route: '/stock',
          icon: Icons.local_shipping_outlined,
          isCompleted: HiveDatabase.suppliersBox.isNotEmpty,
        ),
      ]);
    }

    final allCompleted = tasks.every((t) => t.isCompleted);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent header
            Container(
              color: accent.withOpacity(0.05),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.rocket_launch_rounded, color: accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.quickStartGuide,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismissGuide,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.hide,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Steps body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (allCompleted) ...[
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.congratulations,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.allStepsCompleted,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return InkWell(
                          onTap: () => context.push(task.route),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: task.isCompleted
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    task.isCompleted ? Icons.check : task.icon,
                                    size: 14,
                                    color: task.isCompleted ? Colors.green : Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.bold,
                                      color: task.isCompleted ? Colors.grey[600] : AppTheme.textPrimary,
                                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideTask {
  final String title;
  final String route;
  final IconData icon;
  final bool isCompleted;

  const _GuideTask({
    required this.title,
    required this.route,
    required this.icon,
    required this.isCompleted,
  });
}
