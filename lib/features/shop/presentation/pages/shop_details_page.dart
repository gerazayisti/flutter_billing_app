import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
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

  late final TextEditingController _nameController;
  late final TextEditingController _address1Controller;
  late final TextEditingController _address2Controller;
  late final TextEditingController _phoneController;
  late final TextEditingController _footerController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _orangeController;
  late final TextEditingController _mtnController;
  late final TextEditingController _taxIdController;

  String? _selectedShopType;

  static const List<String> _commonCities = [
    'Douala', 'Yaoundé', 'Bafoussam', 'Buea', 'Bamenda',
    'Abidjan', 'Paris', 'Dakar', 'Libreville', 'Kinshasa',
    'Montréal', 'Bruxelles', 'Lomé', 'Cotonou', 'N\'Djamena',
    'Bangui', 'Brazzaville', 'New York', 'Autre / International',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _address1Controller = TextEditingController();
    _address2Controller = TextEditingController();
    _phoneController = TextEditingController();
    _footerController = TextEditingController();
    _cityController = TextEditingController();
    _districtController = TextEditingController();
    _orangeController = TextEditingController();
    _mtnController = TextEditingController();
    _taxIdController = TextEditingController();
    context.read<ShopBloc>().add(LoadShopEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _phoneController.dispose();
    _footerController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _orangeController.dispose();
    _mtnController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  void _updateControllers(Shop shop) {
    if (_nameController.text.isEmpty && shop.name.isNotEmpty) {
      _nameController.text = shop.name;
      _address1Controller.text = shop.addressLine1;
      _address2Controller.text = shop.addressLine2;
      _phoneController.text = shop.phoneNumber;
      _footerController.text = shop.footerText;
      _cityController.text = shop.city;
      _districtController.text = shop.district;
      _orangeController.text = shop.orangeMoneyMerchant;
      _mtnController.text = shop.mtnMomoMerchant;
      _taxIdController.text = shop.taxId;
      setState(() {
        _selectedShopType = shop.shopType.isEmpty ? null : shop.shopType;
      });
    }
  }

  void _saveShop() {
    if (_formKey.currentState!.validate()) {
      final shop = Shop(
        name: _nameController.text.trim(),
        addressLine1: _address1Controller.text.trim(),
        addressLine2: _address2Controller.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        footerText: _footerController.text.trim(),
        city: _cityController.text.trim(),
        district: _districtController.text.trim(),
        shopType: _selectedShopType ?? '',
        orangeMoneyMerchant: _orangeController.text.trim(),
        mtnMomoMerchant: _mtnController.text.trim(),
        taxId: _taxIdController.text.trim(),
      );
      context.read<ShopBloc>().add(UpdateShopEvent(shop));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shopTypes = [
      ('epicerie', l10n.shopTypeEpicerie),
      ('supermarche', l10n.shopTypeSupermarche),
      ('pharmacie', l10n.shopTypePharmacie),
      ('boulangerie', l10n.shopTypeBoulangerie),
      ('quincaillerie', l10n.shopTypeQuincaillerie),
      ('restaurant', l10n.shopTypeRestaurant),
      ('vetements', l10n.shopTypeVetements),
      ('informatique', l10n.shopTypeInformatique),
      ('autre', l10n.shopTypeAutre),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shopDetails),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<ShopBloc, ShopState>(
        listener: (context, state) {
          if (state is ShopLoaded) _updateControllers(state.shop);
          if (state is ShopOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.shopDetailsSaved),
                backgroundColor: AppTheme.primaryColor));
            context.pop();
          }
          if (state is ShopError) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppTheme.errorColor));
          }
        },
        buildWhen: (p, c) => c is ShopLoading || c is ShopLoaded,
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
                  _sectionHeader(l10n.generalInfo, AppTheme.primaryColor),
                  Text(l10n.shopInfoInstruction,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 20),

                  InputLabel(text: l10n.shopName),
                  _field(_nameController, 'Ex: Supermarché Chez Momo',
                      validator: AppValidators.required(l10n.required)),

                  const SizedBox(height: 12),
                  InputLabel(text: l10n.shopTypeLabel),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedShopType,
                    hint: Text(l10n.shopTypeAutre),
                    items: shopTypes
                        .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedShopType = v),
                    decoration: const InputDecoration(),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InputLabel(text: 'Ville / City (International)'),
                            Autocomplete<String>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return _commonCities;
                                }
                                return _commonCities.where((c) => c
                                    .toLowerCase()
                                    .contains(textEditingValue.text.toLowerCase()));
                              },
                              initialValue: TextEditingValue(text: _cityController.text),
                              onSelected: (String selection) {
                                _cityController.text = selection;
                              },
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                if (_cityController.text.isNotEmpty && controller.text.isEmpty) {
                                  controller.text = _cityController.text;
                                }
                                controller.addListener(() {
                                  _cityController.text = controller.text;
                                });
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    hintText: 'Ex: Douala, Paris, Abidjan...',
                                  ),
                                  validator: AppValidators.required(l10n.required),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InputLabel(text: l10n.district),
                            _field(_districtController, 'Ex: Akwa, Bastos, Centre...'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  InputLabel(text: l10n.addressLine1),
                  _field(_address1Controller, 'Rue, Avenue, Quartier...',
                      validator: AppValidators.required(l10n.required)),

                  const SizedBox(height: 12),
                  InputLabel(text: l10n.addressLine2),
                  _field(_address2Controller, l10n.addressLine2),

                  const SizedBox(height: 12),
                  InputLabel(text: '${l10n.phoneNumber} (International)'),
                  _field(_phoneController, 'Ex: +237 6XX XXX XXX ou +33 6 XX XX XX XX',
                      inputType: TextInputType.phone,
                      validator: AppValidators.required(l10n.required)),

                  const SizedBox(height: 24),
                  _sectionHeader(l10n.mobilePaymentSection, Colors.orange[700]!),
                  Text(
                    'Renseignez vos codes marchands pour recevoir les paiements Mobile Money (si applicables).',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),

                  _momoField(
                    controller: _orangeController,
                    label: l10n.orangeMoneyCode,
                    hint: l10n.momoCodeHint,
                    color: Colors.orange,
                    icon: Icons.circle,
                  ),
                  const SizedBox(height: 12),
                  _momoField(
                    controller: _mtnController,
                    label: l10n.mtnMomoCode,
                    hint: l10n.momoCodeHint,
                    color: Colors.yellow[800]!,
                    icon: Icons.circle,
                  ),

                  const SizedBox(height: 24),
                  _sectionHeader('Informations légales', Colors.grey[700]!),
                  const SizedBox(height: 12),
                  InputLabel(text: l10n.taxId),
                  _field(_taxIdController, 'Ex: M123456789 (NIU / Tax ID)'),

                  const SizedBox(height: 24),
                  _sectionHeader('Reçu', AppTheme.primaryColor),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InputLabel(text: l10n.receiptFooter),
                      Text('Max 60 chars',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    ],
                  ),
                  _field(_footerController, 'Merci pour votre achat !',
                      maxLines: 2, maxLength: 60),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PrimaryButton(onPressed: _saveShop, icon: Icons.save, label: l10n.saveDetails),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      ),
    );
  }

  Widget _momoField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
