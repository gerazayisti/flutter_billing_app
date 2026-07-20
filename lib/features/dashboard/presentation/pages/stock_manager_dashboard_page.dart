import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/interactive_guide_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Stock Manager Dashboard Page — vue réduite pour le gestionnaire de stock.
// Seules les permissions accordées au rôle stockManager sont exposées :
//   • Produits  (canAccessInventory)
//   • Stock     (canAccessInventory)
//   • Alertes de stock
//   • Top produits (lecture)
// La couleur d'accent suit AppColorConfig.accentColor (choix de l'utilisateur).
// ──────────────────────────────────────────────────────────────────────────────

class StockManagerDashboardPage extends StatefulWidget {
  const StockManagerDashboardPage({super.key});

  @override
  State<StockManagerDashboardPage> createState() =>
      _StockManagerDashboardPageState();
}

class _StockManagerDashboardPageState
    extends State<StockManagerDashboardPage> {
  static const Color _bg = Color(0xFFF5F5F7);
  bool _isStockAlertDismissed = false;

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const LoadDashboardEvent());
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColorConfig.accentColor;
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

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
                    if (user != null) InteractiveGuideCard(user: user),
                    const SizedBox(height: 12),

                    // ── Hero card stock ──────────────────────────────────
                    _StockHeroCard(
                      accent: accent,
                      isLoading: state.isLoading,
                      totalProducts: state.topProducts.length,
                      lowStockCount: state.lowStockProducts.length,
                    ),
                    const SizedBox(height: 28),

                    // ── Grille raccourcis (Produits + Stock uniquement) ──
                    _StockManagerActionsGrid(accent: accent),
                    const SizedBox(height: 28),

                    // ── Alertes stock ────────────────────────────────────
                    if (state.lowStockProducts.isNotEmpty && !_isStockAlertDismissed) ...[
                      _SmStockAlertCard(
                        accent: accent,
                        products: state.lowStockProducts,
                        onDismiss: () {
                          setState(() {
                            _isStockAlertDismissed = true;
                          });
                        },
                      ),
                      const SizedBox(height: 28),
                    ] else if (state.lowStockProducts.isEmpty) ...[
                      _SmNoAlertBanner(accent: accent),
                      const SizedBox(height: 28),
                    ],

                    // ── Top produits ─────────────────────────────────────
                    if (state.topProducts.isNotEmpty)
                      _SmTopProductsSection(
                        accent: accent,
                        topProducts: state.topProducts,
                      ),
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
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.black87, size: 26),
              onPressed: () {},
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Logo Gestock+ bicolore
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
// Hero card — résumé du stock
// ──────────────────────────────────────────────────────────────────────────────

class _StockHeroCard extends StatelessWidget {
  final Color accent;
  final bool isLoading;
  final int totalProducts;
  final int lowStockCount;

  const _StockHeroCard({
    required this.accent,
    required this.isLoading,
    required this.totalProducts,
    required this.lowStockCount,
  });

  @override
  Widget build(BuildContext context) {
    final darker = Color.lerp(accent, Colors.black, 0.25)!;

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
              children: [
                // ── Icône stock ──────────────────────────────────────────
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.inventory_2_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 20),

                // ── Chiffres ─────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion du stock',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$totalProducts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              'produits',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lowStockCount == 0
                            ? 'Stock en bonne santé ✓'
                            : '$lowStockCount en alerte de stock ⚠️',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Grille réduite — Produits + Stock uniquement (droits stockManager)
// ──────────────────────────────────────────────────────────────────────────────

class _SmAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
  const _SmAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
  });
}

class _StockManagerActionsGrid extends StatelessWidget {
  final Color accent;

  static const List<_SmAction> _actions = [
    _SmAction(
      icon: Icons.inventory_2_outlined,
      label: 'Produits',
      subtitle: 'Catalogue',
      route: '/products',
    ),
    _SmAction(
      icon: Icons.layers_outlined,
      label: 'Stock',
      subtitle: 'Mouvements',
      route: '/stock',
    ),
  ];

  const _StockManagerActionsGrid({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _actions.map((action) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: action == _actions.first ? 8 : 0,
              left: action == _actions.last ? 8 : 0,
            ),
            child: _SmActionCard(action: action, accent: accent),
          ),
        );
      }).toList(),
    );
  }
}

class _SmActionCard extends StatefulWidget {
  final _SmAction action;
  final Color accent;
  const _SmActionCard({required this.action, required this.accent});

  @override
  State<_SmActionCard> createState() => _SmActionCardState();
}

class _SmActionCardState extends State<_SmActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
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
        context.push(widget.action.route);
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                child: Icon(widget.action.icon, color: accent, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                widget.action.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.action.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Alertes stock détaillées
// ──────────────────────────────────────────────────────────────────────────────

class _SmStockAlertCard extends StatelessWidget {
  final Color accent;
  final List products;
  final VoidCallback onDismiss;

  const _SmStockAlertCard({
    required this.accent,
    required this.products,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/stock'),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Alertes stock',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          '${products.length} produit${products.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: AppTheme.primaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.black38, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close_rounded, color: Colors.black45, size: 18),
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.8),

          // ── Liste (max 4) ─────────────────────────────────────────────
          ...products.take(4).map((p) {
            final isLast =
                products.take(4).toList().last == p;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: AppTheme.primaryColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Stock: ${p.stock} (Min: ${p.minStockAlert})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Réappro.',
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(
                      height: 1, indent: 70, endIndent: 20, thickness: 0.6),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Bannière "stock en bonne santé" (aucune alerte)
// ──────────────────────────────────────────────────────────────────────────────

class _SmNoAlertBanner extends StatelessWidget {
  final Color accent;
  const _SmNoAlertBanner({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock en bonne santé',
                  style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Aucun produit n\'atteint le seuil minimum.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Top produits (lecture seule pour le gestionnaire)
// ──────────────────────────────────────────────────────────────────────────────

class _SmTopProductsSection extends StatelessWidget {
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
  const _SmTopProductsSection(
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                          alignment: Alignment.center,
                          child: Icon(icon, color: color, size: 28),
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
