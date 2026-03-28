// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionAdapter extends TypeAdapter<Question> {
  @override
  final int typeId = 10;

  @override
  Question read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Question()
      ..odId = fields[0] as String
      ..question = fields[1] as String
      ..options = (fields[2] as List).cast<String>()
      ..correctAnswerIndex = fields[3] as int
      ..explanation = fields[4] as String
      ..categoryIndex = fields[5] as int
      ..levelIndex = fields[6] as int
      ..topic = fields[7] as String
      ..source = fields[8] as String
      ..createdAt = fields[9] as DateTime;
  }

  @override
  void write(BinaryWriter writer, Question obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.odId)
      ..writeByte(1)
      ..write(obj.question)
      ..writeByte(2)
      ..write(obj.options)
      ..writeByte(3)
      ..write(obj.correctAnswerIndex)
      ..writeByte(4)
      ..write(obj.explanation)
      ..writeByte(5)
      ..write(obj.categoryIndex)
      ..writeByte(6)
      ..write(obj.levelIndex)
      ..writeByte(7)
      ..write(obj.topic)
      ..writeByte(8)
      ..write(obj.source)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuizResultAdapter extends TypeAdapter<QuizResult> {
  @override
  final int typeId = 11;

  @override
  QuizResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizResult()
      ..odId = fields[0] as String
      ..userId = fields[1] as String
      ..totalQuestions = fields[2] as int
      ..correctAnswers = fields[3] as int
      ..levelIndex = fields[4] as int
      ..categoryIndex = fields[5] as int
      ..durationSeconds = fields[6] as int
      ..completedAt = fields[7] as DateTime
      ..userAnswers = (fields[8] as List).cast<int>();
  }

  @override
  void write(BinaryWriter writer, QuizResult obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.odId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.totalQuestions)
      ..writeByte(3)
      ..write(obj.correctAnswers)
      ..writeByte(4)
      ..write(obj.levelIndex)
      ..writeByte(5)
      ..write(obj.categoryIndex)
      ..writeByte(6)
      ..write(obj.durationSeconds)
      ..writeByte(7)
      ..write(obj.completedAt)
      ..writeByte(8)
      ..write(obj.userAnswers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
