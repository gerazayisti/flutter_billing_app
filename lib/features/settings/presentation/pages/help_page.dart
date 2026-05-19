import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/theme/app_color_config.dart';
import 'package:billing_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:billing_app/features/auth/domain/entities/user.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/l10n/app_localizations.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppColorConfig.accentColor;
    final l10n = AppLocalizations.of(context)!;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.helpCenter)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;
    final roleLabel = switch (user.role) {
      Role.owner => '${l10n.owner} / ${l10n.admin}',
      Role.cashier => l10n.cashier,
      Role.stockManager => l10n.stockManager,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpCenter),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.role} : $roleLabel',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.helpGuideTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.helpGuideDesc,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                l10n.keySteps,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              _buildRoleSteps(context, user, accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSteps(BuildContext context, User user, Color accent) {
    final l10n = AppLocalizations.of(context)!;
    if (user.role == Role.owner) {
      return Column(
        children: [
          _buildStepRow(
            context: context,
            num: '1',
            title: l10n.stepOwner1Title,
            description: l10n.stepOwner1Desc,
            route: '/products/add',
            icon: Icons.inventory_2_outlined,
            isCompleted: HiveDatabase.productBox.isNotEmpty,
            accent: accent,
          ),
          _buildStepRow(
            context: context,
            num: '2',
            title: l10n.stepOwner2Title,
            description: l10n.stepOwner2Desc,
            route: '/home',
            icon: Icons.point_of_sale_rounded,
            isCompleted: HiveDatabase.orderBox.isNotEmpty,
            accent: accent,
          ),
          _buildStepRow(
            context: context,
            num: '3',
            title: l10n.stepOwner3Title,
            description: l10n.stepOwner3Desc,
            route: '/settings',
            icon: Icons.print_rounded,
            isCompleted: HiveDatabase.settingsBox.get('printer_mac') != null,
            accent: accent,
          ),
          _buildStepRow(
            context: context,
            num: '4',
            title: l10n.stepOwner4Title,
            description: l10n.stepOwner4Desc,
            route: '/users',
            icon: Icons.people_outline_rounded,
            isCompleted: HiveDatabase.usersBox.values.any((u) => u.role != Role.owner),
            accent: accent,
          ),
          const SizedBox(height: 16),
          Card(
            color: accent.withOpacity(0.08),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: accent.withOpacity(0.2)),
            ),
            child: InkWell(
              onTap: () {
                HiveDatabase.settingsBox.put('has_seen_spotlight_owner', false);
                context.go('/');
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.play_circle_fill_rounded, color: accent, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.guidedTour,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.guidedTourDesc,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: accent, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else if (user.role == Role.cashier) {
      final hasDoneSale = HiveDatabase.stockMovementsBox.values.any(
        (m) => m.operatorId == user.id && m.typeName == 'saleOut',
      );
      return Column(
        children: [
          _buildStepRow(
            context: context,
            num: '1',
            title: l10n.stepCashier1Title,
            description: l10n.stepCashier1Desc,
            route: '/home',
            icon: Icons.point_of_sale_rounded,
            isCompleted: hasDoneSale,
            accent: accent,
          ),
          _buildStepRow(
            context: context,
            num: '2',
            title: l10n.stepCashier2Title,
            description: l10n.stepCashier2Desc,
            route: '/settings',
            icon: Icons.print_rounded,
            isCompleted: HiveDatabase.settingsBox.get('printer_mac') != null,
            accent: accent,
          ),
          _buildStepRow(
            context: context,
            num: '3',
            title: l10n.stepCashier3Title,
            description: l10n.stepCashier3Desc,
            route: '/orders',
            icon: Icons.history_rounded,
            isCompleted: hasDoneSale,
            accent: accent,
          ),
        ],
      );
    } else {
      // Stock Manager
      final hasMovements = HiveDatabase.stockMovementsBox.values.any(
        (m) => m.operatorId == user.id,
      );
      return Column(
        children: [
          _buildStepRow(
            context: context,
            num: '1',
            title: l10n.stepManager1Title,
            description: l10n.stepManager1Desc,
            route: '/products',
            icon: Icons.inventory_2_outlined,
            isCompleted: HiveDatabase.productBox.isNotEmpty,
            accent: accent,
          ),
          _buildStepRow(
            context: context,
            num: '2',
            title: l10n.stepManager2Title,
            description: l10n.stepManager2Desc,
            route: '/stock',
            icon: Icons.swap_horiz_rounded,
            isCompleted: hasMovements,
            accent: accent,
          ),
          _buildStepRow(
            context: context,
            num: '3',
            title: l10n.stepManager3Title,
            description: l10n.stepManager3Desc,
            route: '/stock',
            icon: Icons.local_shipping_outlined,
            isCompleted: HiveDatabase.suppliersBox.isNotEmpty,
            accent: accent,
          ),
        ],
      );
    }
  }

  Widget _buildStepRow({
    required BuildContext context,
    required String num,
    required String title,
    required String description,
    required String route,
    required IconData icon,
    required bool isCompleted,
    required Color accent,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: () => context.push(route),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.withOpacity(0.1) : accent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check_circle : icon,
            color: isCompleted ? Colors.green : accent,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              '$num. $title',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
            if (isCompleted) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check, color: Colors.green, size: 14),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
      ),
    );
  }
}
