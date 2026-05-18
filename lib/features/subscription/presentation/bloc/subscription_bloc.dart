import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/subscription.dart';
import '../../../../core/services/subscription_service.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class SubscriptionEvent {
  const SubscriptionEvent();
}

class LoadSubscriptionEvent extends SubscriptionEvent {
  const LoadSubscriptionEvent();
}

class ActivateSubscriptionEvent extends SubscriptionEvent {
  final SubscriptionTier tier;
  final BillingCycle cycle;
  final String reference;

  const ActivateSubscriptionEvent({
    required this.tier,
    required this.cycle,
    required this.reference,
  });
}

// ── State ─────────────────────────────────────────────────────────────────────

class SubscriptionState {
  final SubscriptionInfo? info;
  final SubscriptionTier activeTier;
  final int trialDaysRemaining;
  final bool isLoading;
  final String? error;
  final bool activated;

  const SubscriptionState({
    this.info,
    this.activeTier = SubscriptionTier.trial,
    this.trialDaysRemaining = 30,
    this.isLoading = false,
    this.error,
    this.activated = false,
  });

  SubscriptionState copyWith({
    SubscriptionInfo? info,
    SubscriptionTier? activeTier,
    int? trialDaysRemaining,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? activated,
  }) =>
      SubscriptionState(
        info: info ?? this.info,
        activeTier: activeTier ?? this.activeTier,
        trialDaysRemaining: trialDaysRemaining ?? this.trialDaysRemaining,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        activated: activated ?? this.activated,
      );
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc() : super(const SubscriptionState()) {
    on<LoadSubscriptionEvent>(_onLoad);
    on<ActivateSubscriptionEvent>(_onActivate);
  }

  void _onLoad(LoadSubscriptionEvent event, Emitter<SubscriptionState> emit) {
    emit(SubscriptionState(
      info: SubscriptionService.current,
      activeTier: SubscriptionService.activeTier,
      trialDaysRemaining: SubscriptionService.trialDaysRemaining,
    ));
  }

  Future<void> _onActivate(
      ActivateSubscriptionEvent event, Emitter<SubscriptionState> emit) async {
    if (event.reference.trim().isEmpty) {
      emit(state.copyWith(error: 'Entrez la référence Freemopay'));
      emit(state.copyWith(clearError: true));
      return;
    }

    emit(state.copyWith(isLoading: true));

    final duration = event.cycle == BillingCycle.monthly
        ? const Duration(days: 31)
        : const Duration(days: 366);

    final info = SubscriptionInfo(
      tier: event.tier,
      cycle: event.cycle,
      startDate: DateTime.now(),
      expiryDate: DateTime.now().add(duration),
      freemopayReference: event.reference.trim(),
    );

    await SubscriptionService.save(info);

    emit(state.copyWith(
      isLoading: false,
      info: info,
      activeTier: event.tier,
      activated: true,
    ));
  }
}
