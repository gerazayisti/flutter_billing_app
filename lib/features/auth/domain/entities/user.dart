import 'package:equatable/equatable.dart';

enum Role {
  owner,
  cashier,
  stockManager;

  static Role fromString(String s) => switch (s) {
        'owner'        => Role.owner,
        'stockManager' => Role.stockManager,
        _              => Role.cashier,
      };

  String get value => switch (this) {
        Role.owner        => 'owner',
        Role.cashier      => 'cashier',
        Role.stockManager => 'stockManager',
      };
}

class User extends Equatable {
  final String id;      // Supabase UUID
  final String name;
  final String email;
  final Role role;
  final String shopId;  // which boutique this user belongs to

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.shopId,
  });

  bool get isOwner        => role == Role.owner;
  bool get isCashier      => role == Role.cashier;
  bool get isStockManager => role == Role.stockManager;

  bool get canAccessPOS        => role == Role.owner || role == Role.cashier;
  bool get canAccessInventory  => role == Role.owner || role == Role.stockManager;
  bool get canAccessDashboard  => role == Role.owner;
  bool get canAccessSettings   => role == Role.owner || role == Role.cashier;
  bool get canManageUsers      => role == Role.owner;

  @override
  List<Object> get props => [id, name, email, role, shopId];
}
