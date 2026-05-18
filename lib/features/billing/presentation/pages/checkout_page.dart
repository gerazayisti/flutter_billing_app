import 'package:billing_app/core/utils/receipt_share_service.dart';
import 'package:billing_app/core/utils/xaf_formatter.dart';
import 'package:billing_app/features/billing/domain/entities/payment_method.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:billing_app/features/payment/presentation/widgets/momo_payment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/l10n/app_localizations.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/billing_bloc.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _cashController = TextEditingController();
  double _cashReceived = 0;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const borderColor = Color(0xFFE5E5EA);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        context.read<BillingBloc>().add(ClearCartEvent());
        context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.checkout,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left, size: 28, color: Theme.of(context).primaryColor),
            onPressed: () {
              context.read<BillingBloc>().add(ClearCartEvent());
              context.go('/home');
            },
          ),
        ),
        body: BlocConsumer<BillingBloc, BillingState>(
          listener: (context, state) {
            if (state.printSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.successOrder,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.green));
            }
          },
          builder: (context, billingState) {
            return BlocBuilder<ShopBloc, ShopState>(
              builder: (context, shopState) {
                final shop = shopState is ShopLoaded ? shopState.shop : null;
                final total = billingState.totalAmount;

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          children: [
                            // ── Items table ──────────────────────────────────
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4))
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Table(
                                  border: const TableBorder(
                                    horizontalInside: BorderSide(color: borderColor),
                                    bottom: BorderSide(color: borderColor),
                                  ),
                                  children: [
                                    TableRow(
                                      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                                      children: [
                                        _headerCell(l10n.productName, TextAlign.left),
                                        _headerCell(l10n.price, TextAlign.right),
                                        _headerCell(l10n.total, TextAlign.right),
                                      ],
                                    ),
                                    ...billingState.cartItems.map((item) => TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${item.quantity} × ${item.product.name}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w500, fontSize: 14),
                                              ),
                                              if (item.product.variants.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                DropdownButtonHideUnderline(
                                                  child: DropdownButton<String>(
                                                    isDense: true,
                                                    value: item.selectedVariant,
                                                    hint: Text(l10n.selectVariant,
                                                        style: const TextStyle(fontSize: 12)),
                                                    style: const TextStyle(
                                                        fontSize: 12, color: Colors.blue),
                                                    items: item.product.variants
                                                        .map((v) => DropdownMenuItem(
                                                            value: v, child: Text(v)))
                                                        .toList(),
                                                    onChanged: (value) {
                                                      if (value != null) {
                                                        context.read<BillingBloc>().add(
                                                            SelectVariantEvent(
                                                                item.product.id, value));
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        _dataCell(XafFormatter.format(item.product.price),
                                            TextAlign.right, isSubtitle: true),
                                        _dataCell(XafFormatter.format(item.total),
                                            TextAlign.right, isBold: true),
                                      ],
                                    )),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 140),
                          ],
                        ),
                      ),
                    ),

                    // ── Bottom bar ────────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.97),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, -4))
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── Payment method chips ──────────────────────
                                _paymentMethodSelector(context, billingState, l10n),
                                const SizedBox(height: 12),

                                // ── Cash change section ───────────────────────
                                if (billingState.paymentMethod == PaymentMethod.cash)
                                  _cashChangeSection(context, total, l10n),

                                // ── Mobile Money section ──────────────────────
                                if (billingState.paymentMethod.isMobileMoney && shop != null)
                                  _momoSection(context, billingState.paymentMethod, shop, l10n),

                                const SizedBox(height: 8),

                                // ── Grand total ───────────────────────────────
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(l10n.grandTotal,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[400],
                                            letterSpacing: 1.2)),
                                    Text(
                                      XafFormatter.format(total),
                                      style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                          color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),

                          // ── Share buttons ─────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: shop != null
                                        ? () => ReceiptShareService.shareAsText(
                                              shopName: shop.name,
                                              address: '${shop.addressLine1} ${shop.addressLine2}'.trim(),
                                              phone: shop.phoneNumber,
                                              items: billingState.cartItems,
                                              total: total,
                                              footer: shop.footerText,
                                              l10n: l10n,
                                            )
                                        : null,
                                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                    label: const Text('WhatsApp / SMS'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Theme.of(context).primaryColor,
                                      side: BorderSide(color: Theme.of(context).primaryColor),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: shop != null
                                        ? () => ReceiptShareService.shareAsPdf(
                                              shopName: shop.name,
                                              address: '${shop.addressLine1} ${shop.addressLine2}'.trim(),
                                              phone: shop.phoneNumber,
                                              items: billingState.cartItems,
                                              total: total,
                                              footer: shop.footerText,
                                              context: context,
                                              l10n: l10n,
                                            )
                                        : null,
                                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                                    label: const Text('PDF'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(color: Colors.redAccent),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Action buttons ────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _handleAction(
                                      context: context,
                                      billingState: billingState,
                                      shop: shop,
                                      l10n: l10n,
                                      action: () => context
                                          .read<BillingBloc>()
                                          .add(const SaveOrderWithoutPrintEvent()),
                                    ),
                                    icon: const Icon(Icons.save, size: 20),
                                    label: Text(l10n.saveOnly),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: PrimaryButton(
                                    onPressed: shop != null
                                        ? () => _handleAction(
                                              context: context,
                                              billingState: billingState,
                                              shop: shop,
                                              l10n: l10n,
                                              action: () =>
                                                  context.read<BillingBloc>().add(
                                                        PrintReceiptEvent(
                                                          shopName: shop.name,
                                                          address1: shop.addressLine1,
                                                          address2: shop.addressLine2,
                                                          phone: shop.phoneNumber,
                                                          footer: shop.footerText,
                                                          l10n: l10n,
                                                        ),
                                                      ),
                                            )
                                        : () {},
                                    label: l10n.printReceipt,
                                    icon: Icons.print,
                                    isLoading: billingState.isPrinting,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Intercepts save/print: if MoMo method, shows payment dialog first.
  void _handleAction({
    required BuildContext context,
    required BillingState billingState,
    required dynamic shop,
    required AppLocalizations l10n,
    required VoidCallback action,
  }) {
    if (!billingState.paymentMethod.isMobileMoney) {
      action();
      return;
    }

    final isOrange = billingState.paymentMethod == PaymentMethod.orangeMoney;
    final code = shop != null
        ? (isOrange ? shop.orangeMoneyMerchant : shop.mtnMomoMerchant) as String
        : '';

    final authState = context.read<AuthBloc>().state;
    final cashierId = authState is AuthAuthenticated ? authState.user.id : 'unknown';

    MomoPaymentDialog.show(
      context,
      method: billingState.paymentMethod,
      amount: billingState.totalAmount,
      merchantCode: code,
      cashierId: cashierId,
      onConfirmed: action,
    );
  }

  Widget _paymentMethodSelector(
      BuildContext context, BillingState state, AppLocalizations l10n) {
    final methods = [
      (PaymentMethod.cash, Icons.money_rounded, Colors.green, l10n.cash),
      (PaymentMethod.orangeMoney, Icons.phone_android, Colors.orange, l10n.orangeMoney),
      (PaymentMethod.mtnMomo, Icons.phone_android, Colors.yellow[800]!, l10n.mtnMomo),
      (PaymentMethod.card, Icons.credit_card, Colors.blue, l10n.card),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: methods.map((m) {
        final selected = state.paymentMethod == m.$1;
        return ChoiceChip(
          avatar: Icon(m.$2, size: 16, color: selected ? Colors.white : m.$3),
          label: Text(m.$4,
              style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13)),
          selected: selected,
          selectedColor: m.$3,
          backgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onSelected: (_) => context
              .read<BillingBloc>()
              .add(SetPaymentMethodEvent(m.$1)),
        );
      }).toList(),
    );
  }

  Widget _cashChangeSection(
      BuildContext context, double total, AppLocalizations l10n) {
    final change = _cashReceived - total;
    final isInsufficient = _cashReceived > 0 && change < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.cashReceived,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: '0',
                    suffixText: 'FCFA',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(
                      () => _cashReceived = double.tryParse(v.replaceAll(' ', '')) ?? 0),
                ),
              ),
            ],
          ),
          if (_cashReceived > 0) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.changeGiven,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  isInsufficient
                      ? '− ${XafFormatter.format(change.abs())}'
                      : XafFormatter.format(change),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isInsufficient ? Colors.red : Colors.green[700],
                  ),
                ),
              ],
            ),
            if (isInsufficient)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(l10n.insufficientCash,
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _momoSection(BuildContext context, PaymentMethod method,
      dynamic shop, AppLocalizations l10n) {
    final isOrange = method == PaymentMethod.orangeMoney;
    final code = isOrange ? shop.orangeMoneyMerchant : shop.mtnMomoMerchant;
    final color = isOrange ? Colors.orange : Colors.yellow[800]!;
    final label = isOrange ? l10n.orangeMoney : l10n.mtnMomo;

    if (code.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[400], size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Code marchand $label non configuré. Allez dans Paramètres → Boutique.',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${l10n.momoMerchantCode} : ',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Flexible(
                child: Text(
                  code,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.info_outline, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Flexible(
                child: Text(l10n.momoPayInstruction,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, TextAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey),
      ),
    );
  }

  Widget _dataCell(String text, TextAlign align,
      {bool isBold = false, bool isSubtitle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isSubtitle ? 12 : 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: isSubtitle ? Colors.grey[500] : Colors.black87,
        ),
      ),
    );
  }
}
