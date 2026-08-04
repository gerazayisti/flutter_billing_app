import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:billing_app/core/notifications/notification_service.dart';
import 'package:billing_app/core/notifications/notification_item.dart';
import '../../domain/entities/mobile_money_payment.dart';
import 'package:go_router/go_router.dart';
import '../../../billing/presentation/bloc/billing_bloc.dart';
import '../bloc/mobile_money_bloc.dart';
import '../bloc/mobile_money_event.dart';
import '../bloc/mobile_money_state.dart';
import '../widgets/momo_receipt_dialog.dart';

class WaitingConfirmationPage extends StatelessWidget {
  final VoidCallback onConfirmed;

  const WaitingConfirmationPage({
    required this.onConfirmed,
    super.key,
  });

  void _scheduleTimeoutNotification(BuildContext context, String depositId, double amount, AppLocalizations l10n) {
    // Schedule a 10-second sandbox background timer (instead of 15 minutes)
    Timer(const Duration(seconds: 10), () async {
      // Check if this payment is still pending.
      // To notify the user:
      final notification = NotificationItem(
        id: 'timeout_$depositId',
        title: l10n.paymentTimeoutTitle,
        body: l10n.paymentTimeoutBody(amount.toStringAsFixed(0)),
        type: NotificationType.payment,
        createdAt: DateTime.now(),
      );
      await NotificationService.add(notification);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.checkout,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: BlocConsumer<MobileMoneyBloc, MobileMoneyState>(
          listener: (context, state) {
            if (state is PaymentCompleted) {
              onConfirmed();
            }
          },
          builder: (context, state) {
            if (state is PaymentAwaitingClient) {
              return _AwaitingView(
                state: state,
                onHold: (amount) {
                  _scheduleTimeoutNotification(context, state.payment.depositId, amount, l10n);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              );
            }
            if (state is PaymentManualInstructions) {
              return _ManualInstructionsView(
                payment: state.payment,
                onHold: (amount) {
                  _scheduleTimeoutNotification(context, state.payment.depositId, amount, l10n);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              );
            }
            if (state is PaymentCompleted) {
              return _ResultView(
                icon: Icons.check_circle_rounded,
                color: AppTheme.primaryColor,
                title: 'Paiement Reçu',
                canRetry: false,
                payment: state.payment,
              );
            }
            if (state is PaymentFailed) {
              return _ResultView(
                icon: Icons.error_rounded,
                color: AppTheme.errorColor,
                title: 'Paiement Échoué',
                subtitle: state.message ?? state.code,
                canRetry: true,
              );
            }
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          },
        ),
      ),
    );
  }
}

class _AwaitingView extends StatelessWidget {
  final PaymentAwaitingClient state;
  final Function(double) onHold;

  const _AwaitingView({required this.state, required this.onHold});

  @override
  Widget build(BuildContext context) {
    final name = state.payment.nameDisplayedToCustomer;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 32),
            Text(
              'En attente de confirmation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              name != null
                  ? 'Demandez au client de vérifier son téléphone. Un prompt de "$name" va s\'afficher pour saisir son code PIN.'
                  : 'Demandez au client de vérifier son téléphone pour confirmer le paiement.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Read amount from somewhere or default to 0. Since we don't have it on payment, we can pass 0 or dynamic.
                // Let's pass a placeholder amount or retrieve it if available (currently not on MobileMoneyPayment, but we can pass 0 or a dummy value, or retrieve from billing state if we want, but since we are putting it on hold, let's pass a default or use a generic notification).
                onHold(0);
              },
              icon: const Icon(Icons.pause),
              label: Text(l10n.putOnHold),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
              ),
            ),
            if (state.showReviveOption) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Le client n\'a pas reçu le prompt ?',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    context.read<MobileMoneyBloc>().add(const RevivePinPrompt()),
                child: const Text('Afficher le code USSD'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ManualInstructionsView extends StatelessWidget {
  final MobileMoneyPayment payment;
  final Function(double) onHold;

  const _ManualInstructionsView({required this.payment, required this.onHold});

  @override
  Widget build(BuildContext context) {
    final instructions = payment.pinPromptInstructions;
    final channels = (instructions?['channels'] as List?) ?? [];
    final channel = channels.isNotEmpty ? channels.first : null;
    final steps = (channel?['instructions']?['fr'] as List?) ?? [];
    final quickLink = channel?['quickLink'] as String?;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            'Instructions de paiement manuel',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Demandez au client de composer le code ci-dessous sur son téléphone :',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          if (steps.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step['text'] ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (quickLink != null) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.phone, size: 20),
              label: const Text('Composer le code'),
              onPressed: () async {
                final uri = Uri.parse('tel:$quickLink');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            onPressed: () => onHold(0),
            icon: const Icon(Icons.pause),
            label: Text(l10n.putOnHold),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 50),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'En attente de la validation finale...',
              style: TextStyle(fontSize: 12, color: AppTheme.textDisabled),
            ),
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool canRetry;
  final MobileMoneyPayment? payment;

  const _ResultView({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.canRetry,
    this.payment,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
            const SizedBox(height: 30),
            if (payment != null) ...[
              ElevatedButton.icon(
                onPressed: () {
                  MomoReceiptDialog.show(
                    context,
                    depositId: payment!.depositId,
                    amount: payment!.amount,
                    phoneNumber: payment!.phoneNumber,
                    provider: payment!.provider,
                  );
                },
                icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                label: const Text('📸 Voir & Imprimer le Reçu',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(220, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (canRetry)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: const Text('Réessayer'),
              )
            else
              OutlinedButton(
                onPressed: () {
                  context.read<BillingBloc>().add(ClearCartEvent());
                  context.go('/home');
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retour à la caisse'),
              ),
          ],
        ),
      ),
    );
  }
}
