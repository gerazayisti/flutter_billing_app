import 'package:equatable/equatable.dart';
import '../../domain/entities/shop_withdrawal.dart';

enum WalletStatus { initial, loading, loaded, error }

class WalletState extends Equatable {
  final WalletStatus status;
  final double balance;
  final List<ShopWithdrawal> withdrawals;
  final String errorMessage;
  final bool isWithdrawing;
  final String? withdrawalSuccessMessage;
  final String? withdrawalErrorMessage;
  final String shopId;

  const WalletState({
    this.status = WalletStatus.initial,
    this.balance = 0.0,
    this.withdrawals = const [],
    this.errorMessage = '',
    this.isWithdrawing = false,
    this.withdrawalSuccessMessage,
    this.withdrawalErrorMessage,
    this.shopId = '',
  });

  WalletState copyWith({
    WalletStatus? status,
    double? balance,
    List<ShopWithdrawal>? withdrawals,
    String? errorMessage,
    bool? isWithdrawing,
    String? withdrawalSuccessMessage,
    String? withdrawalErrorMessage,
    String? shopId,
  }) {
    return WalletState(
      status: status ?? this.status,
      balance: balance ?? this.balance,
      withdrawals: withdrawals ?? this.withdrawals,
      errorMessage: errorMessage ?? this.errorMessage,
      isWithdrawing: isWithdrawing ?? this.isWithdrawing,
      withdrawalSuccessMessage: withdrawalSuccessMessage,
      withdrawalErrorMessage: withdrawalErrorMessage,
      shopId: shopId ?? this.shopId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        balance,
        withdrawals,
        errorMessage,
        isWithdrawing,
        withdrawalSuccessMessage,
        withdrawalErrorMessage,
        shopId,
      ];
}
