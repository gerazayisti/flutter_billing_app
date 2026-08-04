import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/utils/xaf_formatter.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:billing_app/core/data/hive_database.dart';
import '../bloc/mobile_money_bloc.dart';
import '../bloc/mobile_money_event.dart';
import '../bloc/mobile_money_state.dart';
import 'waiting_confirmation_page.dart';

class EnterPhoneNumberPage extends StatefulWidget {
  final String saleId;
  final double amount;
  final VoidCallback onConfirmed;

  const EnterPhoneNumberPage({
    required this.saleId,
    required this.amount,
    required this.onConfirmed,
    super.key,
  });

  @override
  State<EnterPhoneNumberPage> createState() => _EnterPhoneNumberPageState();
}

class _EnterPhoneNumberPageState extends State<EnterPhoneNumberPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final shopBox = HiveDatabase.shopBox;
    final shop = shopBox.values.isNotEmpty ? shopBox.values.first : null;
    String prefix = '237';
    if (shop != null && shop.phoneNumber.isNotEmpty) {
      final p = shop.phoneNumber.replaceAll('+', '').replaceAll(' ', '').trim();
      if (p.startsWith('237')) {
        prefix = '237';
      } else if (p.length >= 3) {
        prefix = p.substring(0, 3);
      }
    }
    _controller.text = prefix;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(l10n.mobileMoney,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: BlocConsumer<MobileMoneyBloc, MobileMoneyState>(
        listener: (context, state) {
          if (state is PaymentAwaitingClient ||
              state is PaymentManualInstructions ||
              state is PaymentCompleted ||
              state is PaymentFailed) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<MobileMoneyBloc>(),
                  child: WaitingConfirmationPage(onConfirmed: widget.onConfirmed),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Notification / Bannière d'information FreeMoPay ─────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppTheme.primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Paiement via FreeMoPay',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Sécurisé',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Le paiement Mobile Money (MTN MoMo & Orange Money) est géré instantanément via la passerelle officielle FreeMoPay. Une notification USSD sera envoyée sur le téléphone du client pour valider le code PIN.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Montant à encaisser',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          XafFormatter.format(widget.amount),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  l10n.enterCustomerPhone,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone (ex: 690000000)',
                    hintText: l10n.phoneHint,
                    prefixIcon: const Icon(Icons.phone_android_rounded, color: AppTheme.primaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: state is PaymentInitiating
                      ? null
                      : () {
                          final phone = _controller.text.trim();
                          if (phone.isEmpty) return;
                          context.read<MobileMoneyBloc>().add(InitiatePayment(
                                saleId: widget.saleId,
                                amount: widget.amount,
                                phoneNumberRaw: phone,
                              ));
                        },
                  icon: state is PaymentInitiating
                      ? const SizedBox.shrink()
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  label: state is PaymentInitiating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.initiatePayment,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 16),

                // Badges opérateurs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Compatible MTN Mobile Money & Orange Money Cameroun',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
