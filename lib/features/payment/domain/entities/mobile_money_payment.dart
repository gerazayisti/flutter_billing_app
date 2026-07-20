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

  MobileMoneyPayment({
    required this.depositId,
    required this.status,
    required this.pinPrompt,
    required this.pinPromptRevivable,
    this.pinPromptInstructions,
    this.nameDisplayedToCustomer,
    this.failureCode,
    this.failureMessage,
  });

  MobileMoneyPayment copyWith({
    PaymentStatus? status,
    String? failureCode,
    String? failureMessage,
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
    );
  }
}
