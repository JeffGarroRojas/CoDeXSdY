// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudySessionAdapter extends TypeAdapter<StudySession> {
  @override
  final int typeId = 3;

  @override
  StudySession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudySession()
      ..odId = fields[0] as String
      ..documentId = fields[1] as String?
      ..startTime = fields[2] as DateTime
      ..endTime = fields[3] as DateTime?
      ..cardsStudied = fields[4] as int
      ..correctAnswers = fields[5] as int
      ..incorrectAnswers = fields[6] as int
      ..totalTimeMinutes = fields[7] as double
      ..userId = fields[8] as String;
  }

  @override
  void write(BinaryWriter writer, StudySession obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.odId)
      ..writeByte(1)
      ..write(obj.documentId)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.cardsStudied)
      ..writeByte(5)
      ..write(obj.correctAnswers)
      ..writeByte(6)
      ..write(obj.incorrectAnswers)
      ..writeByte(7)
      ..write(obj.totalTimeMinutes)
      ..writeByte(8)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudySessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
