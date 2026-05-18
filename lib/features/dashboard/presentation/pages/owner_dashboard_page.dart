import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../subscription/domain/subscription.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../../notifications/presentation/bloc/notification_bloc.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Owner Dashboard Page — vue principale du propriétaire de boutique.
// Toutes les couleurs d'accentuation passent par AppColorConfig.accentColor
// afin de respecter le choix de couleur fait dans les Paramètres.
// ──────────────────────────────────────────────────────────────────────────────

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  static const Color _bg = AppTheme.backgroundColor;

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const LoadDashboardEvent());
    context.read<NotificationBloc>().add(LoadNotificationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    // Lire la couleur d'accent à chaque rebuild (peut changer dans Paramètres)
    final accent = AppColorConfig.accentColor;

    return Scaffold(
      backgroundColor: _bg,
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              _buildAppBar(context, accent),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),

                    // ── Hero card ventes du jour ─────────────────────────
                    _HeroSalesCard(
                      accent: accent,
                      isLoading: state.isLoading,
                      dailyRevenue: state.dailyRevenue,
                      transactionCount: state.recentOrders.length,
                      weeklySales: state.weeklySales,
                    ),
                    const SizedBox(height: 12),

                    // ── Subscription status banner ───────────────────────
                    _SubscriptionBanner(accent: accent),
                    const SizedBox(height: 16),

                    // ── Grille de raccourcis ─────────────────────────────
                    _QuickActionsGrid(accent: accent),
                    const SizedBox(height: 28),

                    // ── Alerte stock ─────────────────────────────────────
                    if (state.lowStockProducts.isNotEmpty) ...[
                      _StockAlertCard(
                          accent: accent,
                          count: state.lowStockProducts.length),
                      const SizedBox(height: 28),
                    ],

                    // ── Top produits ─────────────────────────────────────
                    if (state.topProducts.isNotEmpty)
                      _TopProductsSection(
                          accent: accent, topProducts: state.topProducts),
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
      pinned: true,
      floating: false,
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.black87, size: 26),
        onPressed: () {},
      ),
      title: _GestockLogo(accent: accent),
      centerTitle: true,
      actions: [
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, notifState) {
            final count = notifState.unreadCount;
            return Stack(
              children: [
                IconButton(
                  icon: Icon(
                    count > 0
                        ? Icons.notifications_rounded
                        : Icons.notifications_outlined,
                    color: Colors.black87,
                    size: 26,
                  ),
                  onPressed: () {
                    context.push('/notifications');
                    context
                        .read<NotificationBloc>()
                        .add(MarkAllReadEvent());
                  },
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Logo Gestock+ (texte bicolore — le '+' suit la couleur d'accent)
// ──────────────────────────────────────────────────────────────────────────────

class _GestockLogo extends StatelessWidget {
  final Color accent;
  const _GestockLogo({required this.accent});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'Gestock',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: '+',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: accent,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Subscription banner
// ──────────────────────────────────────────────────────────────────────────────

class _SubscriptionBanner extends StatelessWidget {
  final Color accent;
  const _SubscriptionBanner({required this.accent});

  @override
  Widget build(BuildContext context) {
    final sub = SubscriptionService.current;

    if (sub != null && sub.isActive) {
      final tierLabel = switch (sub.tier) {
        SubscriptionTier.starter => 'Starter',
        SubscriptionTier.pro => 'Pro',
        SubscriptionTier.business => 'Business',
        SubscriptionTier.trial => 'Essai',
      };
      return _BannerTile(
        icon: Icons.verified_rounded,
        color: accent,
        text: 'Gestock+ $tierLabel · ${sub.daysRemaining}j restants',
        onTap: () => context.push('/subscription'),
      );
    }

    final days = SubscriptionService.trialDaysRemaining;
    if (days > 0) {
      return _BannerTile(
        icon: Icons.hourglass_bottom_rounded,
        color: AppTheme.primaryColor,
        text: 'Essai gratuit · $days jours restants — Voir les plans',
        onTap: () => context.push('/subscription'),
      );
    }

    return _BannerTile(
      icon: Icons.warning_amber_rounded,
      color: AppTheme.errorColor,
      text: 'Essai expiré — Abonnez-vous pour continuer',
      onTap: () => context.push('/subscription'),
    );
  }
}

class _BannerTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onTap;

  const _BannerTile({
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Hero card — Ventes du jour
// ──────────────────────────────────────────────────────────────────────────────

class _HeroSalesCard extends StatelessWidget {
  final Color accent;
  final bool isLoading;
  final double dailyRevenue;
  final int transactionCount;
  final Map<DateTime, double> weeklySales;

  const _HeroSalesCard({
    required this.accent,
    required this.isLoading,
    required this.dailyRevenue,
    required this.transactionCount,
    required this.weeklySales,
  });

  @override
  Widget build(BuildContext context) {
    final darker = Color.lerp(accent, Colors.black, 0.25)!;
    final currency = NumberFormat('#,###', 'fr_FR');
    final formatted = currency.format(dailyRevenue.toInt());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, darker],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isLoading
          ? const SizedBox(
              height: 90,
              child: Center(
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left — label + montant + transactions
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ventes du jour',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$formatted ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const TextSpan(
                              text: 'FCFA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$transactionCount transactions',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right — badge % variation vs yesterday
                _buildDayComparison(),
              ],
            ),
    );
  }

  Widget _buildDayComparison() {
    final now = DateTime.now();
    final yesterdayKey = DateTime(now.year, now.month, now.day - 1);
    final yesterdayRevenue = weeklySales[yesterdayKey] ?? 0.0;

    String label;
    if (yesterdayRevenue == 0) {
      label = '--';
    } else {
      final pct = ((dailyRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
      final sign = pct >= 0 ? '+' : '';
      label = '$sign${pct.toStringAsFixed(1)}%';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'vs hier',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Grille 4×2 de raccourcis
// ──────────────────────────────────────────────────────────────────────────────

class _QuickAction {
  final IconData icon;
  final String label;
  final String? route;
  const _QuickAction({required this.icon, required this.label, this.route});
}

class _QuickActionsGrid extends StatelessWidget {
  final Color accent;

  static const List<_QuickAction> _actions = [
    _QuickAction(
        icon: Icons.point_of_sale_rounded, label: 'Caisse', route: '/home'),
    _QuickAction(
        icon: Icons.inventory_2_outlined,
        label: 'Produits',
        route: '/products'),
    _QuickAction(
        icon: Icons.layers_outlined, label: 'Stock', route: '/stock'),
    _QuickAction(
        icon: Icons.bar_chart_rounded,
        label: 'Rapports',
        route: '/dashboard'),
    _QuickAction(
        icon: Icons.add_business_rounded,
        label: 'Boutiques',
        route: '/boutiques'),
    _QuickAction(
        icon: Icons.people_outline_rounded,
        label: 'Employés',
        route: '/users'),
    _QuickAction(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Caisses',
        route: '/cash-closure'),
    _QuickAction(
        icon: Icons.settings_outlined,
        label: 'Paramètres',
        route: '/settings'),
    _QuickAction(
        icon: Icons.workspace_premium_rounded,
        label: 'Abonnement',
        route: '/subscription'),
    _QuickAction(
        icon: Icons.person_outline_rounded,
        label: 'Mon Profil',
        route: '/profile'),
  ];

  const _QuickActionsGrid({required this.accent});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _actions.length,
      itemBuilder: (context, index) {
        return _QuickActionTile(action: _actions[index], accent: accent);
      },
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  final _QuickAction action;
  final Color accent;
  const _QuickActionTile({required this.action, required this.accent});

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        if (widget.action.route != null) {
          context.push(widget.action.route!);
        }
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    Icon(widget.action.icon, color: accent, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                widget.action.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Alerte stock
// ──────────────────────────────────────────────────────────────────────────────

class _StockAlertCard extends StatelessWidget {
  final Color accent;
  final int count;
  const _StockAlertCard({required this.accent, required this.count});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/stock'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alertes stock',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count produit${count > 1 ? 's' : ''} atteignent le seuil minimum',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.black38, size: 24),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Top produits
// ──────────────────────────────────────────────────────────────────────────────

class _TopProductsSection extends StatelessWidget {
  static const List<Color> _colors = [
    Color(0xFF6C63FF), // violet
    Color(0xFF4B44CC), // violet foncé
    Color(0xFF8B7FF5), // violet clair
    Color(0xFF1A1A2E), // noir profond
    Color(0xFF6B6B80), // gris foncé
  ];

  static const List<IconData> _icons = [
    Icons.shopping_bag_outlined,
    Icons.local_drink_outlined,
    Icons.set_meal_outlined,
    Icons.spa_outlined,
    Icons.lunch_dining_outlined,
  ];

  final Color accent;
  final List<MapEntry<String, int>> topProducts;
  const _TopProductsSection(
      {required this.accent, required this.topProducts});

  @override
  Widget build(BuildContext context) {
    final items = topProducts.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top produits',
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final entry = items[i];
              final isLast = i == items.length - 1;
              final color = _colors[i % _colors.length];
              final icon = _icons[i % _icons.length];

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${entry.value} vendu${entry.value > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1,
                        indent: 74,
                        endIndent: 16,
                        thickness: 0.8),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
