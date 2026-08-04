import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class LoadWalletDataEvent extends WalletEvent {}

class InitiateWithdrawalEvent extends WalletEvent {
  final double amount;
  final String phoneNumber;

  const InitiateWithdrawalEvent({required this.amount, required this.phoneNumber});

  @override
  List<Object?> get props => [amount, phoneNumber];
}

class CheckPendingWithdrawalsEvent extends WalletEvent {}
