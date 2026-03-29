// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_goal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavingsGoalModelAdapter extends TypeAdapter<SavingsGoalModel> {
  @override
  final int typeId = 3;

  @override
  SavingsGoalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingsGoalModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      targetAmount: fields[3] as double,
      currentAmount: fields[4] as double,
      category: fields[5] as String,
      priority: fields[6] as String,
      createdDateMs: fields[7] as int,
      deadlineDateMs: fields[8] as int?,
      isCompleted: fields[9] == null ? false : fields[9] as bool,
      completedDateMs: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SavingsGoalModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.targetAmount)
      ..writeByte(4)
      ..write(obj.currentAmount)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.createdDateMs)
      ..writeByte(8)
      ..write(obj.deadlineDateMs)
      ..writeByte(9)
      ..write(obj.isCompleted)
      ..writeByte(10)
      ..write(obj.completedDateMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsGoalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
