import 'package:equatable/equatable.dart';

enum Role { admin, cashier }

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

  @override
  List<Object> get props => [id, name, pinCode, role];
}
