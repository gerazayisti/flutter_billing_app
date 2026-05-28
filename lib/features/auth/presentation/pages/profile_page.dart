import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../subscription/domain/subscription.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppColorConfig.accentColor;
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, accent, user),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSubscriptionCard(context, accent),
                const SizedBox(height: 16),
                _buildActionsCard(context, accent),
                const SizedBox(height: 24),
                _buildLogoutButton(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
      BuildContext context, Color accent, User user) {
    final initials = _initials(user.name);
    final roleLabel = switch (user.role) {
      Role.owner => 'Propriétaire',
      Role.cashier => 'Caissier',
      Role.stockManager => 'Gestionnaire stock',
    };

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: accent,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Mon Profil',
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, Color.lerp(accent, Colors.black, 0.25)!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.only(top: kToolbarHeight + 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, Color accent) {
    final sub = SubscriptionService.current;
    final isTrial = sub == null && SubscriptionService.isTrialActive;
    final tier = SubscriptionService.activeTier;
    final tierLabel = isTrial
        ? 'Essai Pro gratuit'
        : switch (tier) {
            SubscriptionTier.trial => 'Expiré',
            SubscriptionTier.starter => 'Starter',
            SubscriptionTier.pro => 'Pro',
            SubscriptionTier.business => 'Business',
          };

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (sub != null && sub.isActive) {
      statusText = '${sub.daysRemaining} jours restants';
      statusColor = accent;
      statusIcon = Icons.verified_rounded;
    } else if (isTrial) {
      statusText = '${SubscriptionService.trialDaysRemaining} jours restants';
      statusColor = AppTheme.primaryColor;
      statusIcon = Icons.hourglass_bottom_rounded;
    } else {
      statusText = 'Expiré — Abonnez-vous';
      statusColor = AppTheme.errorColor;
      statusIcon = Icons.warning_amber_rounded;
    }

    return _CardSection(
      child: ListTile(
        onTap: () => context.push('/subscription'),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.workspace_premium_rounded, color: accent, size: 22),
        ),
        title: Text(
          'Plan $tierLabel',
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            Icon(statusIcon, size: 14, color: statusColor),
            const SizedBox(width: 4),
            Text(statusText,
                style: TextStyle(fontSize: 12, color: statusColor)),
          ],
        ),
        trailing: Icon(Icons.chevron_right_rounded,
            color: Colors.grey[300], size: 22),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, Color accent) {
    return _CardSection(
      child: ListTile(
        onTap: () => context.push('/settings'),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.settings_outlined, color: accent, size: 22),
        ),
        title: const Text('Paramètres',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: Colors.grey[300], size: 22),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        context.read<AuthBloc>().add(LogoutEvent());
        context.go('/');
      },
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text('Se déconnecter'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        foregroundColor: AppTheme.errorColor,
        side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    return parts
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join()
        .ifEmpty('U');
  }
}

class _CardSection extends StatelessWidget {
  final Widget child;
  const _CardSection({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: child,
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
