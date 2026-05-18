// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockMovementModelAdapter extends TypeAdapter<StockMovementModel> {
  @override
  final int typeId = 9;

  @override
  StockMovementModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockMovementModel(
      id: fields[0] as String,
      productId: fields[1] as String,
      productName: fields[2] as String,
      typeName: fields[3] as String,
      quantity: fields[4] as int,
      operatorId: fields[5] as String,
      date: fields[6] as DateTime,
      supplierId: fields[7] as String?,
      supplierName: fields[8] as String?,
      orderId: fields[9] as String?,
      note: fields[10] as String?,
      unitCost: fields[11] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, StockMovementModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.typeName)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.operatorId)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.supplierId)
      ..writeByte(8)
      ..write(obj.supplierName)
      ..writeByte(9)
      ..write(obj.orderId)
      ..writeByte(10)
      ..write(obj.note)
      ..writeByte(11)
      ..write(obj.unitCost);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovementModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
