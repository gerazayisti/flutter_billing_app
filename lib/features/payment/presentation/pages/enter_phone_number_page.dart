import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/utils/xaf_formatter.dart';
import 'package:billing_app/l10n/app_localizations.dart';
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mobileMoney,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      XafFormatter.format(widget.amount),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.enterCustomerPhone,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.enterCustomerPhone,
                    hintText: l10n.phoneHint,
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: state is PaymentInitiating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.initiatePayment),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
