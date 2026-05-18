import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:billing_app/core/data/hive_database.dart';
import '../../domain/entities/momo_transaction.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../data/services/mtn_momo_service.dart';
import '../../data/services/orange_money_service.dart';
import '../../../billing/domain/entities/payment_method.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object?> get props => [];
}

class InitiatePaymentEvent extends PaymentEvent {
  final PaymentMethod method;
  final String customerPhone;
  final double amount;
  final String merchantCode;
  final String cashierId;

  const InitiatePaymentEvent({
    required this.method,
    required this.customerPhone,
    required this.amount,
    required this.merchantCode,
    required this.cashierId,
  });

  @override
  List<Object?> get props => [method, customerPhone, amount];
}

class CheckPaymentStatusEvent extends PaymentEvent {
  final String transactionId;
  const CheckPaymentStatusEvent(this.transactionId);
  @override
  List<Object?> get props => [transactionId];
}

class ManualConfirmPaymentEvent extends PaymentEvent {
  final String transactionId;
  final String reference;
  const ManualConfirmPaymentEvent(this.transactionId, this.reference);
  @override
  List<Object?> get props => [transactionId, reference];
}

class CancelPaymentEvent extends PaymentEvent {
  final String transactionId;
  const CancelPaymentEvent(this.transactionId);
  @override
  List<Object?> get props => [transactionId];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentInitiating extends PaymentState {}

class PaymentPending extends PaymentState {
  final MomoTransaction transaction;
  final int elapsedSeconds;
  final String? ussdInstruction;

  const PaymentPending(this.transaction,
      {this.elapsedSeconds = 0, this.ussdInstruction});

  @override
  List<Object?> get props => [transaction, elapsedSeconds];
}

class PaymentConfirmed extends PaymentState {
  final MomoTransaction transaction;
  const PaymentConfirmed(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class PaymentFailed extends PaymentState {
  final String message;
  final MomoTransaction? transaction;
  const PaymentFailed(this.message, {this.transaction});
  @override
  List<Object?> get props => [message];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository repository;

  // Polling timer
  Timer? _pollTimer;
  int _pollCount = 0;
  static const int _maxPollCount = 24; // 24 × 5s = 2 minutes

  PaymentBloc({required this.repository}) : super(PaymentInitial()) {
    on<InitiatePaymentEvent>(_onInitiate);
    on<CheckPaymentStatusEvent>(_onCheckStatus);
    on<ManualConfirmPaymentEvent>(_onManualConfirm);
    on<CancelPaymentEvent>(_onCancel);
  }

  MtnMomoService? _buildMtnService() {
    final settings = HiveDatabase.settingsBox;
    final subKey = settings.get('mtn_subscription_key', defaultValue: '') as String;
    final userId = settings.get('mtn_api_user', defaultValue: '') as String;
    final apiKey = settings.get('mtn_api_key', defaultValue: '') as String;
    final env = settings.get('mtn_target_env', defaultValue: 'sandbox') as String;

    final svc = MtnMomoService(
      subscriptionKey: subKey,
      apiUserId: userId,
      apiKey: apiKey,
      targetEnvironment: env,
    );
    return svc.isConfigured ? svc : null;
  }

  Future<void> _onInitiate(
      InitiatePaymentEvent event, Emitter<PaymentState> emit) async {
    emit(PaymentInitiating());

    final txId = const Uuid().v4();
    final operator = event.method == PaymentMethod.orangeMoney
        ? MomoOperator.orange
        : MomoOperator.mtn;

    final transaction = MomoTransaction(
      id: txId,
      operator: operator,
      customerPhone: event.customerPhone,
      amount: event.amount,
      status: MomoStatus.pending,
      initiatedAt: DateTime.now(),
      cashierId: event.cashierId,
    );

    await repository.saveTransaction(transaction);

    if (operator == MomoOperator.mtn) {
      final mtnService = _buildMtnService();

      if (mtnService != null) {
        // Full API flow
        final result = await mtnService.requestToPay(
          referenceId: txId,
          customerPhone: event.customerPhone,
          amount: event.amount,
          payerMessage: 'Paiement Gestock+ ${event.amount.round()} FCFA',
        );

        if (!result.success) {
          final failed = transaction.copyWith(
            status: MomoStatus.failed,
            errorMessage: result.error,
          );
          await repository.updateTransaction(failed);
          emit(PaymentFailed(
              result.error ?? 'Erreur d\'initiation MTN MoMo',
              transaction: failed));
          return;
        }

        emit(PaymentPending(transaction));
        _startPolling(txId, mtnService);
      } else {
        // No API keys → USSD manual flow
        final ussd = '#150*1*${event.merchantCode}*${event.amount.round()}#';
        emit(PaymentPending(transaction, ussdInstruction: ussd));
      }
    } else {
      // Orange Money → USSD flow
      final ussd = OrangeMoneyService.getUssdInstruction(
        merchantCode: event.merchantCode,
        amount: event.amount,
      );
      emit(PaymentPending(transaction, ussdInstruction: ussd));
    }
  }

  void _startPolling(String txId, MtnMomoService service) {
    _pollCount = 0;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      add(CheckPaymentStatusEvent(txId));
    });
  }

