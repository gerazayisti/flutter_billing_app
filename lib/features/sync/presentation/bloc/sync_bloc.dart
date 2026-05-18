import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:billing_app/core/cloud/supabase_sync_service.dart';
import 'package:billing_app/core/data/hive_database.dart';

// ── Events ─────────────────────────────────────────────────────────────────

abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class LoadSyncStatusEvent extends SyncEvent {}

class ConfigureCloudEvent extends SyncEvent {
  final String url;
  final String anonKey;
  const ConfigureCloudEvent(this.url, this.anonKey);
  @override
  List<Object?> get props => [url, anonKey];
}

class SignInCloudEvent extends SyncEvent {
  final String email;
  final String password;
  const SignInCloudEvent(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class SignOutCloudEvent extends SyncEvent {}

class SyncNowEvent extends SyncEvent {}

class PullFromCloudEvent extends SyncEvent {}

class ToggleAutoSyncEvent extends SyncEvent {}

// ── State ──────────────────────────────────────────────────────────────────

class SyncState extends Equatable {
  final bool isConfigured;
  final bool isSignedIn;
  final String? userEmail;
  final bool isSyncing;
  final bool isPulling;
  final DateTime? lastSyncedAt;
  final bool autoSync;
  final String? error;
  final String? successMessage;

  const SyncState({
    this.isConfigured = false,
    this.isSignedIn = false,
    this.userEmail,
    this.isSyncing = false,
    this.isPulling = false,
    this.lastSyncedAt,
    this.autoSync = true,
    this.error,
    this.successMessage,
  });

  SyncState copyWith({
    bool? isConfigured,
    bool? isSignedIn,
    String? userEmail,
    bool? isSyncing,
    bool? isPulling,
    DateTime? lastSyncedAt,
    bool? autoSync,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) =>
      SyncState(
        isConfigured: isConfigured ?? this.isConfigured,
        isSignedIn: isSignedIn ?? this.isSignedIn,
        userEmail: userEmail ?? this.userEmail,
        isSyncing: isSyncing ?? this.isSyncing,
        isPulling: isPulling ?? this.isPulling,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        autoSync: autoSync ?? this.autoSync,
        error: clearMessages ? null : error ?? this.error,
        successMessage:
            clearMessages ? null : successMessage ?? this.successMessage,
      );

  @override
  List<Object?> get props => [
        isConfigured, isSignedIn, userEmail, isSyncing, isPulling,
        lastSyncedAt, autoSync, error, successMessage,
      ];
}

// ── Bloc ───────────────────────────────────────────────────────────────────

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SupabaseSyncService syncService;

  SyncBloc({required this.syncService}) : super(const SyncState()) {
    on<LoadSyncStatusEvent>(_onLoad);
    on<ConfigureCloudEvent>(_onConfigure);
    on<SignInCloudEvent>(_onSignIn);
    on<SignOutCloudEvent>(_onSignOut);
    on<SyncNowEvent>(_onSyncNow);
    on<PullFromCloudEvent>(_onPull);
    on<ToggleAutoSyncEvent>(_onToggleAutoSync);
  }

  void _onLoad(LoadSyncStatusEvent event, Emitter<SyncState> emit) {
    final s = HiveDatabase.settingsBox;
    final lastMs = s.get('last_sync_ms', defaultValue: 0) as int;
    final autoSync = s.get('cloud_auto_sync', defaultValue: true) as bool;

    emit(state.copyWith(
      isConfigured: syncService.isConfigured,
      isSignedIn: syncService.isSignedIn,
      userEmail: syncService.userEmail,
      lastSyncedAt:
          lastMs > 0 ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null,
      autoSync: autoSync,
    ));
  }

  Future<void> _onConfigure(
      ConfigureCloudEvent event, Emitter<SyncState> emit) async {
    emit(state.copyWith(isSyncing: true, error: null));
    try {
      await syncService.reconfigure(event.url, event.anonKey);
      emit(state.copyWith(
        isSyncing: false,
        isConfigured: syncService.isConfigured,
        successMessage: 'configured',
      ));
      emit(state.copyWith(clearMessages: true));
    } catch (e) {
      emit(state.copyWith(isSyncing: false, error: e.toString()));
    }
  }

  Future<void> _onSignIn(
      SignInCloudEvent event, Emitter<SyncState> emit) async {
    if (!syncService.isConfigured) return;
    emit(state.copyWith(isSyncing: true, error: null));
    final ok = await syncService.signIn(event.email, event.password);
    if (ok) {
      emit(state.copyWith(
        isSyncing: false,
        isSignedIn: true,
        userEmail: syncService.userEmail,
        successMessage: 'signed_in',
      ));
      emit(state.copyWith(clearMessages: true));
    } else {
      emit(state.copyWith(
          isSyncing: false, error: 'auth_error'));
    }
  }

  Future<void> _onSignOut(
      SignOutCloudEvent event, Emitter<SyncState> emit) async {
    await syncService.signOut();
    emit(state.copyWith(isSignedIn: false, userEmail: null));
  }

  Future<void> _onSyncNow(SyncNowEvent event, Emitter<SyncState> emit) async {
    if (!syncService.isConfigured) return;
    emit(state.copyWith(isSyncing: true, error: null));
    try {
      final s = HiveDatabase.settingsBox;
      final lastMs = s.get('last_sync_ms', defaultValue: 0) as int;
      final lastSync =
          lastMs > 0 ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null;

      final syncedAt = await syncService.pushAll(lastSync: lastSync);
      await s.put('last_sync_ms', syncedAt.millisecondsSinceEpoch);

      emit(state.copyWith(
        isSyncing: false,
        lastSyncedAt: syncedAt,
        successMessage: 'synced',
      ));
      emit(state.copyWith(clearMessages: true));
    } catch (e) {
      emit(state.copyWith(isSyncing: false, error: e.toString()));
    }
  }

  Future<void> _onPull(
      PullFromCloudEvent event, Emitter<SyncState> emit) async {
    if (!syncService.isConfigured) return;
    emit(state.copyWith(isPulling: true, error: null));
    try {
      await syncService.pullAll();
      emit(state.copyWith(isPulling: false, successMessage: 'pulled'));
      emit(state.copyWith(clearMessages: true));
    } catch (e) {
      emit(state.copyWith(isPulling: false, error: e.toString()));
    }
  }

  void _onToggleAutoSync(ToggleAutoSyncEvent event, Emitter<SyncState> emit) {
    final newVal = !state.autoSync;
    HiveDatabase.settingsBox.put('cloud_auto_sync', newVal);
    emit(state.copyWith(autoSync: newVal));
  }
}
