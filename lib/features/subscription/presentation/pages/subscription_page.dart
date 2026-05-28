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

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _isYearly = false;

  @override
  void initState() {
    super.initState();
    context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent());
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColorConfig.accentColor;

    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state.activated) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Abonnement activé avec succès !',
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
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Current status banner ─────────────────────────────────
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
      final expiry =
          DateFormat('dd/MM/yyyy').format(state.info!.expiryDate);
      return _banner(
        icon: Icons.verified_rounded,
        color: accent,
        title: 'Gestock+ ${_tierLabel(state.info!.tier)}',
        subtitle: 'Actif jusqu\'au $expiry · ${state.info!.daysRemaining} jours',
        trailing: TextButton(
          onPressed: () {},
          child: Text('Renouveler',
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.bold)),
        ),
      );
    }

    final days = state.trialDaysRemaining;
    if (days > 0) {
      return _banner(
        icon: Icons.timer_rounded,
        color: AppTheme.primaryColor,
        title: 'Essai Pro gratuit',
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54)),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Container(
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
                    child: Icon(Icons.shopping_cart_checkout_rounded,
                        color: accent),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gestock+ ${_tierLabel(plan.tier)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
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
              const SizedBox(height: 24),

              // Step 1: open pay-link
              _StepTile(
                step: '1',
                accent: accent,
                title: 'Effectuer le paiement',
                subtitle: 'Ouvrir le lien dans votre navigateur et payer par Mobile Money',
                action: ElevatedButton.icon(
                  onPressed: () => _openPayLink(payLink),
                  icon: const Icon(Icons.open_in_browser_rounded,
                      size: 18),
                  label: const Text('Ouvrir lien de paiement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Step 2: enter reference
              _StepTile(
                step: '2',
                accent: accent,
                title: 'Entrer la référence',
                subtitle: 'Saisissez la référence reçue par SMS après le paiement',
                action: TextField(
                  controller: refCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Ex: FMP-XXXXXXXX',
                    prefixIcon: Icon(Icons.receipt_long_rounded,
                        color: accent),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accent, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Activate button
              BlocBuilder<SubscriptionBloc, SubscriptionState>(
                bloc: bloc,
                builder: (_, s) => s.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () {
                          bloc.add(ActivateSubscriptionEvent(
                            tier: plan.tier,
                            cycle: cycle,
                            reference: refCtrl.text,
                          ));
                          Navigator.pop(sheetCtx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Activer l\'abonnement',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPayLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildFaqNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('À savoir',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          SizedBox(height: 8),
          _FaqItem(
              '1 mois gratuit offert à la création du compte pour tous les plans.'),
          _FaqItem(
              'Paiement via Orange Money ou MTN MoMo (Cameroun).'),
          _FaqItem(
              'Plan Business : fonctionnalités ajustables sur demande.'),
          _FaqItem(
              'Support : gestockplus@gmail.com'),
        ],
      ),
    );
  }

  String _tierLabel(SubscriptionTier tier) => switch (tier) {
        SubscriptionTier.trial => 'Essai',
        SubscriptionTier.starter => 'Starter',
        SubscriptionTier.pro => 'Pro',
        SubscriptionTier.business => 'Business',
      };

  String _fmtPrice(int price) =>
      NumberFormat('#,###', 'fr_FR').format(price).replaceAll(',', ' ');
}

// ── Widgets ───────────────────────────────────────────────────────────────────

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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6)
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? accent : Colors.black54,
          ),
        ),
      ),
    );
  }
}

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

  bool get isCurrent =>
      currentInfo != null &&
      currentInfo!.isActive &&
      currentInfo!.tier == plan.tier;

  bool get isPopular => plan.tier == SubscriptionTier.pro;

  @override
  Widget build(BuildContext context) {
    final price = isYearly ? plan.yearlyPrice : plan.monthlyPrice;
    final currency = NumberFormat('#,###', 'fr_FR');
    final formatted = currency.format(price).replaceAll(',', ' ');
    final borderColor = isCurrent ? accent : AppTheme.borderColor;

    return Container(
      decoration: BoxDecoration(
        color: isCurrent
            ? accent.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: borderColor, width: isCurrent ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _tierLabel(plan.tier),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: isCurrent ? accent : Colors.black87,
                          ),
                        ),
                        if (isPopular) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Populaire',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Actif',
                                style: TextStyle(
                                    color: accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$formatted ',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              color: isCurrent ? accent : Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text:
                                'FCFA/${isYearly ? 'an' : 'mois'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _planIcon(plan.tier, accent),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Limits summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              children: [
                _chip(
                    plan.maxBoutiques == -1
                        ? '∞ boutiques'
                        : '${plan.maxBoutiques} boutique${plan.maxBoutiques > 1 ? 's' : ''}',
                    accent),
                _chip(
                    plan.maxProducts == -1
                        ? '∞ produits'
                        : '${plan.maxProducts} produits',
                    accent),
                _chip(
                    plan.maxEmployees == -1
                        ? '∞ employés'
                        : '${plan.maxEmployees} employé${plan.maxEmployees > 1 ? 's' : ''}',
                    accent),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),

          // Features list
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              children: _featureRows(plan, accent),
            ),
          ),
          const Divider(height: 1),

          // CTA
          Padding(
            padding: const EdgeInsets.all(20),
            child: isCurrent
                ? OutlinedButton(
                    onPressed: onSubscribe,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: accent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Renouveler',
                        style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold)),
                  )
                : ElevatedButton(
                    onPressed: onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Choisir ${_tierLabel(plan.tier)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _featureRows(PlanConfig plan, Color accent) {
    const all = [
      ('pos', 'Caisse & Ventes'),
      ('stock', 'Gestion du stock'),
      ('rapports_daily', 'Rapports journaliers'),
      ('rapports_pdf', 'Exports PDF'),
      ('cloud_sync', 'Synchronisation cloud'),
      ('multi_boutiques', 'Multi-boutiques'),
      ('momo_api', 'API Mobile Money'),
      ('support_prioritaire', 'Support prioritaire'),
      ('custom_features', 'Fonctionnalités sur mesure'),
    ];

    return all
        .map((entry) {
          final has = plan.hasFeature(entry.$1);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  has
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 16,
                  color: has ? accent : Colors.black26,
                ),
                const SizedBox(width: 8),
                Text(
                  entry.$2,
                  style: TextStyle(
                    fontSize: 13,
                    color: has ? Colors.black87 : Colors.black38,
                    fontWeight:
                        has ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        })
        .toList();
  }

  Widget _chip(String label, Color accent) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: accent,
                fontWeight: FontWeight.w600)),
      );

  Widget _planIcon(SubscriptionTier tier, Color accent) {
    final icon = switch (tier) {
      SubscriptionTier.starter => Icons.storefront_rounded,
      SubscriptionTier.pro => Icons.rocket_launch_rounded,
      SubscriptionTier.business => Icons.business_center_rounded,
      SubscriptionTier.trial => Icons.hourglass_top_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: accent, size: 28),
    );
  }

  String _tierLabel(SubscriptionTier tier) => switch (tier) {
        SubscriptionTier.trial => 'Essai',
        SubscriptionTier.starter => 'Starter',
        SubscriptionTier.pro => 'Pro',
        SubscriptionTier.business => 'Business',
      };
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
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(step,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 10),
              action,
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String text;
  const _FaqItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.black54)),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54))),
        ],
      ),
    );
  }
}
