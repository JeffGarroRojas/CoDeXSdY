import 'package:hive/hive.dart';

part 'study_session.g.dart';

@HiveType(typeId: 3)
class StudySession extends HiveObject {
  @HiveField(0)
  late String odId;

  @HiveField(1)
  String? documentId;

  @HiveField(2)
  late DateTime startTime;

  @HiveField(3)
  DateTime? endTime;

  @HiveField(4)
  int cardsStudied = 0;

  @HiveField(5)
  int correctAnswers = 0;

  @HiveField(6)
  int incorrectAnswers = 0;

  @HiveField(7)
  double totalTimeMinutes = 0;

  @HiveField(8)
  late String userId;

  StudySession();

  StudySession.create({this.documentId, required this.userId}) {
    odId = DateTime.now().millisecondsSinceEpoch.toString();
    startTime = DateTime.now();
  }

  void complete() {
    endTime = DateTime.now();
    totalTimeMinutes = endTime!.difference(startTime).inSeconds / 60.0;
  }

  Map<String, dynamic> toMap() => {
    'odId': odId,
    'documentId': documentId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'cardsStudied': cardsStudied,
    'correctAnswers': correctAnswers,
    'incorrectAnswers': incorrectAnswers,
    'totalTimeMinutes': totalTimeMinutes,
    'userId': userId,
  };

  factory StudySession.fromMap(Map<String, dynamic> map) {
    final session = StudySession()
      ..odId = map['odId']
      ..documentId = map['documentId']
      ..startTime = DateTime.parse(map['startTime'])
      ..endTime = map['endTime'] != null ? DateTime.parse(map['endTime']) : null
      ..cardsStudied = map['cardsStudied'] ?? 0
      ..correctAnswers = map['correctAnswers'] ?? 0
      ..incorrectAnswers = map['incorrectAnswers'] ?? 0
      ..totalTimeMinutes = (map['totalTimeMinutes'] ?? 0).toDouble()
      ..userId = map['userId'];
    return session;
  }
}
