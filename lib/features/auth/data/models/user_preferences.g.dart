// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 3;

  @override
  UserPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferences()
      ..odId = fields[0] as String
      ..userId = fields[1] as String
      ..name = fields[2] as String?
      ..studyLevel = fields[3] as String?
      ..subjects = (fields[4] as List).cast<String>()
      ..studyGoal = fields[5] as String?
      ..preferredStudyTime = fields[6] as String?
      ..dailyStudyMinutes = fields[7] as int?
      ..learningStyle = fields[8] as String?
      ..onboardingCompleted = fields[9] as bool
      ..createdAt = fields[10] as DateTime
      ..updatedAt = fields[11] as DateTime;
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.odId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.studyLevel)
      ..writeByte(4)
      ..write(obj.subjects)
      ..writeByte(5)
      ..write(obj.studyGoal)
      ..writeByte(6)
      ..write(obj.preferredStudyTime)
      ..writeByte(7)
      ..write(obj.dailyStudyMinutes)
      ..writeByte(8)
      ..write(obj.learningStyle)
      ..writeByte(9)
      ..write(obj.onboardingCompleted)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
