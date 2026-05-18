import 'package:equatable/equatable.dart';

class Shop extends Equatable {
  final String name;
  final String addressLine1;
  final String addressLine2;
  final String phoneNumber;
  // Legacy field kept for Hive backward compatibility — not shown in UI
  final String upiId;
  final String footerText;

  // Cameroon-specific fields
  final String city;
  final String district;
  final String shopType;
  final String orangeMoneyMerchant;
  final String mtnMomoMerchant;
  final String taxId;

  const Shop({
    this.name = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.phoneNumber = '',
    this.upiId = '',
    this.footerText = '',
    this.city = '',
    this.district = '',
    this.shopType = '',
    this.orangeMoneyMerchant = '',
    this.mtnMomoMerchant = '',
    this.taxId = '',
  });

  bool get hasOrangeMoney => orangeMoneyMerchant.isNotEmpty;
  bool get hasMtnMomo => mtnMomoMerchant.isNotEmpty;
  bool get hasMobileMoney => hasOrangeMoney || hasMtnMomo;

  Shop copyWith({
    String? name,
    String? addressLine1,
    String? addressLine2,
    String? phoneNumber,
    String? upiId,
    String? footerText,
    String? city,
    String? district,
    String? shopType,
    String? orangeMoneyMerchant,
    String? mtnMomoMerchant,
    String? taxId,
  }) {
    return Shop(
      name: name ?? this.name,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      upiId: upiId ?? this.upiId,
      footerText: footerText ?? this.footerText,
      city: city ?? this.city,
      district: district ?? this.district,
      shopType: shopType ?? this.shopType,
      orangeMoneyMerchant: orangeMoneyMerchant ?? this.orangeMoneyMerchant,
      mtnMomoMerchant: mtnMomoMerchant ?? this.mtnMomoMerchant,
      taxId: taxId ?? this.taxId,
    );
  }

  @override
  List<Object?> get props => [
        name, addressLine1, addressLine2, phoneNumber, upiId, footerText,
        city, district, shopType, orangeMoneyMerchant, mtnMomoMerchant, taxId,
      ];
}
