enum PaymentStatus { pending, accepted, processing, completed, failed }

class MobileMoneyPayment {
  final String depositId;
  final PaymentStatus status;
  final String pinPrompt; // "AUTOMATIC" | "MANUAL"
  final bool pinPromptRevivable;
  final Map<String, dynamic>? pinPromptInstructions;
  final String? nameDisplayedToCustomer;
  final String? failureCode;
  final String? failureMessage;
  final double amount;
  final String phoneNumber;
  final String provider;

  MobileMoneyPayment({
    required this.depositId,
    required this.status,
    required this.pinPrompt,
    required this.pinPromptRevivable,
    this.pinPromptInstructions,
    this.nameDisplayedToCustomer,
    this.failureCode,
    this.failureMessage,
    this.amount = 0.0,
    this.phoneNumber = '',
    this.provider = 'Mobile Money',
  });

  MobileMoneyPayment copyWith({
    PaymentStatus? status,
    String? failureCode,
    String? failureMessage,
    double? amount,
    String? phoneNumber,
    String? provider,
  }) {
    return MobileMoneyPayment(
      depositId: depositId,
      status: status ?? this.status,
      pinPrompt: pinPrompt,
      pinPromptRevivable: pinPromptRevivable,
      pinPromptInstructions: pinPromptInstructions,
      nameDisplayedToCustomer: nameDisplayedToCustomer,
      failureCode: failureCode ?? this.failureCode,
      failureMessage: failureMessage ?? this.failureMessage,
      amount: amount ?? this.amount,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      provider: provider ?? this.provider,
    );
  }
}
