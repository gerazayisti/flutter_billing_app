import 'package:equatable/equatable.dart';

enum Role { owner, cashier, stockManager }

class User extends Equatable {
  final String id;
  final String name;
  final String pinCode;
  final Role role;

  const User({
    required this.id,
    required this.name,
    required this.pinCode,
    required this.role,
  });

  bool get isOwner => role == Role.owner;
  bool get isCashier => role == Role.cashier;
  bool get isStockManager => role == Role.stockManager;

  /// Owner can access everything
  bool get canAccessPOS => role == Role.owner || role == Role.cashier;
  bool get canAccessInventory => role == Role.owner || role == Role.stockManager;
  bool get canAccessDashboard => role == Role.owner;
  bool get canAccessSettings => role == Role.owner;
  bool get canManageUsers => role == Role.owner;

  @override
  List<Object> get props => [id, name, pinCode, role];
}
