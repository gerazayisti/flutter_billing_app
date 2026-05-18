import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../subscription/domain/subscription.dart';

class BoutiquesPage extends StatefulWidget {
  const BoutiquesPage({super.key});

  @override
  State<BoutiquesPage> createState() => _BoutiquesPageState();
}

class _BoutiquesPageState extends State<BoutiquesPage> {
  List<Map<String, dynamic>> _shops = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authService = context.read<AuthBloc>().authService;
      final shops = await authService.getOwnerShops();
      if (mounted) {
        setState(() {
          _shops = shops;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  int get _maxBoutiques {
    final tier = SubscriptionService.activeTier;
    final plan = PlanConfig.all.firstWhere(
      (p) => p.tier == tier,
      orElse: () => PlanConfig.all.first,
    );
    return plan.maxBoutiques;
  }

  bool get _canAddMore =>
      _maxBoutiques == -1 || _shops.length < _maxBoutiques;

  @override
  Widget build(BuildContext context) {
    final accent = AppColorConfig.accentColor;
    final authState = context.read<AuthBloc>().state;
    final currentShopId =
        authState is AuthAuthenticated ? authState.shopId : '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mes Boutiques',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadShops,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _error != null
              ? _buildError(accent)
              : _buildContent(context, accent, currentShopId),
      floatingActionButton: _buildFab(context, accent),
    );
  }

  Widget _buildContent(
      BuildContext context, Color accent, String currentShopId) {
    return Column(
      children: [
        _buildSubscriptionBar(accent),
        Expanded(
          child: _shops.isEmpty
              ? _buildEmpty(accent)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _shops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _ShopCard(
                    shop: _shops[i],
                    accent: accent,
                    isCurrent: _shops[i]['id'] == currentShopId,
                    onEdit: () => context.push('/shop'),
                    onSwitch: _shops[i]['id'] != currentShopId
                        ? () => _switchShop(context, _shops[i])
                        : null,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionBar(Color accent) {
    final tier = SubscriptionService.activeTier;
    final max = _maxBoutiques;
    final label = max == -1 ? 'Illimité' : '$max max';
    final tierName = switch (tier) {
      SubscriptionTier.trial => 'Essai',
      SubscriptionTier.starter => 'Starter',
      SubscriptionTier.pro => 'Pro',
      SubscriptionTier.business => 'Business',
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_rounded, color: accent, size: 18),
          const SizedBox(width: 8),
          Text(
            'Plan $tierName · $label · ${_shops.length} boutique${_shops.length > 1 ? 's' : ''}',
            style: TextStyle(
                fontSize: 12,
                color: accent,
                fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (!_canAddMore)
            GestureDetector(
              onTap: () => context.push('/subscription'),
              child: Text(
                'Mettre à niveau →',
                style: TextStyle(
                    fontSize: 11,
                    color: accent,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty(Color accent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Aucune boutique trouvée',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Créez votre première boutique',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildError(Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('Impossible de charger les boutiques',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Vérifiez votre connexion',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadShops,
              style: ElevatedButton.styleFrom(
                  backgroundColor: accent, foregroundColor: Colors.white),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFab(BuildContext context, Color accent) {
    if (!_canAddMore) return null;
    return FloatingActionButton.extended(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_business_rounded),
      label: const Text('Ajouter une boutique',
          style: TextStyle(fontWeight: FontWeight.bold)),
      onPressed: () => _showAddSheet(context, accent),
    );
  }

  void _showAddSheet(BuildContext context, Color accent) {
    if (!_canAddMore) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Votre plan permet $_maxBoutiques boutique(s) maximum. Passez à Pro ou Business.'),
        backgroundColor: AppTheme.errorColor,
        action: SnackBarAction(
          label: 'Voir les plans',
          textColor: Colors.white,
          onPressed: () => context.push('/subscription'),
        ),
      ));
      return;
    }

    final nameCtrl = TextEditingController();
    final authBloc = context.read<AuthBloc>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_business_rounded, color: accent),
                    const SizedBox(width: 10),
                    const Text('Nouvelle boutique',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nom de la boutique',
                    hintText: 'Ex: Épicerie du Centre',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accent, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          setSheetState(() => saving = true);
                          final state = authBloc.state;
                          if (state is AuthAuthenticated) {
                            final newId =
                                await authBloc.authService.createShop(
                              state.user.id,
                              name,
                            );
                            if (mounted) {
                              Navigator.pop(sheetCtx);
                              if (newId != null) {
                                await _loadShops();
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text(
                                      'Erreur lors de la création'),
                                  backgroundColor: AppTheme.errorColor,
                                ));
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Créer la boutique',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _switchShop(
      BuildContext context, Map<String, dynamic> shop) {
    final authBloc = context.read<AuthBloc>();
    final state = authBloc.state;
    if (state is! AuthAuthenticated) return;

    authBloc.add(SwitchShopEvent(
      shopId: shop['id'] as String,
      shopData: shop,
    ));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text('Boutique active : ${shop['name'] ?? shop['id']}'),
      backgroundColor: AppTheme.primaryColor,
    ));

    context.pop();
  }
}

// ── Shop card ──────────────────────────────────────────────────────────────────

class _ShopCard extends StatelessWidget {
  final Map<String, dynamic> shop;
  final Color accent;
  final bool isCurrent;
  final VoidCallback onEdit;
  final VoidCallback? onSwitch;

  const _ShopCard({
    required this.shop,
    required this.accent,
    required this.isCurrent,
    required this.onEdit,
    this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final name = shop['name'] as String? ?? 'Sans nom';
    final city = shop['city'] as String? ?? '';
    final shopType = shop['shop_type'] as String? ?? '';
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : 'B';

    return Container(
      decoration: BoxDecoration(
        color: isCurrent
            ? accent.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isCurrent ? accent : AppTheme.borderColor,
            width: isCurrent ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(initials,
                  style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Active',
                              style: TextStyle(
                                  color: accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  if (city.isNotEmpty || shopType.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        [if (shopType.isNotEmpty) shopType, if (city.isNotEmpty) city].join(' · '),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                if (isCurrent)
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: accent, size: 20),
                    tooltip: 'Modifier',
                    onPressed: onEdit,
                  ),
                if (onSwitch != null)
                  IconButton(
                    icon: Icon(Icons.swap_horiz_rounded,
                        color: Colors.black54, size: 20),
                    tooltip: 'Définir comme active',
                    onPressed: onSwitch,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
