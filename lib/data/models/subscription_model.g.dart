// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionModelAdapter extends TypeAdapter<SubscriptionModel> {
  @override
  final int typeId = 0;

  @override
  SubscriptionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionModel(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      billingCycle: fields[3] as String,
      startDate: fields[4] as DateTime,
      renewalDate: fields[5] as DateTime,
      status: fields[6] as String,
      description: fields[7] as String?,
      website: fields[8] as String?,
      logoUrl: fields[9] as String?,
      customBillingDays: fields[10] as int?,
      category: fields[11] as String?,
      notificationsEnabled: fields[12] as bool,
      notificationDays: fields[13] as int,
      paymentHistory: (fields[14] as List?)?.cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.billingCycle)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.renewalDate)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.website)
      ..writeByte(9)
      ..write(obj.logoUrl)
      ..writeByte(10)
      ..write(obj.customBillingDays)
      ..writeByte(11)
      ..write(obj.category)
      ..writeByte(12)
      ..write(obj.notificationsEnabled)
      ..writeByte(13)
      ..write(obj.notificationDays)
      ..writeByte(14)
      ..write(obj.paymentHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
