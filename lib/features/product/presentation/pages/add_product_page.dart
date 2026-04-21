import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:billing_app/l10n/app_localizations.dart';

import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _barcode = '';
  double _price = 0.0;
  int _stock = 0;
  String _category = 'General';
  int _minStockAlert = 5;
  final List<String> _variants = [];
  final TextEditingController _variantController = TextEditingController();

  void _scanBarcode() async {
    final result = await context.push<String>('/scanner');
    if (result != null && result.isNotEmpty) {
      setState(() {
        _barcode = result;
      });
    }
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final productState = context.read<ProductBloc>().state;
      final existingProduct =
          productState.products.where((p) => p.barcode == _barcode).firstOrNull;

      if (existingProduct != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.barcodeExists} "$_barcode"'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final product = Product(
        id: const Uuid().v4(),
        name: _name,
        barcode: _barcode,
        price: _price,
        stock: _stock,
        category: _category,
        minStockAlert: _minStockAlert,
        variants: _variants,
      );

      context.read<ProductBloc>().add(AddProduct(product));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.addProduct,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_scanner,
                              color: AppTheme.primaryColor),
                          onPressed: _scanBarcode,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.tapToOpenScanner,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF4C669A))),
                  const SizedBox(height: 24),
                  InputLabel(text: l10n.productName),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'e.g. Basmati Rice',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => AppValidators.required(l10n.enterName)(v),
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 24),
                  InputLabel(text: l10n.price),
                  TextFormField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixText: 'XAF ',
                      prefixStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    ),
                    validator: (v) => AppValidators.price(v, l10n),
                    onSaved: (value) => _price = double.parse(value!),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InputLabel(text: l10n.initialStock),
                            TextFormField(
                              initialValue: '0',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '0'),
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
                              initialValue: '5',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '5'),
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
                    decoration: const InputDecoration(),
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
            icon: Icons.add_circle,
            label: l10n.addProduct,
          ),
        ));
  }
}
