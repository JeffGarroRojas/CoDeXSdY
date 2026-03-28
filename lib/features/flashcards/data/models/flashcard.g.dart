// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FlashcardAdapter extends TypeAdapter<Flashcard> {
  @override
  final int typeId = 1;

  @override
  Flashcard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Flashcard()
      ..odId = fields[0] as String
      ..documentId = fields[1] as String?
      ..front = fields[2] as String
      ..back = fields[3] as String
      ..tags = (fields[4] as List).cast<String>()
      ..easeFactor = fields[5] as double
      ..interval = fields[6] as int
      ..repetitions = fields[7] as int
      ..nextReview = fields[8] as DateTime?
      ..createdAt = fields[9] as DateTime
      ..updatedAt = fields[10] as DateTime
      ..lastReviewedAt = fields[11] as DateTime?
      ..statusIndex = fields[12] as int
      ..userId = fields[13] as String;
  }

  @override
  void write(BinaryWriter writer, Flashcard obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.odId)
      ..writeByte(1)
      ..write(obj.documentId)
      ..writeByte(2)
      ..write(obj.front)
      ..writeByte(3)
      ..write(obj.back)
      ..writeByte(4)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.easeFactor)
      ..writeByte(6)
      ..write(obj.interval)
      ..writeByte(7)
      ..write(obj.repetitions)
      ..writeByte(8)
      ..write(obj.nextReview)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.lastReviewedAt)
      ..writeByte(12)
      ..write(obj.statusIndex)
      ..writeByte(13)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashcardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FlashcardStatusAdapter extends TypeAdapter<FlashcardStatus> {
  @override
  final int typeId = 2;

  @override
  FlashcardStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FlashcardStatus.newCard;
      case 1:
        return FlashcardStatus.learning;
      case 2:
        return FlashcardStatus.review;
      case 3:
        return FlashcardStatus.mastered;
      default:
        return FlashcardStatus.newCard;
    }
  }

  @override
  void write(BinaryWriter writer, FlashcardStatus obj) {
    switch (obj) {
      case FlashcardStatus.newCard:
        writer.writeByte(0);
        break;
      case FlashcardStatus.learning:
        writer.writeByte(1);
        break;
      case FlashcardStatus.review:
        writer.writeByte(2);
        break;
      case FlashcardStatus.mastered:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashcardStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
