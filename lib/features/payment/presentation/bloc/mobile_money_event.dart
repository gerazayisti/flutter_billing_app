import 'package:equatable/equatable.dart';
import '../../domain/entities/mobile_money_payment.dart';

abstract class MobileMoneyEvent extends Equatable {
  const MobileMoneyEvent();

  @override
  List<Object?> get props => [];
}

class InitiatePayment extends MobileMoneyEvent {
  final String saleId;
  final double amount;
  final String phoneNumberRaw;

  const InitiatePayment({
    required this.saleId,
    required this.amount,
    required this.phoneNumberRaw,
  });

  @override
  List<Object?> get props => [saleId, amount, phoneNumberRaw];
}

class StatusUpdated extends MobileMoneyEvent {
  final MobileMoneyPayment payment;

  const StatusUpdated(this.payment);

  @override
  List<Object?> get props => [payment];
}

class RevivePinPrompt extends MobileMoneyEvent {
  const RevivePinPrompt();
}
