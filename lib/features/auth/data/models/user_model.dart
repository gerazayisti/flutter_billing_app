import 'package:hive/hive.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@HiveType(typeId: 4)
class UserModel extends User {
  @override
  @HiveField(0)
  final String id;

  @override
  @HiveField(1)
  final String name;

  @override
  @HiveField(2)
  final String email;

  @override
  @HiveField(3)
  final Role role;

  @override
  @HiveField(4)
  final String shopId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.shopId,
  }) : super(id: id, name: name, email: email, role: role, shopId: shopId);
}

class RoleAdapter extends TypeAdapter<Role> {
  @override
  final int typeId = 7;

  @override
  Role read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Role.owner;
      case 1:
        return Role.cashier;
      case 2:
        return Role.stockManager;
      default:
        return Role.cashier;
    }
  }

  @override
  void write(BinaryWriter writer, Role obj) {
    switch (obj) {
      case Role.owner:
        writer.writeByte(0);
        break;
      case Role.cashier:
        writer.writeByte(1);
        break;
      case Role.stockManager:
        writer.writeByte(2);
        break;
    }
  }
}
