import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:billing_app/core/cloud/supabase_auth_service.dart';

// ── Events ────────────────────────────────────────────────────

abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();
  @override
  List<Object?> get props => [];
}

class LoadUsersEvent extends UserManagementEvent {
  final String shopId;
  const LoadUsersEvent(this.shopId);
  @override
  List<Object?> get props => [shopId];
}

class AddEmployeeEvent extends UserManagementEvent {
  final String shopId;
  final String name;
  final String email;
  final String password;
  final String role; // 'cashier' | 'stockManager'
  const AddEmployeeEvent({
    required this.shopId,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
  @override
  List<Object?> get props => [shopId, name, email, role];
}

class DeleteEmployeeEvent extends UserManagementEvent {
  final String userId;
  const DeleteEmployeeEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

// ── State ─────────────────────────────────────────────────────

enum UserMgmtStatus { initial, loading, success, error }

class UserManagementState extends Equatable {
  final List<Map<String, dynamic>> members;
  final UserMgmtStatus status;
  final String? message;

  const UserManagementState({
    this.members = const [],
    this.status  = UserMgmtStatus.initial,
    this.message,
  });

  UserManagementState copyWith({
    List<Map<String, dynamic>>? members,
    UserMgmtStatus? status,
    String? message,
  }) =>
      UserManagementState(
        members: members ?? this.members,
        status:  status  ?? this.status,
        message: message,
      );

  @override
  List<Object?> get props => [members, status, message];
}

// ── Bloc ──────────────────────────────────────────────────────

class UserManagementBloc
    extends Bloc<UserManagementEvent, UserManagementState> {
  final SupabaseAuthService authService;

  UserManagementBloc({required this.authService})
      : super(const UserManagementState()) {
    on<LoadUsersEvent>(_onLoad);
    on<AddEmployeeEvent>(_onAdd);
    on<DeleteEmployeeEvent>(_onDelete);
  }

  Future<void> _onLoad(
      LoadUsersEvent event, Emitter<UserManagementState> emit) async {
    emit(state.copyWith(status: UserMgmtStatus.loading));
    final members = await authService.getShopMembers(event.shopId);
    emit(state.copyWith(status: UserMgmtStatus.success, members: members));
  }

  Future<void> _onAdd(
      AddEmployeeEvent event, Emitter<UserManagementState> emit) async {
    emit(state.copyWith(status: UserMgmtStatus.loading));
    final error = await authService.createEmployee(
      shopId:   event.shopId,
      name:     event.name,
      email:    event.email,
      password: event.password,
      role:     event.role,
    );
    if (error != null) {
      emit(state.copyWith(status: UserMgmtStatus.error, message: error));
      return;
    }
    add(LoadUsersEvent(event.shopId));
  }

  Future<void> _onDelete(
      DeleteEmployeeEvent event, Emitter<UserManagementState> emit) async {
    final shopId = state.members.isNotEmpty
        ? state.members.first['shop_id'] as String
        : '';
    final error = await authService.deleteEmployee(event.userId, shopId);
    if (error != null) {
      emit(state.copyWith(status: UserMgmtStatus.error, message: error));
      return;
    }
    if (shopId.isNotEmpty) add(LoadUsersEvent(shopId));
  }
}
