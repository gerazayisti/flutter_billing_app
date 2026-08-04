import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:billing_app/features/auth/domain/entities/user.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/l10n/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userState = context.watch<AuthBloc>().state;
    User? user;
    if (userState is AuthAuthenticated) user = userState.user;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildHeader(context, user, l10n),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── POS & Caisse : owner + cashier ────────────────────
                if (user == null || user.canAccessPOS)
                  _navItem(context,
                      icon: Icons.point_of_sale_rounded,
                      label: l10n.pos,
                      route: '/home'),

                if (user == null || user.canAccessPOS)
                  _navItem(context,
                      icon: Icons.history_rounded,
                      label: l10n.history,
                      route: '/orders'),

                // ── Inventaire : owner + stockManager ─────────────────
                if (user == null || user.canAccessInventory)
                  _navItem(context,
                      icon: Icons.inventory_2_outlined,
                      label: l10n.inventory,
                      route: '/products'),

                if (user == null || user.canAccessInventory)
                  _navItem(context,
                      icon: Icons.swap_vert_rounded,
                      label: l10n.stockMovements,
                      route: '/stock'),

                if (user == null || user.canAccessInventory)
                  _navItem(context,
                      icon: Icons.analytics_outlined,
                      label: 'Rapport Inventaire',
                      route: '/inventory-report'),

                // ── Tableau de bord : owner → vue complète ────────────
                if (user == null || user.isOwner)
                  _navItem(context,
                      icon: Icons.dashboard_rounded,
                      label: l10n.dashboard,
                      route: '/owner-dashboard'),

                // ── Tableau de bord : stockManager → vue stock ────────
                if (user?.isStockManager == true)
                  _navItem(context,
                      icon: Icons.dashboard_outlined,
                      label: l10n.dashboard,
                      route: '/stock-manager-dashboard'),

                // ── Clôture caisse : owner only ───────────────────────
                if (user == null || user.isOwner)
                  _navItem(context,
                      icon: Icons.lock_clock_rounded,
                      label: l10n.cashClosure,
                      route: '/cash-closure'),

                const Divider(height: 1),

                // ── Paramètres : owner only ───────────────────────────
                if (user == null || user.canAccessSettings)
                  _navItem(context,
                      icon: Icons.settings_outlined,
                      label: l10n.settings,
                      route: '/settings'),

                // ── Gestion utilisateurs : owner only ─────────────────
                if (user == null || user.canManageUsers)
                  _navItem(context,
                      icon: Icons.people_outline_rounded,
                      label: l10n.userManagement,
                      route: '/users'),

                // ── Boutiques : owner only ────────────────────────────
                if (user == null || user.isOwner)
                  _navItem(context,
                      icon: Icons.add_business_rounded,
                      label: 'Mes Boutiques',
                      route: '/boutiques'),

                // ── Abonnement : owner only ───────────────────────────
                if (user == null || user.canAccessSettings)
                  _navItem(context,
                      icon: Icons.workspace_premium_rounded,
                      label: 'Abonnement',
                      route: '/subscription'),

                // ── Profil : tous ─────────────────────────────────────
                _navItem(context,
                    icon: Icons.person_outline_rounded,
                    label: 'Mon Profil',
                    route: '/profile'),
              ],
            ),
          ),
          _buildFooter(context, l10n),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user, AppLocalizations l10n) {
    final roleLabel = switch (user?.role) {
      Role.owner        => l10n.owner,
      Role.stockManager => l10n.stockManager,
      Role.cashier      => l10n.cashier,
      null              => l10n.user,
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white24,
            child: Icon(Icons.storefront_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? l10n.user,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              roleLabel,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(icon,
          color: isSelected
              ? AppTheme.primaryColor
              : AppTheme.textSecondary,
          size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? AppTheme.primaryColor
              : AppTheme.textPrimary,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryLight,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: OutlinedButton.icon(
        onPressed: () {
          context.read<AuthBloc>().add(LogoutEvent());
          context.go('/');
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text(l10n.logout),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          foregroundColor: AppTheme.errorColor,
          side: BorderSide(
              color: AppTheme.errorColor.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
