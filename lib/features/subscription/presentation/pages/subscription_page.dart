import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_color_config.dart';
import '../../domain/subscription.dart';
import '../bloc/subscription_bloc.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> with WidgetsBindingObserver {
  bool _isYearly = false;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SubscriptionBloc>().add(const CheckAutoSubscriptionEvent());
    }
  }

  void _startAutoChecking() {
    _autoCheckTimer?.cancel();
    int attempts = 0;
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      attempts++;
      if (!mounted || attempts > 45) {
        timer.cancel();
        return;
      }
      context.read<SubscriptionBloc>().add(const CheckAutoSubscriptionEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColorConfig.accentColor;

    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state.activated) {
          _autoCheckTimer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('🎉 Abonnement activé avec succès !',
                style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.primaryColor,
          ));
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.error!),
            backgroundColor: AppTheme.errorColor,
          ));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Gérer l\'abonnement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Status banner ─────────────────────────────────────────
                _buildStatusBanner(context, state, accent),
                const SizedBox(height: 20),

                // ── Monthly / yearly toggle ───────────────────────────────
                _buildBillingToggle(accent),
                const SizedBox(height: 20),

                // ── Plan cards ────────────────────────────────────────────
                ...PlanConfig.all.map((plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PlanCard(
                        plan: plan,
                        isYearly: _isYearly,
                        accent: accent,
                        activeTier: state.activeTier,
                        currentInfo: state.info,
                        onSubscribe: () =>
                            _showPaymentSheet(context, plan, accent),
                      ),
                    )),

                const SizedBox(height: 8),
                _buildFaqNote(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Status banner ─────────────────────────────────────────────────────────

  Widget _buildStatusBanner(
      BuildContext context, SubscriptionState state, Color accent) {
    if (state.info != null && state.info!.isActive) {
      final expiry = DateFormat('dd/MM/yyyy').format(state.info!.expiryDate);
      return _banner(
        icon: Icons.verified_rounded,
        color: accent,
        title: 'Gestock+ ${_tierLabel(state.info!.tier)}',
        subtitle: 'Actif jusqu\'au $expiry · ${state.info!.daysRemaining} jours restants',
        trailing: TextButton(
          onPressed: () => context.read<SubscriptionBloc>().add(const CheckAutoSubscriptionEvent()),
          child: Text('Actualiser',
              style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
        ),
      );
    }

    final days = state.trialDaysRemaining;
    if (days > 0) {
      return _banner(
        icon: Icons.timer_rounded,
        color: AppTheme.primaryColor,
        title: 'Essai Pro gratuit actif',
        subtitle: 'Accès Pro complet · $days jours restants',
        trailing: null,
      );
    }

    return _banner(
      icon: Icons.warning_amber_rounded,
      color: AppTheme.errorColor,
      title: 'Essai expiré',
      subtitle: 'Abonnez-vous pour continuer à utiliser Gestock+',
      trailing: null,
    );
  }

  Widget _banner({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ── Billing toggle ────────────────────────────────────────────────────────

  Widget _buildBillingToggle(Color accent) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.borderColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleBtn(
              label: 'Mensuel',
              selected: !_isYearly,
              accent: accent,
              onTap: () => setState(() => _isYearly = false),
            ),
          ),
          Expanded(
            child: _ToggleBtn(
              label: 'Annuel  −17%',
              selected: _isYearly,
              accent: accent,
              onTap: () => setState(() => _isYearly = true),
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment bottom sheet ──────────────────────────────────────────────────

  void _showPaymentSheet(
      BuildContext context, PlanConfig plan, Color accent) {
    final bloc = context.read<SubscriptionBloc>();
    final refCtrl = TextEditingController();
    final price = _isYearly ? plan.yearlyPrice : plan.monthlyPrice;
    final payLink = _isYearly ? plan.yearlyPayLink : plan.monthlyPayLink;
    final cycle = _isYearly ? BillingCycle.yearly : BillingCycle.monthly;

    bool showManualCodeInput = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.shopping_cart_checkout_rounded, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gestock+ ${_tierLabel(plan.tier)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(
                              '${_fmtPrice(price)} FCFA · ${_isYearly ? 'annuel' : 'mensuel'}',
                              style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info Bannière Détection Automatique
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF3FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryColor, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Validation 100% Automatique',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Dès votre paiement effectué sur FreeMoPay, votre abonnement sera activé automatiquement sans aucune saisie de code !',
                                style: TextStyle(fontSize: 11, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action principale : Ouvrir FreeMoPay et lancer la vérification automatique
                  ElevatedButton.icon(
                    onPressed: () {
                      _openPayLink(payLink);
                      _startAutoChecking();
                    },
                    icon: const Icon(Icons.open_in_browser_rounded, size: 20, color: Colors.white),
                    label: const Text('Payer via FreeMoPay',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Optionnel : Activer manuellement avec référence
                  TextButton.icon(
                    onPressed: () {
                      setSheetState(() {
                        showManualCodeInput = !showManualCodeInput;
                      });
                    },
                    icon: Icon(
                      showManualCodeInput ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    label: Text(
                      showManualCodeInput
                          ? 'Masquer le code manuel'
                          : 'Activer manuellement avec une référence (optionnel)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),

                  if (showManualCodeInput) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: refCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Référence FreeMoPay (ex: FMP-XXXXXXXX)',
                        prefixIcon: Icon(Icons.receipt_long_rounded, color: accent),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: accent, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<SubscriptionBloc, SubscriptionState>(
                      bloc: bloc,
                      builder: (_, s) => s.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : OutlinedButton(
                              onPressed: () {
                                bloc.add(ActivateSubscriptionEvent(
                                  tier: plan.tier,
                                  cycle: cycle,
                                  reference: refCtrl.text,
                                ));
                                Navigator.pop(sheetCtx);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: accent),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Activer manuellement',
                                  style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openPayLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    }
  }

  Widget _buildFaqNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Paiement sécurisé Mobile Money',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Les abonnements sont réglés en FCFA via FreeMoPay (MTN MoMo & Orange Money). Le renouvellement n\'est pas automatique, aucun prélèvement surprise. Dès validation de votre règlement, votre formule s\'active immédiatement.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ── Plan Card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final PlanConfig plan;
  final bool isYearly;
  final Color accent;
  final SubscriptionTier activeTier;
  final SubscriptionInfo? currentInfo;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.isYearly,
    required this.accent,
    required this.activeTier,
    required this.currentInfo,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentPlan = currentInfo != null &&
        currentInfo!.isActive &&
        currentInfo!.tier == plan.tier;

    final isPopular = plan.tier == SubscriptionTier.pro;
    final price = isYearly ? plan.yearlyPrice : plan.monthlyPrice;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? accent : AppTheme.borderColor,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ]
            : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _tierLabel(plan.tier),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const Spacer(),
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Recommandé',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _fmtPrice(price),
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: accent),
                    ),
                    const SizedBox(width: 4),
                    const Text('FCFA',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary)),
                    Text(
                      ' / ${isYearly ? 'an' : 'mois'}',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const Divider(height: 24),

                ...plan.features.map((feat) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: accent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _featureLabel(feat),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan ? null : onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? accent : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isCurrentPlan ? 'Formule actuelle' : 'Choisir cette formule',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
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

class _StepTile extends StatelessWidget {
  final String step;
  final Color accent;
  final String title;
  final String subtitle;
  final Widget action;

  const _StepTile({
    required this.step,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: accent.withValues(alpha: 0.15),
          child: Text(step,
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              action,
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? accent : AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

String _tierLabel(SubscriptionTier tier) => switch (tier) {
      SubscriptionTier.starter => 'Starter',
      SubscriptionTier.pro => 'Pro',
      SubscriptionTier.business => 'Business',
      SubscriptionTier.trial => 'Essai',
    };

String _fmtPrice(int amount) =>
    NumberFormat('#,###', 'fr_FR').format(amount).replaceAll(',', ' ');

String _featureLabel(String feature) => switch (feature) {
      'pos' => 'Caisse enregistreuse (POS)',
      'stock' => 'Gestion de stock & produits',
      'rapports_daily' => 'Rapports de ventes quotidiens',
      'rapports_pdf' => 'Export PDF & Excel des rapports',
      'cloud_sync' => 'Synchronisation Cloud automatique',
      'multi_boutiques' => 'Multi-boutiques & multi-caisses',
      'momo_api' => 'Encaissements Mobile Money direct',
      'support_prioritaire' => 'Support client prioritaire 7j/7',
      'custom_features' => 'Fonctionnalités sur mesure sur demande',
      _ => feature,
    };
