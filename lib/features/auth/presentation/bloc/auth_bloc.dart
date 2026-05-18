import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:billing_app/features/auth/domain/entities/user.dart';
import 'package:billing_app/features/auth/data/models/user_model.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/core/utils/pin_hasher.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class LoginWithPinEvent extends AuthEvent {
  final String pinCode;
  const LoginWithPinEvent(this.pinCode);
  @override
  List<Object> get props => [pinCode];
}

class LogoutEvent extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  final int? attemptsLeft;
  const AuthError(this.message, {this.attemptsLeft});
  @override
  List<Object?> get props => [message, attemptsLeft];
}

class AuthLocked extends AuthState {
  final DateTime lockoutUntil;
  const AuthLocked(this.lockoutUntil);
  @override
  List<Object?> get props => [lockoutUntil];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  User? currentUser;

  static const int _maxAttempts = 3;
  static const Duration _lockoutDuration = Duration(seconds: 30);

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  AuthBloc() : super(AuthInitial()) {
    on<LoginWithPinEvent>(_onLoginWithPin);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onLoginWithPin(
      LoginWithPinEvent event, Emitter<AuthState> emit) async {
    // Check lockout
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      emit(AuthLocked(_lockoutUntil!));
      return;
    }
    _lockoutUntil = null;

    try {
      final users = HiveDatabase.usersBox.values.toList();

      UserModel? matchedUser;
      for (final u in users) {
        if (PinHasher.verify(event.pinCode, u.pinCode)) {
          matchedUser = u;
          // Migrate legacy plain-text PIN to hashed on first match
          if (!PinHasher.isHashed(u.pinCode)) {
            final upgraded = UserModel(
              id: u.id,
              name: u.name,
              pinCode: PinHasher.hash(event.pinCode),
              role: u.role,
            );
            await HiveDatabase.usersBox.put(u.id, upgraded);
          }
          break;
        }
      }

      if (matchedUser == null) {
        _failedAttempts++;
        final remaining = _maxAttempts - _failedAttempts;

        if (_failedAttempts >= _maxAttempts) {
          _lockoutUntil = DateTime.now().add(_lockoutDuration);
          _failedAttempts = 0;
          emit(AuthLocked(_lockoutUntil!));
        } else {
          emit(AuthError('Code PIN incorrect', attemptsLeft: remaining));
          emit(AuthInitial());
        }
        return;
      }

      _failedAttempts = 0;
      currentUser = matchedUser;
      emit(AuthAuthenticated(matchedUser));
    } catch (e) {
      emit(const AuthError('Erreur interne. Réessayez.'));
      emit(AuthInitial());
    }
  }

  void _onLogout(LogoutEvent event, Emitter<AuthState> emit) {
    currentUser = null;
    _failedAttempts = 0;
    emit(AuthInitial());
  }
}
