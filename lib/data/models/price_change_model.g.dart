// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_change_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PriceChangeModelAdapter extends TypeAdapter<PriceChangeModel> {
  @override
  final int typeId = 1;

  @override
  PriceChangeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriceChangeModel(
      id: fields[0] as String,
      subscriptionId: fields[1] as String,
      oldPrice: fields[2] as double,
      newPrice: fields[3] as double,
      effectiveDate: fields[4] as DateTime,
      reason: fields[5] as String?,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PriceChangeModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subscriptionId)
      ..writeByte(2)
      ..write(obj.oldPrice)
      ..writeByte(3)
      ..write(obj.newPrice)
      ..writeByte(4)
      ..write(obj.effectiveDate)
      ..writeByte(5)
      ..write(obj.reason)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceChangeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
