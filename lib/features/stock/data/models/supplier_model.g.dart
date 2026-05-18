// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SupplierModelAdapter extends TypeAdapter<SupplierModel> {
  @override
  final int typeId = 10;

  @override
  SupplierModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SupplierModel(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String?,
      address: fields[3] as String?,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SupplierModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
