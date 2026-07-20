import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/entities/mobile_money_payment.dart';
import 'mobile_money_event.dart';
import 'mobile_money_state.dart';

class MobileMoneyBloc extends Bloc<MobileMoneyEvent, MobileMoneyState> {
  final PaymentRepository _repository;
  StreamSubscription? _statusSub;
  Timer? _reviveTimer;

  MobileMoneyBloc(this._repository) : super(PaymentIdle()) {
    on<InitiatePayment>(_onInitiate);
    on<StatusUpdated>(_onStatusUpdated);
    on<RevivePinPrompt>(_onRevive);
  }

  Future<void> _onInitiate(InitiatePayment event, Emitter<MobileMoneyState> emit) async {
    emit(PaymentInitiating());

    try {
      final payment = await _repository.initiatePawaPayDeposit(
        saleId: event.saleId,
        amount: event.amount,
        phoneNumberRaw: event.phoneNumberRaw,
      );

      if (payment.status == PaymentStatus.failed) {
        emit(PaymentFailed(code: payment.failureCode, message: payment.failureMessage));
        return;
      }

      if (payment.pinPrompt == 'MANUAL') {
        emit(PaymentManualInstructions(payment));
      } else {
        emit(PaymentAwaitingClient(payment));

        if (payment.pinPromptRevivable) {
          _reviveTimer = Timer(const Duration(seconds: 10), () {
            if (state is PaymentAwaitingClient) {
              final current = state as PaymentAwaitingClient;
              emit(PaymentAwaitingClient(current.payment, showReviveOption: true));
            }
          });
        }
      }

      _statusSub?.cancel();
      _statusSub = _repository.watchPawaPayDepositStatus(payment.depositId).listen((updated) {
        add(StatusUpdated(updated));
      });

      // Lancer un polling périodique actif en parallèle de Realtime
      // toutes les 5 secondes pendant 2 minutes maximum (24 tentatives)
      int attempts = 0;
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        attempts++;
        if (state is PaymentCompleted || state is PaymentFailed || attempts > 24) {
          timer.cancel();
          return;
        }

        try {
          final updated = await _repository.checkPawaPayDepositStatus(payment.depositId);
          if (updated.status == PaymentStatus.completed || updated.status == PaymentStatus.failed) {
            timer.cancel();
            add(StatusUpdated(updated));
          }
        } catch (e) {
          // Ignorer les erreurs réseau temporaires pendant le polling
          print("Polling error: $e");
        }
      });
    } catch (e) {
      emit(PaymentFailed(message: e.toString()));
    }
  }

  void _onStatusUpdated(StatusUpdated event, Emitter<MobileMoneyState> emit) {
    final p = event.payment;
    if (p.status == PaymentStatus.completed) {
      _reviveTimer?.cancel();
      emit(PaymentCompleted(p));
    } else if (p.status == PaymentStatus.failed) {
      _reviveTimer?.cancel();
      emit(PaymentFailed(code: p.failureCode, message: p.failureMessage));
    }
  }

  void _onRevive(RevivePinPrompt event, Emitter<MobileMoneyState> emit) {
    if (state is PaymentAwaitingClient) {
      final current = state as PaymentAwaitingClient;
      emit(PaymentManualInstructions(current.payment));
    }
  }

  @override
  Future<void> close() {
    _statusSub?.cancel();
    _reviveTimer?.cancel();
    return super.close();
  }
}
