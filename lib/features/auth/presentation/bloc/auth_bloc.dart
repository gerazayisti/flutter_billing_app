import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:billing_app/features/auth/domain/entities/user.dart';
import 'package:billing_app/core/data/hive_database.dart';

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
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  User? currentUser;

  AuthBloc() : super(AuthInitial()) {
    on<LoginWithPinEvent>(_onLoginWithPin);
    on<LogoutEvent>(_onLogout);
  }

  void _onLoginWithPin(LoginWithPinEvent event, Emitter<AuthState> emit) {
    try {
      final users = HiveDatabase.usersBox.values.toList();
      
      // Attempt to find a user matching the PIN
      final user = users.firstWhere(
        (u) => u.pinCode == event.pinCode,
        orElse: () => throw Exception('Incorrect PIN'),
      );
      
      currentUser = user;
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(const AuthError('Code PIN incorrect'));
      emit(AuthInitial()); // Reset after error
    }
  }

  void _onLogout(LogoutEvent event, Emitter<AuthState> emit) {
    currentUser = null;
    emit(AuthInitial());
  }
}
