// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseModelAdapter extends TypeAdapter<ExpenseModel> {
  @override
  final int typeId = 0;

  @override
  ExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      categoryName: fields[2] as String,
      dateMs: fields[3] as int,
      note: fields[4] as String?,
      isIncome: fields[5] == null ? false : fields[5] as bool,
      receiptPath: fields[6] as String?,
      isCreditCard: fields[7] == null ? false : fields[7] as bool,
      isCreditCardSettled: fields[8] == null ? false : fields[8] as bool,
      creditCardPaidAmount: fields[9] == null ? 0.0 : fields[9] as double,
      isRecurring: fields[10] == null ? false : fields[10] as bool,
      recurrenceInterval: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.categoryName)
      ..writeByte(3)
      ..write(obj.dateMs)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.isIncome)
      ..writeByte(6)
      ..write(obj.receiptPath)
      ..writeByte(7)
      ..write(obj.isCreditCard)
      ..writeByte(8)
      ..write(obj.isCreditCardSettled)
      ..writeByte(9)
      ..write(obj.creditCardPaidAmount)
      ..writeByte(10)
      ..write(obj.isRecurring)
      ..writeByte(11)
      ..write(obj.recurrenceInterval);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
