// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_withdrawal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShopWithdrawalModelAdapter extends TypeAdapter<ShopWithdrawalModel> {
  @override
  final int typeId = 13;

  @override
  ShopWithdrawalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShopWithdrawalModel(
      payoutId: fields[0] as String,
      shopId: fields[1] as String,
      phoneNumber: fields[2] as String,
      provider: fields[3] as String,
      grossAmount: fields[4] as double,
      feeAmount: fields[5] as double,
      netAmount: fields[6] as double,
      statusName: fields[7] as String,
      failureCode: fields[8] as String?,
      failureMessage: fields[9] as String?,
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ShopWithdrawalModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.payoutId)
      ..writeByte(1)
      ..write(obj.shopId)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.provider)
      ..writeByte(4)
      ..write(obj.grossAmount)
      ..writeByte(5)
      ..write(obj.feeAmount)
      ..writeByte(6)
      ..write(obj.netAmount)
      ..writeByte(7)
      ..write(obj.statusName)
      ..writeByte(8)
      ..write(obj.failureCode)
      ..writeByte(9)
      ..write(obj.failureMessage)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopWithdrawalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
