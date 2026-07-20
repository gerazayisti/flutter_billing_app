import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/core/theme/app_theme.dart';

/// Écran de blocage affiché quand l'abonnement du propriétaire est expiré.
/// Empêche toute vente ou enregistrement de paiement.
class SubscriptionExpiredOverlay extends StatelessWidget {
  const SubscriptionExpiredOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Icône ────────────────────────────────────────────────────
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4), width: 2),
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Titre ─────────────────────────────────────────────────────
                const Text(
                  'Abonnement expiré',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Description ───────────────────────────────────────────────
                Text(
                  'Votre abonnement Gestock+ a expiré.\n'
                  'Les ventes et paiements sont bloqués jusqu\'au renouvellement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.65),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // ── CTA Renouveler ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/subscription'),
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text(
                      'Renouveler mon abonnement',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Lien retour ────────────────────────────────────────────────
                TextButton(
                  onPressed: () => context.go('/owner-dashboard'),
                  child: Text(
                    'Retour au tableau de bord',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
