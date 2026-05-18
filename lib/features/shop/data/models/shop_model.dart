import 'package:hive/hive.dart';
import '../../domain/entities/shop.dart';

part 'shop_model.g.dart';

@HiveType(typeId: 1)
class ShopModel extends Shop {
  @override
  @HiveField(0)
  final String name;
  @override
  @HiveField(1)
  final String addressLine1;
  @override
  @HiveField(2)
  final String addressLine2;
  @override
  @HiveField(3)
  final String phoneNumber;
  @override
  @HiveField(4)
  final String upiId;
  @override
  @HiveField(5)
  final String footerText;

  // Cameroon-specific fields — indices 6–11
  @override
  @HiveField(6)
  final String orangeMoneyMerchant;
  @override
  @HiveField(7)
  final String mtnMomoMerchant;
  @override
  @HiveField(8)
  final String city;
  @override
  @HiveField(9)
  final String district;
  @override
  @HiveField(10)
  final String shopType;
  @override
  @HiveField(11)
  final String taxId;

  const ShopModel({
    required this.name,
    required this.addressLine1,
    required this.addressLine2,
    required this.phoneNumber,
    required this.upiId,
    required this.footerText,
    this.orangeMoneyMerchant = '',
    this.mtnMomoMerchant = '',
    this.city = '',
    this.district = '',
    this.shopType = '',
    this.taxId = '',
  }) : super(
          name: name,
          addressLine1: addressLine1,
          addressLine2: addressLine2,
          phoneNumber: phoneNumber,
          upiId: upiId,
          footerText: footerText,
          orangeMoneyMerchant: orangeMoneyMerchant,
          mtnMomoMerchant: mtnMomoMerchant,
          city: city,
          district: district,
          shopType: shopType,
          taxId: taxId,
        );

  factory ShopModel.fromEntity(Shop shop) {
    return ShopModel(
      name: shop.name,
      addressLine1: shop.addressLine1,
      addressLine2: shop.addressLine2,
      phoneNumber: shop.phoneNumber,
      upiId: shop.upiId,
      footerText: shop.footerText,
      orangeMoneyMerchant: shop.orangeMoneyMerchant,
      mtnMomoMerchant: shop.mtnMomoMerchant,
      city: shop.city,
      district: shop.district,
      shopType: shop.shopType,
      taxId: shop.taxId,
    );
  }

  Shop toEntity() => this;
}
