/// Orange Money Cameroun — USSD merchant flow
///
/// Orange's OM Web Payment API requires a browser redirect and is not
/// suitable for direct POS use. The standard merchant POS flow relies on
/// the customer dialing the USSD code independently.
///
/// Full API integration is available upon request with an Orange Business
/// merchant agreement. This service provides the USSD instructions and
/// manual confirmation flow in the meantime.
class OrangeMoneyService {
  /// Returns the USSD string the customer should dial to pay
  static String getUssdInstruction({
    required String merchantCode,
    required double amount,
  }) {
    final amountStr = amount.round().toString();
    // Orange Money Cameroun USSD: #150*1*merchantCode*amount#
    return '#150*1*$merchantCode*$amountStr#';
  }

  /// Returns human-readable payment instructions
  static String getPaymentInstructions({
    required String merchantCode,
    required double amount,
  }) {
    final ussd = getUssdInstruction(merchantCode: merchantCode, amount: amount);
    return 'Composez $ussd sur votre téléphone Orange\net confirmez avec votre code secret.';
  }

  /// Validates a manually-entered Orange Money reference
  static bool isValidReference(String ref) {
    // Orange Money references are typically 10-15 digit numbers
    final cleaned = ref.trim();
    return cleaned.isNotEmpty && RegExp(r'^\d{6,20}$').hasMatch(cleaned);
  }
}
