import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:billing_app/core/utils/xaf_formatter.dart';
import 'package:billing_app/features/billing/domain/entities/payment_method.dart';
import 'package:billing_app/core/service_locator.dart' as di;
import '../bloc/payment_bloc.dart';

class MomoPaymentDialog extends StatefulWidget {
  final PaymentMethod method;
  final double amount;
  final String merchantCode;
  final String cashierId;
  final VoidCallback onConfirmed;

  const MomoPaymentDialog({
    super.key,
    required this.method,
    required this.amount,
    required this.merchantCode,
    required this.cashierId,
    required this.onConfirmed,
  });

  static Future<bool> show(
    BuildContext context, {
    required PaymentMethod method,
    required double amount,
    required String merchantCode,
    required String cashierId,
    required VoidCallback onConfirmed,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => BlocProvider(
            create: (_) => di.sl<PaymentBloc>(),
            child: MomoPaymentDialog(
              method: method,
              amount: amount,
              merchantCode: merchantCode,
              cashierId: cashierId,
              onConfirmed: onConfirmed,
            ),
          ),
        ) ??
        false;
  }

  @override
  State<MomoPaymentDialog> createState() => _MomoPaymentDialogState();
}

class _MomoPaymentDialogState extends State<MomoPaymentDialog> {
  final _phoneController = TextEditingController();
  final _refController = TextEditingController();
  bool _showRefEntry = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _refController.dispose();
    super.dispose();
  }

  Color get _brandColor =>
      widget.method == PaymentMethod.orangeMoney ? Colors.orange : Colors.yellow[800]!;

  String get _brandName =>
      widget.method == PaymentMethod.orangeMoney ? 'Orange Money' : 'MTN MoMo';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentConfirmed) {
          widget.onConfirmed();
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(),
                const SizedBox(height: 20),
                _buildBody(context, state, l10n),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _brandColor.withValues(alpha:0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.phone_android, color: _brandColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_brandName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _brandColor)),
              Text(XafFormatter.format(widget.amount),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 22)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, PaymentState state, AppLocalizations l10n) {
    if (state is PaymentInitial || state is PaymentInitiating) {
      return _phoneEntry(context, state is PaymentInitiating, l10n);
    }
    if (state is PaymentPending) {
      return _pendingView(context, state, l10n);
    }
    if (state is PaymentFailed) {
      return _failedView(context, state, l10n);
    }
    return const SizedBox.shrink();
  }

  // ── Phone entry ──────────────────────────────────────────────────────────

  Widget _phoneEntry(BuildContext context, bool isLoading, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.enterCustomerPhone,
            hintText: l10n.phoneHint,
            prefixText: '+237 ',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  final phone = _phoneController.text.trim();
                  if (phone.isEmpty) return;
                  context.read<PaymentBloc>().add(InitiatePaymentEvent(
                        method: widget.method,
                        customerPhone: phone,
                        amount: widget.amount,
                        merchantCode: widget.merchantCode,
                        cashierId: widget.cashierId,
                      ));
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(l10n.initiatePayment,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel,
              style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  // ── Pending ──────────────────────────────────────────────────────────────

  Widget _pendingView(
      BuildContext context, PaymentPending state, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.ussdInstruction != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _brandColor.withValues(alpha:0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _brandColor.withValues(alpha:0.3)),
            ),
            child: Column(
              children: [
                Text(l10n.dialUssdCode,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: _brandColor)),
                const SizedBox(height: 10),
                Text(
                  state.ussdInstruction!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: _brandColor,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Center(
            child: SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(color: _brandColor, strokeWidth: 3),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Center(
          child: Text(
            state.elapsedSeconds > 0
                ? '${state.elapsedSeconds}s — ${l10n.waitingForPayment}'
                : l10n.waitingForPayment,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),

        // ── Manual reference entry ────────────────────────────────────────
        if (!_showRefEntry) ...[
          OutlinedButton.icon(
            onPressed: () => setState(() => _showRefEntry = true),
            icon: Icon(Icons.edit_note, color: _brandColor),
            label: Text(l10n.enterRefManually,
                style: TextStyle(color: _brandColor)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _brandColor),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ] else ...[
          TextField(
            controller: _refController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.transactionRef,
              hintText: '0000000000',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              final ref = _refController.text.trim();
              if (ref.isEmpty) return;
              context.read<PaymentBloc>().add(
                  ManualConfirmPaymentEvent(state.transaction.id, ref));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.manualConfirmation,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () {
            context.read<PaymentBloc>().add(
                CancelPaymentEvent(state.transaction.id));
            Navigator.of(context).pop(false);
          },
          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
          label: Text(l10n.cancelPayment,
              style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  // ── Failed ───────────────────────────────────────────────────────────────

  Widget _failedView(
      BuildContext context, PaymentFailed state, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
            child: Icon(Icons.error_outline, color: Colors.red, size: 52)),
        const SizedBox(height: 12),
        Center(
          child: Text(l10n.paymentFailed,
              style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(state.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
