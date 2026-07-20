enum WithdrawalStatus { pending, accepted, completed, failed }

class ShopWithdrawal {
  final String payoutId;
  final String shopId;
  final String phoneNumber;
  final String provider;
  final double grossAmount;
  final double feeAmount;
  final double netAmount;
  final WithdrawalStatus status;
  final String? failureCode;
  final String? failureMessage;
  final DateTime createdAt;

  ShopWithdrawal({
    required this.payoutId,
    required this.shopId,
    required this.phoneNumber,
    required this.provider,
    required this.grossAmount,
    required this.feeAmount,
    required this.netAmount,
    required this.status,
    this.failureCode,
    this.failureMessage,
    required this.createdAt,
  });

  ShopWithdrawal copyWith({
    WithdrawalStatus? status,
    String? failureCode,
    String? failureMessage,
  }) {
    return ShopWithdrawal(
      payoutId: payoutId,
      shopId: shopId,
      phoneNumber: phoneNumber,
      provider: provider,
      grossAmount: grossAmount,
      feeAmount: feeAmount,
      netAmount: netAmount,
      status: status ?? this.status,
      failureCode: failureCode ?? this.failureCode,
      failureMessage: failureMessage ?? this.failureMessage,
      createdAt: createdAt,
    );
  }
}
