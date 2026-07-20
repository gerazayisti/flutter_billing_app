// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'momo_transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MomoTransactionModelAdapter extends TypeAdapter<MomoTransactionModel> {
  @override
  final int typeId = 8;

  @override
  MomoTransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MomoTransactionModel(
      id: fields[0] as String,
      orderId: fields[1] as String?,
      operatorName: fields[2] as String,
      customerPhone: fields[3] as String,
      amount: fields[4] as double,
      statusName: fields[5] as String,
      reference: fields[6] as String?,
      externalId: fields[7] as String?,
      initiatedAt: fields[8] as DateTime,
      confirmedAt: fields[9] as DateTime?,
      errorMessage: fields[10] as String?,
      cashierId: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MomoTransactionModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.orderId)
      ..writeByte(2)
      ..write(obj.operatorName)
      ..writeByte(3)
      ..write(obj.customerPhone)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.statusName)
      ..writeByte(6)
      ..write(obj.reference)
      ..writeByte(7)
      ..write(obj.externalId)
      ..writeByte(8)
      ..write(obj.initiatedAt)
      ..writeByte(9)
      ..write(obj.confirmedAt)
      ..writeByte(10)
      ..write(obj.errorMessage)
      ..writeByte(11)
      ..write(obj.cashierId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MomoTransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
