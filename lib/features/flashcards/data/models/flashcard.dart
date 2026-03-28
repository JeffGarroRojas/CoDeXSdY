import 'package:hive/hive.dart';

part 'flashcard.g.dart';

@HiveType(typeId: 1)
class Flashcard extends HiveObject {
  @HiveField(0)
  late String odId;

  @HiveField(1)
  String? documentId;

  @HiveField(2)
  late String front;

  @HiveField(3)
  late String back;

  @HiveField(4)
  List<String> tags = [];

  @HiveField(5)
  double easeFactor = 2.5;

  @HiveField(6)
  int interval = 0;

  @HiveField(7)
  int repetitions = 0;

  @HiveField(8)
  DateTime? nextReview;

  @HiveField(9)
  late DateTime createdAt;

  @HiveField(10)
  late DateTime updatedAt;

  @HiveField(11)
  DateTime? lastReviewedAt;

  @HiveField(12)
  int statusIndex = 0;

  @HiveField(13)
  late String userId;

  FlashcardStatus get status => FlashcardStatus.values[statusIndex];
  set status(FlashcardStatus value) => statusIndex = value.index;

  Flashcard() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    nextReview = DateTime.now();
  }

  Flashcard.create({
    required this.odId,
    this.documentId,
    required this.front,
    required this.back,
    List<String>? tags,
    double? easeFactor,
    int? interval,
    int? repetitions,
    DateTime? nextReview,
    required this.userId,
  }) : tags = tags ?? [],
       easeFactor = easeFactor ?? 2.5,
       interval = interval ?? 0,
       repetitions = repetitions ?? 0,
       nextReview = nextReview ?? DateTime.now(),
       createdAt = DateTime.now(),
       updatedAt = DateTime.now();

  Map<String, dynamic> toMap() => {
    'odId': odId,
    'documentId': documentId,
    'front': front,
    'back': back,
    'tags': tags,
    'easeFactor': easeFactor,
    'interval': interval,
    'repetitions': repetitions,
    'nextReview': nextReview?.toIso8601String(),
    'statusIndex': statusIndex,
    'userId': userId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastReviewedAt': lastReviewedAt?.toIso8601String(),
  };

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    final card = Flashcard()
      ..odId = map['odId']
      ..documentId = map['documentId']
      ..front = map['front']
      ..back = map['back']
      ..tags = List<String>.from(map['tags'] ?? [])
      ..easeFactor = (map['easeFactor'] ?? 2.5).toDouble()
      ..interval = map['interval'] ?? 0
      ..repetitions = map['repetitions'] ?? 0
      ..nextReview = map['nextReview'] != null
          ? DateTime.parse(map['nextReview'])
          : DateTime.now()
      ..statusIndex = map['statusIndex'] ?? 0
      ..userId = map['userId']
      ..createdAt = map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now()
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now()
      ..lastReviewedAt = map['lastReviewedAt'] != null
          ? DateTime.parse(map['lastReviewedAt'])
          : null;
    return card;
  }
}

@HiveType(typeId: 2)
enum FlashcardStatus {
  @HiveField(0)
  newCard,
  @HiveField(1)
  learning,
  @HiveField(2)
  review,
  @HiveField(3)
  mastered,
}
