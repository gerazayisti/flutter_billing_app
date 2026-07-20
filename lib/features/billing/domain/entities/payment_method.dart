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

  bool get isMobileMoney => this == PaymentMethod.mobileMoney;

  String get stringValue => name;

  static PaymentMethod fromString(String? value) {
    switch (value) {
      case 'orangeMoney':
      case 'mtnMomo':
      case 'mobileMoney':
        return PaymentMethod.mobileMoney;
      case 'card':
        return PaymentMethod.card;
      case 'cash':
      default:
        return PaymentMethod.cash;
    }
  }
}
