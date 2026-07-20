import 'package:equatable/equatable.dart';
import '../../domain/entities/mobile_money_payment.dart';

abstract class MobileMoneyState extends Equatable {
  const MobileMoneyState();

  @override
  List<Object?> get props => [];
}

class PaymentIdle extends MobileMoneyState {}

class PaymentInitiating extends MobileMoneyState {}

class PaymentAwaitingClient extends MobileMoneyState {
  final MobileMoneyPayment payment;
  final bool showReviveOption;

  const PaymentAwaitingClient(this.payment, {this.showReviveOption = false});

  @override
  List<Object?> get props => [payment, showReviveOption];
}

class PaymentManualInstructions extends MobileMoneyState {
  final MobileMoneyPayment payment;

  const PaymentManualInstructions(this.payment);

  @override
  List<Object?> get props => [payment];
}

class PaymentCompleted extends MobileMoneyState {
  final MobileMoneyPayment payment;

  const PaymentCompleted(this.payment);

  @override
  List<Object?> get props => [payment];
}

class PaymentFailed extends MobileMoneyState {
  final String? code;
  final String? message;

  const PaymentFailed({this.code, this.message});

  @override
  List<Object?> get props => [code, message];
}
