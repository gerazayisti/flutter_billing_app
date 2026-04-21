import 'package:billing_app/l10n/app_localizations.dart';

class AppValidators {
  static String? Function(String?) required(String message) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  static String? price(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.priceRequired;
    }
    if (double.tryParse(value) == null) {
      return l10n.validNumberRequired;
    }
    if (double.parse(value) < 0) {
      return l10n.positivePriceRequired;
    }
    return null;
  }
}
