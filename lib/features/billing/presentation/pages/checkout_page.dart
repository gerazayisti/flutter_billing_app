import 'package:billing_app/core/utils/receipt_share_service.dart';
import 'package:billing_app/features/billing/domain/entities/payment_method.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:billing_app/l10n/app_localizations.dart';

import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/billing_bloc.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
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
              icon: Icon(Icons.chevron_left,
                  size: 28, color: Theme.of(context).primaryColor),
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
                    content: Text(l10n.successOrder, style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.green));
              }
            },
            builder: (context, billingState) {
              return BlocBuilder<ShopBloc, ShopState>(
                  builder: (context, shopState) {
                String upiId = '';
                String shopName = 'Shop';

                if (shopState is ShopLoaded) {
                  upiId = shopState.shop.upiId;
                  shopName = shopState.shop.name;
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Column(
                          children: [
                            // Table
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Table(
                                  border: const TableBorder(
                                    horizontalInside:
                                        BorderSide(color: borderColor),
                                    bottom: BorderSide(color: borderColor),
                                  ),
                                  children: [
                                    // Header row
                                    TableRow(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF8FAFC),
                                        border: Border(
                                            bottom:
                                                BorderSide(color: borderColor)),
                                      ),
                                      children: [
                                        _buildHeaderCell(
                                            l10n.productName, TextAlign.left),
                                        _buildHeaderCell(
                                            l10n.price, TextAlign.right),
                                        _buildHeaderCell(
                                            l10n.total, TextAlign.right),
                                      ],
                                    ),
                                    // Items rows
                                    ...billingState.cartItems.map((item) {
                                      return TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${item.quantity} x ${item.product.name}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 14),
                                                ),
                                                if (item.product.variants
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  DropdownButtonHideUnderline(
                                                    child: DropdownButton<String>(
                                                      isDense: true,
                                                      value:
                                                          item.selectedVariant,
                                                      hint: Text(
                                                        l10n.selectVariant,
                                                        style: const TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.blue),
                                                      items: item
                                                          .product.variants
                                                          .map((v) =>
                                                              DropdownMenuItem(
                                                                value: v,
                                                                child: Text(v),
                                                              ))
                                                          .toList(),
                                                      onChanged: (value) {
                                                        context
                                                            .read<BillingBloc>()
                                                            .add(
                                                              SelectVariantEvent(
                                                                  item.product
                                                                      .id,
                                                                  value!),
                                                            );
                                                      },
                                                    ),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          ),
                                          _buildDataCell(
                                              'XAF${item.product.price.toStringAsFixed(2)}',
                                              TextAlign.right,
                                              isSubtitle: true),
                                          _buildDataCell(
                                              'XAF${item.total.toStringAsFixed(2)}',
                                              TextAlign.right,
                                              isBold: true),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            const SizedBox(
                                height: 120), // padding for bottom fixed bar
                          ],
                        ),
                      ),
                    ),

                    // Bottom Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(24),
                            right: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 8,
                                ),
                                upiId.isNotEmpty
                                    ? Column(
                                        children: [
                                          Text(
                                            l10n.scanToPay,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: 180,
                                            height: 180,
                                            child: PrettyQrView.data(
                                              data:
                                                  'upi://pay?pa=$upiId&pn=$shopName&am=${billingState.totalAmount.toStringAsFixed(2)}&cu=INR',
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                                const SizedBox(height: 15),
                                
                                // Payment Method Selector
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 15),
                                  child: SegmentedButton<PaymentMethod>(
                                    segments: [
                                      ButtonSegment(
                                        value: PaymentMethod.cash,
                                        icon: const Icon(Icons.money, size: 18),
                                        label: Text(l10n.cash),
                                      ),
                                      ButtonSegment(
                                        value: PaymentMethod.card,
                                        icon: const Icon(Icons.credit_card, size: 18),
                                        label: Text(l10n.card),
                                      ),
                                      ButtonSegment(
                                        value: PaymentMethod.mobileMoney,
                                        icon: const Icon(Icons.phone_android, size: 18),
                                        label: Text(l10n.mobileMoney),
                                      ),
                                    ],
                                    selected: {billingState.paymentMethod},
                                    onSelectionChanged: (Set<PaymentMethod> newSelection) {
                                      context.read<BillingBloc>().add(
                                        SetPaymentMethodEvent(newSelection.first)
                                      );
                                    },
                                    style: const ButtonStyle(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      l10n.grandTotal,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[400],
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      'XAF${billingState.totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // ── Share Row ─────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      if (shopState is ShopLoaded) {
                                        ReceiptShareService.shareAsText(
                                          shopName: shopState.shop.name,
                                          address:
                                              '${shopState.shop.addressLine1} ${shopState.shop.addressLine2}'
                                                  .trim(),
                                          phone: shopState.shop.phoneNumber,
                                          items: billingState.cartItems,
                                          total: billingState.totalAmount,
                                          footer: shopState.shop.footerText,
                                          l10n: l10n,
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.chat_bubble_outline,
                                        size: 18),
                                    label: const Text('WhatsApp / SMS'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          Theme.of(context).primaryColor,
                                      side: BorderSide(
                                          color: Theme.of(context).primaryColor),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      if (shopState is ShopLoaded) {
                                        ReceiptShareService.shareAsPdf(
                                          shopName: shopState.shop.name,
                                          address:
                                              '${shopState.shop.addressLine1} ${shopState.shop.addressLine2}'
                                                  .trim(),
                                          phone: shopState.shop.phoneNumber,
                                          items: billingState.cartItems,
                                          total: billingState.totalAmount,
                                          footer: shopState.shop.footerText,
                                          context: context,
                                          l10n: l10n,
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                        Icons.picture_as_pdf_outlined,
                                        size: 18),
                                    label: const Text('PDF'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(
                                          color: Colors.redAccent),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Action Buttons ────────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    context.read<BillingBloc>().add(const SaveOrderWithoutPrintEvent());
                                  },
                                  icon: const Icon(Icons.save, size: 20),
                                  label: Text(l10n.saveOnly),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: PrimaryButton(
                                  onPressed: () {
                                    if (shopState is ShopLoaded) {
                                      context.read<BillingBloc>().add(
                                          PrintReceiptEvent(
                                              shopName: shopState.shop.name,
                                              address1: shopState.shop.addressLine1,
                                              address2: shopState.shop.addressLine2,
                                              phone: shopState.shop.phoneNumber,
                                              footer: shopState.shop.footerText,
                                              l10n: l10n,
                                          ));
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('Shop details not loaded'),
                                              backgroundColor: Colors.red));
                                    }
                                  },
                                  label: l10n.printReceipt,
                                  icon: Icons.print,
                                  isLoading: billingState.isPrinting,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              });
            },
          ),
        ));
  }

  Widget _buildHeaderCell(String text, TextAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, TextAlign align,
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
