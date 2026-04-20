// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'held_order_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HeldOrderModelAdapter extends TypeAdapter<HeldOrderModel> {
  @override
  final int typeId = 5;

  @override
  HeldOrderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HeldOrderModel(
      id: fields[0] as String,
      savedAt: fields[1] as DateTime,
      items: (fields[2] as List).cast<HeldCartItemModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, HeldOrderModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.savedAt)
      ..writeByte(2)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeldOrderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HeldCartItemModelAdapter extends TypeAdapter<HeldCartItemModel> {
  @override
  final int typeId = 6;

  @override
  HeldCartItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HeldCartItemModel(
      product: fields[0] as ProductModel,
      quantity: fields[1] as int,
      selectedVariant: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HeldCartItemModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.product)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.selectedVariant);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeldCartItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