  Future<void> _onCheckStatus(
      CheckPaymentStatusEvent event, Emitter<PaymentState> emit) async {
    if (state is! PaymentPending) return;
    final pending = state as PaymentPending;

    _pollCount++;
    final elapsed = _pollCount * 5;

    final mtnService = _buildMtnService();
    if (mtnService == null) {
      // Can't poll without API keys — emit updated elapsed time only
      emit(PaymentPending(pending.transaction,
          elapsedSeconds: elapsed,
          ussdInstruction: pending.ussdInstruction));
      if (_pollCount >= _maxPollCount) _stopPolling();
      return;
    }

    final result = await mtnService.getPaymentStatus(event.transactionId);

    if (result.status == 'SUCCESSFUL') {
      _stopPolling();
      final confirmed = pending.transaction.copyWith(
        status: MomoStatus.confirmed,
        reference: result.financialTxId ?? event.transactionId,
        confirmedAt: DateTime.now(),
      );
      await repository.updateTransaction(confirmed);
      emit(PaymentConfirmed(confirmed));
    } else if (result.status == 'FAILED') {
      _stopPolling();
      final failed = pending.transaction.copyWith(
        status: MomoStatus.failed,
        errorMessage: 'Paiement refusé par l\'opérateur',
      );
      await repository.updateTransaction(failed);
      emit(PaymentFailed('Paiement refusé par MTN MoMo', transaction: failed));
    } else {
      // Still pending
      emit(PaymentPending(pending.transaction,
          elapsedSeconds: elapsed,
          ussdInstruction: pending.ussdInstruction));

      if (_pollCount >= _maxPollCount) {
        _stopPolling();
        emit(PaymentPending(pending.transaction,
            elapsedSeconds: 120,
            ussdInstruction: pending.ussdInstruction));
      }
    }
  }

  Future<void> _onManualConfirm(
      ManualConfirmPaymentEvent event, Emitter<PaymentState> emit) async {
    _stopPolling();

    MomoTransaction? tx;
    if (state is PaymentPending) {
      tx = (state as PaymentPending).transaction;
    } else {
      tx = repository.getTransactionById(event.transactionId);
    }

    if (tx == null) {
      emit(const PaymentFailed('Transaction introuvable'));
      return;
    }

    final confirmed = tx.copyWith(
      status: MomoStatus.manualConfirm,
      reference: event.reference,
      confirmedAt: DateTime.now(),
    );
    await repository.updateTransaction(confirmed);
    emit(PaymentConfirmed(confirmed));
  }

  Future<void> _onCancel(
      CancelPaymentEvent event, Emitter<PaymentState> emit) async {
    _stopPolling();

    if (state is PaymentPending) {
      final tx = (state as PaymentPending).transaction;
      final cancelled = tx.copyWith(status: MomoStatus.cancelled);
      await repository.updateTransaction(cancelled);
    }
    emit(PaymentInitial());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollCount = 0;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
