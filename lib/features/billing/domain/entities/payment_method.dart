enum PaymentMethod {
  cash,
  orangeMoney,
  mtnMomo,
  card,
  // Legacy value preserved for existing order history records
  mobileMoney,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.mtnMomo:
        return 'MTN MoMo';
      case PaymentMethod.card:
        return 'Carte';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
    }
  }

  bool get isMobileMoney =>
      this == PaymentMethod.orangeMoney ||
      this == PaymentMethod.mtnMomo ||
      this == PaymentMethod.mobileMoney;

  String get stringValue => name;

  static PaymentMethod fromString(String? value) {
    switch (value) {
      case 'orangeMoney':
        return PaymentMethod.orangeMoney;
      case 'mtnMomo':
        return PaymentMethod.mtnMomo;
      case 'card':
        return PaymentMethod.card;
      case 'mobileMoney':
        return PaymentMethod.mobileMoney;
      case 'cash':
      default:
        return PaymentMethod.cash;
    }
  }
}
