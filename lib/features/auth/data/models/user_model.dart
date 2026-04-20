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
  final String pinCode;
  
  @override
  @HiveField(3)
  final Role role;

  const UserModel({
    required this.id,
    required this.name,
    required this.pinCode,
    required this.role,
  }) : super(id: id, name: name, pinCode: pinCode, role: role);
}

class RoleAdapter extends TypeAdapter<Role> {
  @override
  final int typeId = 7;

  @override
  Role read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Role.admin;
      case 1:
        return Role.cashier;
      default:
        return Role.cashier;
    }
  }

  @override
  void write(BinaryWriter writer, Role obj) {
    switch (obj) {
      case Role.admin:
        writer.writeByte(0);
        break;
      case Role.cashier:
        writer.writeByte(1);
        break;
    }
  }
}
