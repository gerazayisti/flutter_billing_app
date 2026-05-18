import 'package:hive/hive.dart';
import '../../domain/entities/supplier.dart';

part 'supplier_model.g.dart';

@HiveType(typeId: 10)
class SupplierModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String? phone;
  @HiveField(3) String? address;
  @HiveField(4) String? notes;

  SupplierModel({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.notes,
  });

  factory SupplierModel.fromEntity(Supplier e) => SupplierModel(
        id: e.id,
        name: e.name,
        phone: e.phone,
        address: e.address,
        notes: e.notes,
      );

  Supplier toEntity() => Supplier(
        id: id,
        name: name,
        phone: phone,
        address: address,
        notes: notes,
      );
}
