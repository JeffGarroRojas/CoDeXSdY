import 'package:hive/hive.dart';

part 'user_preferences.g.dart';

@HiveType(typeId: 3)
class UserPreferences extends HiveObject {
  @HiveField(0)
  late String odId;

  @HiveField(1)
  late String userId;

  @HiveField(2)
  String? name;

  @HiveField(3)
  String? studyLevel;

  @HiveField(4)
  List<String> subjects = [];

  @HiveField(5)
  String? studyGoal;

  @HiveField(6)
  String? preferredStudyTime;

  @HiveField(7)
  int? dailyStudyMinutes;

  @HiveField(8)
  String? learningStyle;

  @HiveField(9)
  bool onboardingCompleted = false;

  @HiveField(10)
  late DateTime createdAt;

  @HiveField(11)
  late DateTime updatedAt;

  @HiveField(12)
  bool isGuest = false;

  @HiveField(13)
  DateTime? guestSessionStart;

  UserPreferences() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  UserPreferences.create({
    required this.odId,
    required this.userId,
    this.name,
    this.studyLevel,
    List<String>? subjects,
    this.studyGoal,
    this.preferredStudyTime,
    this.dailyStudyMinutes,
    this.learningStyle,
    this.onboardingCompleted = false,
    this.isGuest = false,
    this.guestSessionStart,
  }) : subjects = subjects ?? [],
       createdAt = DateTime.now(),
       updatedAt = DateTime.now();

  bool get isGuestSessionExpired {
    if (!isGuest || guestSessionStart == null) return false;
    final daysSinceStart = DateTime.now().difference(guestSessionStart!).inDays;
    return daysSinceStart >= 5;
  }

  int get guestDaysRemaining {
    if (!isGuest || guestSessionStart == null) return 5;
    final daysSinceStart = DateTime.now().difference(guestSessionStart!).inDays;
    return (5 - daysSinceStart).clamp(0, 5);
  }

  void startGuestSession() {
    isGuest = true;
    guestSessionStart = DateTime.now();
    updatedAt = DateTime.now();
  }

  void convertToFullAccount() {
    isGuest = false;
    guestSessionStart = null;
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() => {
    'odId': odId,
    'userId': userId,
    'name': name,
    'studyLevel': studyLevel,
    'subjects': subjects,
    'studyGoal': studyGoal,
    'preferredStudyTime': preferredStudyTime,
    'dailyStudyMinutes': dailyStudyMinutes,
    'learningStyle': learningStyle,
    'onboardingCompleted': onboardingCompleted,
    'isGuest': isGuest,
    'guestSessionStart': guestSessionStart?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    final prefs = UserPreferences()
      ..odId = map['odId']
      ..userId = map['userId']
      ..name = map['name']
      ..studyLevel = map['studyLevel']
      ..subjects = List<String>.from(map['subjects'] ?? [])
      ..studyGoal = map['studyGoal']
      ..preferredStudyTime = map['preferredStudyTime']
      ..dailyStudyMinutes = map['dailyStudyMinutes']
      ..learningStyle = map['learningStyle']
      ..onboardingCompleted = map['onboardingCompleted'] ?? false
      ..isGuest = map['isGuest'] ?? false
      ..guestSessionStart = map['guestSessionStart'] != null
          ? DateTime.parse(map['guestSessionStart'])
          : null
      ..createdAt = map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now()
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now();
    return prefs;
  }

  String getContextForAI() {
    final buffer = StringBuffer();
    buffer.writeln('Información del estudiante:');
    if (name != null) buffer.writeln('- Nombre: $name');
    if (studyLevel != null) buffer.writeln('- Nivel: $studyLevel');
    if (subjects.isNotEmpty)
      buffer.writeln('- Materias: ${subjects.join(", ")}');
    if (studyGoal != null) buffer.writeln('- Objetivo: $studyGoal');
    if (preferredStudyTime != null)
      buffer.writeln('- Horario preferido: $preferredStudyTime');
    if (dailyStudyMinutes != null)
      buffer.writeln('- Tiempo diario: $dailyStudyMinutes minutos');
    if (learningStyle != null)
      buffer.writeln('- Estilo de aprendizaje: $learningStyle');
    if (isGuest) {
      buffer.writeln('- Modo Guest: Sí');
      buffer.writeln('- Días restantes: $guestDaysRemaining');
    }
    return buffer.toString();
  }
}
