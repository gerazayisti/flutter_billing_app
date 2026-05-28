import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/subscription.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/cloud/supabase_subscription_service.dart';
import '../../../../core/data/hive_database.dart';


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
  final SupabaseSubscriptionService subscriptionService;

  SubscriptionBloc({required this.subscriptionService})
      : super(const SubscriptionState()) {
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
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    final shopId = HiveDatabase.settingsBox
        .get('cloud_shop_id', defaultValue: '') as String;

    // Vérification côté serveur via Edge Function :
    // appelle l'API FreemoPay, vérifie le montant, puis écrit dans Supabase.
    final error = await subscriptionService.verifyAndActivate(
      shopId:    shopId,
      reference: event.reference.trim(),
      tier:      event.tier,
      cycle:     event.cycle,
    );

    if (error != null) {
      emit(state.copyWith(isLoading: false, error: error));
      return;
    }

    // verifyAndActivate a déjà sauvegardé dans Hive — on relit pour être cohérent
    emit(state.copyWith(
      isLoading: false,
      info:      SubscriptionService.current,
      activeTier: SubscriptionService.activeTier,
      activated: true,
    ));
  }
}
