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
    if (userState is AuthAuthenticated) {
      user = userState.user;
    }
    
    final isAdmin = user?.role == Role.admin;

    return Drawer(
      child: Column(
        children: [
          _buildHeader(context, user),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.point_of_sale_rounded,
                  label: l10n.pos,
                  route: '/home',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.history_rounded,
                  label: l10n.history,
                  route: '/orders',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  label: l10n.inventory,
                  route: '/products',
                ),
                if (isAdmin)
                  _buildNavItem(
                    context,
                    icon: Icons.bar_chart_rounded,
                    label: l10n.dashboard,
                    route: '/dashboard',
                  ),
                const Divider(),
                _buildNavItem(
                  context,
                  icon: Icons.settings_outlined,
                  label: l10n.settings,
                  route: '/settings',
                ),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? l10n.user,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            user?.role == Role.admin ? l10n.admin : l10n.cashier,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey[600]),
      title: Text(label, style: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.primaryColor : Colors.black87,
      )),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withOpacity(0.05),
      onTap: () {
        Navigator.pop(context); // Close drawer
        context.go(route);
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: OutlinedButton.icon(
        onPressed: () {
          context.read<AuthBloc>().add(LogoutEvent());
          context.go('/');
        },
        icon: const Icon(Icons.logout_rounded),
        label: Text(l10n.logout),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
