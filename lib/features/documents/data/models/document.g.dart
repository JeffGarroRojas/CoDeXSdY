// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentAdapter extends TypeAdapter<Document> {
  @override
  final int typeId = 0;

  @override
  Document read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Document()
      ..odId = fields[0] as String
      ..title = fields[1] as String
      ..description = fields[2] as String?
      ..filePath = fields[3] as String
      ..extractedText = fields[4] as String
      ..createdAt = fields[5] as DateTime?
      ..updatedAt = fields[6] as DateTime?
      ..lastStudiedAt = fields[7] as DateTime?
      ..userId = fields[8] as String;
  }

  @override
  void write(BinaryWriter writer, Document obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.odId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.filePath)
      ..writeByte(4)
      ..write(obj.extractedText)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.lastStudiedAt)
      ..writeByte(8)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
