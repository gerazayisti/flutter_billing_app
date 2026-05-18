// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_register_closure_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CashRegisterClosureModelAdapter
    extends TypeAdapter<CashRegisterClosureModel> {
  @override
  final int typeId = 11;

  @override
  CashRegisterClosureModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CashRegisterClosureModel(
      id: fields[0] as String,
      closedAt: fields[1] as DateTime,
      periodStart: fields[2] as DateTime,
      cashierId: fields[3] as String,
      cashTotal: fields[4] as double,
      orangeMoneyTotal: fields[5] as double,
      mtnMomoTotal: fields[6] as double,
      cardTotal: fields[7] as double,
      grandTotal: fields[8] as double,
      transactionCount: fields[9] as int,
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CashRegisterClosureModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.closedAt)
      ..writeByte(2)
      ..write(obj.periodStart)
      ..writeByte(3)
      ..write(obj.cashierId)
      ..writeByte(4)
      ..write(obj.cashTotal)
      ..writeByte(5)
      ..write(obj.orangeMoneyTotal)
      ..writeByte(6)
      ..write(obj.mtnMomoTotal)
      ..writeByte(7)
      ..write(obj.cardTotal)
      ..writeByte(8)
      ..write(obj.grandTotal)
      ..writeByte(9)
      ..write(obj.transactionCount)
      ..writeByte(10)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashRegisterClosureModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
