import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:billing_app/features/auth/data/models/user_model.dart';
import 'package:billing_app/core/data/hive_database.dart';

// Events
abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();
  @override
  List<Object?> get props => [];
}

class LoadUsersEvent extends UserManagementEvent {}

class AddUserEvent extends UserManagementEvent {
  final UserModel user;
  const AddUserEvent(this.user);
  @override
  List<Object?> get props => [user];
}

class UpdateUserEvent extends UserManagementEvent {
  final UserModel user;
  const UpdateUserEvent(this.user);
  @override
  List<Object?> get props => [user];
}

class DeleteUserEvent extends UserManagementEvent {
  final String userId;
  const DeleteUserEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

// States
enum UserManagementStatus { initial, loading, success, error }

class UserManagementState extends Equatable {
  final List<UserModel> users;
  final UserManagementStatus status;
  final String? message;

  const UserManagementState({
    this.users = const [],
    this.status = UserManagementStatus.initial,
    this.message,
  });

  UserManagementState copyWith({
    List<UserModel>? users,
    UserManagementStatus? status,
    String? message,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      status: status ?? this.status,
      message: message,
    );
  }

  @override
  List<Object?> get props => [users, status, message];
}

// Bloc
class UserManagementBloc extends Bloc<UserManagementEvent, UserManagementState> {
  UserManagementBloc() : super(const UserManagementState()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<AddUserEvent>(_onAddUser);
    on<UpdateUserEvent>(_onUpdateUser);
    on<DeleteUserEvent>(_onDeleteUser);
  }

  void _onLoadUsers(LoadUsersEvent event, Emitter<UserManagementState> emit) {
    emit(state.copyWith(status: UserManagementStatus.loading));
    final users = HiveDatabase.usersBox.values.toList();
    emit(state.copyWith(status: UserManagementStatus.success, users: users));
  }

  Future<void> _onAddUser(AddUserEvent event, Emitter<UserManagementState> emit) async {
    await HiveDatabase.usersBox.put(event.user.id, event.user);
    add(LoadUsersEvent());
  }

  Future<void> _onUpdateUser(UpdateUserEvent event, Emitter<UserManagementState> emit) async {
    await HiveDatabase.usersBox.put(event.user.id, event.user);
    add(LoadUsersEvent());
  }

  Future<void> _onDeleteUser(DeleteUserEvent event, Emitter<UserManagementState> emit) async {
    await HiveDatabase.usersBox.delete(event.userId);
    add(LoadUsersEvent());
  }
}
