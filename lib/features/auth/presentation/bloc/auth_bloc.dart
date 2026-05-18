import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:billing_app/core/cloud/supabase_auth_service.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/features/auth/domain/entities/user.dart';
import 'package:billing_app/features/shop/data/models/shop_model.dart';

// ── Events ──────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class CheckAuthEvent extends AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  const LoginEvent(this.email, this.password);
  @override
  List<Object> get props => [email, password];
}

class LogoutEvent extends AuthEvent {}

class SwitchShopEvent extends AuthEvent {
  final String shopId;
  final Map<String, dynamic> shopData;
  const SwitchShopEvent({required this.shopId, required this.shopData});
  @override
  List<Object> get props => [shopId, shopData];
}

class SignUpSuccessEvent extends AuthEvent {
  final User user;
  final String shopId;
  final Map<String, dynamic> shopData;
  const SignUpSuccessEvent({required this.user, required this.shopId, required this.shopData});
  @override
  List<Object> get props => [user, shopId, shopData];
}

// ── States ───────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final String shopId;
  const AuthAuthenticated({required this.user, required this.shopId});
  @override
  List<Object?> get props => [user, shopId];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseAuthService authService;

  AuthBloc({required this.authService}) : super(AuthInitial()) {
    on<CheckAuthEvent>(_onCheckAuth);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<SwitchShopEvent>((event, emit) {
      _syncShopToHive(event.shopData);
      final current = state;
      if (current is AuthAuthenticated) {
        emit(AuthAuthenticated(user: current.user, shopId: event.shopId));
      }
    });
    on<SignUpSuccessEvent>((event, emit) {
      _syncShopToHive(event.shopData);
      emit(AuthAuthenticated(user: event.user, shopId: event.shopId));
    });
  }

  Future<void> _onCheckAuth(
      CheckAuthEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await authService.restoreSession();
    if (result == null || !result.success) {
      emit(AuthUnauthenticated());
      return;
    }
    _syncShopToHive(result.shopData!);
    emit(AuthAuthenticated(user: result.user!, shopId: result.shopId!));
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await authService.signIn(event.email, event.password);
    if (!result.success) {
      emit(AuthError(result.error ?? 'Erreur inconnue'));
      return;
    }
    _syncShopToHive(result.shopData!);
    emit(AuthAuthenticated(user: result.user!, shopId: result.shopId!));
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await authService.signOut();
    emit(AuthUnauthenticated());
  }

  /// Writes Supabase shop data into Hive so ShopBloc / receipts / sync
  /// continue to work with no other changes.
  void _syncShopToHive(Map<String, dynamic> d) {
    try {
      // Store shopId so SupabaseSyncService can tag records correctly.
      final shopId = d['id'] as String?;
      if (shopId != null && shopId.isNotEmpty) {
        HiveDatabase.settingsBox.put('cloud_shop_id', shopId);
      }

      final box      = HiveDatabase.shopBox;
      final existing = box.values.isNotEmpty ? box.values.first : null;

      final model = ShopModel(
        name:               d['name']             as String? ?? '',
        addressLine1:       d['address1']         as String? ?? existing?.addressLine1 ?? '',
        addressLine2:       d['address2']         as String? ?? existing?.addressLine2 ?? '',
        phoneNumber:        d['phone']            as String? ?? existing?.phoneNumber  ?? '',
        upiId:              existing?.upiId       ?? '',
        footerText:         d['receipt_footer']   as String? ?? existing?.footerText   ?? '',
        orangeMoneyMerchant: d['orange_merchant'] as String? ?? existing?.orangeMoneyMerchant ?? '',
        mtnMomoMerchant:    d['mtn_merchant']     as String? ?? existing?.mtnMomoMerchant     ?? '',
        city:               d['city']             as String? ?? existing?.city          ?? '',
        district:           d['district']         as String? ?? existing?.district      ?? '',
        shopType:           d['shop_type']        as String? ?? existing?.shopType      ?? '',
        taxId:              d['tax_id']           as String? ?? existing?.taxId         ?? '',
      );

      if (box.isEmpty) {
        box.add(model);
      } else {
        box.putAt(0, model);
      }
    } catch (_) {}
  }
}
