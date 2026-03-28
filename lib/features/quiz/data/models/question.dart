import 'package:hive/hive.dart';

part 'question.g.dart';

enum QuestionCategory {
  matematicas,
  ciencias,
  estudiosSociales,
  espanol,
  ingles,
  biologia,
  quimica,
  fisica,
  historia,
  geografia,
  civica,
  filosofia,
  comedia,
}

enum QuestionLevel {
  decimo, // 10°
  undecimo, // 11°
  duoddecimo, // 12°
}

@HiveType(typeId: 10)
class Question extends HiveObject {
  @HiveField(0)
  late String odId;

  @HiveField(1)
  late String question;

  @HiveField(2)
  late List<String> options;

  @HiveField(3)
  late int correctAnswerIndex;

  @HiveField(4)
  late String explanation;

  @HiveField(5)
  late int categoryIndex;

  @HiveField(6)
  late int levelIndex;

  @HiveField(7)
  late String topic;

  @HiveField(8)
  late String source; // MEP,UNI,UCR,etc

  @HiveField(9)
  late DateTime createdAt;

  Question();

  Question.create({
    required this.odId,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.categoryIndex,
    required this.levelIndex,
    required this.topic,
    this.source = 'MEP',
  }) : createdAt = DateTime.now();

  QuestionCategory get category => QuestionCategory.values[categoryIndex];
  QuestionLevel get level => QuestionLevel.values[levelIndex];

  bool isCorrect(int selectedIndex) => selectedIndex == correctAnswerIndex;

  String get correctAnswer => options[correctAnswerIndex];

  Map<String, dynamic> toMap() => {
    'odId': odId,
    'question': question,
    'options': options,
    'correctAnswerIndex': correctAnswerIndex,
    'explanation': explanation,
    'categoryIndex': categoryIndex,
    'levelIndex': levelIndex,
    'topic': topic,
    'source': source,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question()
      ..odId = map['odId']
      ..question = map['question']
      ..options = List<String>.from(map['options'])
      ..correctAnswerIndex = map['correctAnswerIndex']
      ..explanation = map['explanation']
      ..categoryIndex = map['categoryIndex']
      ..levelIndex = map['levelIndex']
      ..topic = map['topic']
      ..source = map['source'] ?? 'MEP'
      ..createdAt = map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now();
  }
}

@HiveType(typeId: 11)
class QuizResult extends HiveObject {
  @HiveField(0)
  late String odId;

  @HiveField(1)
  late String userId;

  @HiveField(2)
  late int totalQuestions;

  @HiveField(3)
  late int correctAnswers;

  @HiveField(4)
  late int levelIndex;

  @HiveField(5)
  late int categoryIndex;

  @HiveField(6)
  late int durationSeconds;

  @HiveField(7)
  late DateTime completedAt;

  @HiveField(8)
  late List<int> userAnswers;

  QuizResult();

  QuizResult.create({
    required this.odId,
    required this.userId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.levelIndex,
    required this.categoryIndex,
    required this.durationSeconds,
    required this.userAnswers,
  }) : completedAt = DateTime.now();

  double get percentage => (correctAnswers / totalQuestions) * 100;

  bool get passed => percentage >= 70;

  Map<String, dynamic> toMap() => {
    'odId': odId,
    'userId': userId,
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
    'levelIndex': levelIndex,
    'categoryIndex': categoryIndex,
    'durationSeconds': durationSeconds,
    'completedAt': completedAt.toIso8601String(),
    'userAnswers': userAnswers,
  };

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult()
      ..odId = map['odId']
      ..userId = map['userId']
      ..totalQuestions = map['totalQuestions']
      ..correctAnswers = map['correctAnswers']
      ..levelIndex = map['levelIndex']
      ..categoryIndex = map['categoryIndex']
      ..durationSeconds = map['durationSeconds']
      ..completedAt = DateTime.parse(map['completedAt'])
      ..userAnswers = List<int>.from(map['userAnswers']);
  }
}
