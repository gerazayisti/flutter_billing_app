enum PaymentMethod {
  cash,
  card,
  mobileMoney,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.card:
        return 'Carte';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
    }
  }

  String get stringValue => name;

  static PaymentMethod fromString(String? value) {
    switch (value) {
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
