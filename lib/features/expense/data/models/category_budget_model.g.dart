// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_budget_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryBudgetModelAdapter extends TypeAdapter<CategoryBudgetModel> {
  @override
  final int typeId = 4;

  @override
  CategoryBudgetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryBudgetModel()
      ..categoryName = fields[0] as String
      ..limitAmount = fields[1] as double
      ..month = fields[2] as int
      ..year = fields[3] as int;
  }

  @override
  void write(BinaryWriter writer, CategoryBudgetModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.categoryName)
      ..writeByte(1)
      ..write(obj.limitAmount)
      ..writeByte(2)
      ..write(obj.month)
      ..writeByte(3)
      ..write(obj.year);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryBudgetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
