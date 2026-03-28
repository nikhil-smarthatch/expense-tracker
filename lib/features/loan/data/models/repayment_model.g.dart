// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repayment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RepaymentModelAdapter extends TypeAdapter<RepaymentModel> {
  @override
  final int typeId = 2;

  @override
  RepaymentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RepaymentModel(
      id: fields[0] as String,
      loanId: fields[1] as String,
      amount: fields[2] as double,
      dateMs: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RepaymentModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.loanId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.dateMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepaymentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
