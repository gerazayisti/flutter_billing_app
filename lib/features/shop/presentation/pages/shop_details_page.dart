import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import '../../domain/entities/shop.dart';
import '../bloc/shop_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';

class ShopDetailsPage extends StatefulWidget {
  const ShopDetailsPage({super.key});

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _phoneController;
  late TextEditingController _upiController;
  late TextEditingController _footerController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _address1Controller = TextEditingController();
    _address2Controller = TextEditingController();
    _phoneController = TextEditingController();
    _upiController = TextEditingController();
    _footerController = TextEditingController();

    context.read<ShopBloc>().add(LoadShopEvent());
  }

  void _updateControllers(Shop shop) {
    if (_nameController.text.isEmpty && shop.name.isNotEmpty) {
      _nameController.text = shop.name;
      _address1Controller.text = shop.addressLine1;
      _address2Controller.text = shop.addressLine2;
      _phoneController.text = shop.phoneNumber;
      _upiController.text = shop.upiId;
      _footerController.text = shop.footerText;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _phoneController.dispose();
    _upiController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _saveShop() {
    if (_formKey.currentState!.validate()) {
      final shop = Shop(
        name: _nameController.text,
        addressLine1: _address1Controller.text,
        addressLine2: _address2Controller.text,
        phoneNumber: _phoneController.text,
        upiId: _upiController.text,
        footerText: _footerController.text,
      );

      context.read<ShopBloc>().add(UpdateShopEvent(shop));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(
          title: Text(l10n.shopDetails),
          backgroundColor: Colors.white,
        ),
        body: BlocConsumer<ShopBloc, ShopState>(
          listener: (context, state) {
            if (state is ShopLoaded) {
              _updateControllers(state.shop);
            } else if (state is ShopOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.shopDetailsSaved),
                  backgroundColor: Colors.green));
              context.pop();
            } else if (state is ShopError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red));
            }
          },
          buildWhen: (previous, current) =>
              current is ShopLoading || current is ShopLoaded,
          builder: (context, state) {
            if (state is ShopLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.generalInfo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                        )),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      l10n.shopInfoInstruction,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),
                    InputLabel(text: l10n.shopName),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'e.g. QuickMart Superstore',
                      validator: AppValidators.required(l10n.required),
                    ),
                    const SizedBox(height: 15),
                    InputLabel(text: l10n.addressLine1),
                    _buildTextField(
                      controller: _address1Controller,
                      hint: 'Street, City',
                      validator: AppValidators.required(l10n.required),
                    ),
                    const SizedBox(height: 15),
                    InputLabel(text: l10n.addressLine2),
                    _buildTextField(
                      controller: _address2Controller,
                      hint: 'District, State',
                    ),
                    const SizedBox(height: 15),
                    InputLabel(text: l10n.phoneNumber),
                    _buildTextField(
                      controller: _phoneController,
                      hint: '+237 6XX XXX XXX',
                      keyboardType: TextInputType.phone,
                      validator: AppValidators.required(l10n.required),
                    ),
                    const SizedBox(height: 15),
                    InputLabel(text: l10n.upiId),
                    _buildTextField(
                      controller: _upiController,
                      hint: 'ID Payment',
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InputLabel(text: l10n.receiptFooter),
                        Text('Max 150 chars',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400])),
                      ],
                    ),
                    _buildTextField(
                      controller: _footerController,
                      hint: 'Thank you, Visit again!!!',
                      maxLines: 2,
                      maxLength: 60,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: PrimaryButton(
            onPressed: _saveShop,
            icon: Icons.save,
            label: l10n.saveDetails,
          ),
        ));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.words,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
      ),
    );
  }
}
