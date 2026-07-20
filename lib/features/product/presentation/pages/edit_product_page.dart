import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/l10n/app_localizations.dart';

import 'package:barcode_widget/barcode_widget.dart';
import '../../../../core/utils/barcode_print_service.dart';
import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late double _price;
  late int _stock;
  late String _category;
  late int _minStockAlert;
  late List<String> _variants;
  late String _barcode;
  final TextEditingController _variantController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name = widget.product.name;
    _price = widget.product.price;
    _stock = widget.product.stock;
    _category = widget.product.category;
    _minStockAlert = widget.product.minStockAlert;
    _variants = List.from(widget.product.variants);
    _barcode = widget.product.barcode;
  }

  void _scanBarcode() async {
    final result = await context.push<String>('/scanner');
    if (result != null && result.isNotEmpty) {
      setState(() {
        _barcode = result;
      });
    }
  }

  void _generateBarcode() {
    final productState = context.read<ProductBloc>().state;
    String newBarcode = '';
    bool exists = true;

    while (exists) {
      final stamp = DateTime.now().millisecondsSinceEpoch.toString();
      newBarcode = '20${stamp.substring(stamp.length - 10)}';
      exists = productState.products.any((p) => p.barcode == newBarcode && p.id != widget.product.id);
    }

    setState(() {
      _barcode = newBarcode;
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updatedProduct = Product(
        id: widget.product.id,
        name: _name,
        barcode: _barcode,
        price: _price,
        stock: _stock,
        category: _category,
        minStockAlert: _minStockAlert,
        variants: _variants,
      );

      context.read<ProductBloc>().add(UpdateProduct(updatedProduct));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 32, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.editProduct,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InputLabel(text: l10n.barcode),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(_barcode),
                          initialValue: _barcode,
                          decoration: InputDecoration(
                            hintText: l10n.scanOrEnterBarcode,
                          ),
                          validator: (v) => AppValidators.required(l10n.enterBarcode)(v),
                          onSaved: (value) => _barcode = value!,
                          onChanged: (val) {
                            setState(() {
                              _barcode = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner,
                            color: AppTheme.primaryColor, size: 28),
                        onPressed: _scanBarcode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_barcode.isEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _generateBarcode,
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Générer un code-barres unique'),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        children: [
                          BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: _barcode,
                            width: double.infinity,
                            height: 60,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _barcode = '';
                                  });
                                },
                                icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                                label: const Text('Effacer', style: TextStyle(color: AppTheme.errorColor)),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_barcode.isNotEmpty) {
                                    BarcodePrintService.printBarcodeLabel(
                                      productName: _name.isNotEmpty ? _name : 'Produit',
                                      productPrice: _price,
                                      barcodeData: _barcode,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.print_rounded),
                                label: const Text('Imprimer l\'étiquette'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  InputLabel(text: l10n.productName),

                  TextFormField(
                    initialValue: _name,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => AppValidators.required(l10n.enterName)(v),
                    onSaved: (value) => _name = value!,
                    onChanged: (value) => _name = value,
                  ),
                  const SizedBox(height: 24),

                  InputLabel(text: l10n.price),

                  TextFormField(
                    initialValue: _price.toStringAsFixed(2),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixText: 'XAF ',
                      prefixStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    ),
                    validator: (v) => AppValidators.price(v, l10n),
                    onSaved: (value) => _price = double.tryParse(value ?? '0') ?? 0.0,
                    onChanged: (value) => _price = double.tryParse(value) ?? 0.0,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InputLabel(text: l10n.stockQuantity),
                            TextFormField(
                              initialValue: _stock.toString(),
                              keyboardType: TextInputType.number,
                              onSaved: (value) =>
                                  _stock = int.tryParse(value!) ?? 0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InputLabel(text: l10n.alertThreshold),
                            TextFormField(
                              initialValue: _minStockAlert.toString(),
                              keyboardType: TextInputType.number,
                              onSaved: (value) =>
                                  _minStockAlert = int.tryParse(value!) ?? 5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  InputLabel(text: l10n.category),
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: ['General', 'Food', 'Drinks', 'Electronics', 'Others']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) => setState(() => _category = value!),
                  ),
                  const SizedBox(height: 24),
                  InputLabel(text: l10n.variants),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _variantController,
                          decoration: InputDecoration(
                            hintText: l10n.addVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: () {
                          if (_variantController.text.isNotEmpty) {
                            setState(() {
                              _variants.add(_variantController.text.trim());
                              _variantController.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _variants
                        .map((v) => Chip(
                              label: Text(v),
                              onDeleted: () =>
                                  setState(() => _variants.remove(v)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: PrimaryButton(
            onPressed: _submit,
            icon: Icons.save,
            label: l10n.saveChanges,
          ),
        ));
  }
}
