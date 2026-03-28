import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 12)
class UserProfile extends HiveObject {
  @HiveField(0)
  late String odId;

  @HiveField(1)
  String? name;

  @HiveField(2)
  String? email;

  @HiveField(3)
  int totalStudyMinutes = 0;

  @HiveField(4)
  int totalCardsStudied = 0;

  @HiveField(5)
  int totalDocuments = 0;

  @HiveField(6)
  int currentStreak = 0;

  @HiveField(7)
  DateTime? lastStudyDate;

  @HiveField(8)
  int longestStreak = 0;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  late String userId;

  UserProfile() : createdAt = DateTime.now();

  UserProfile.create({
    required this.odId,
    this.name,
    this.email,
    required this.userId,
  }) : createdAt = DateTime.now();

  void updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastStudyDate == null) {
      currentStreak = 1;
    } else {
      final lastDate = DateTime(
        lastStudyDate!.year,
        lastStudyDate!.month,
        lastStudyDate!.day,
      );
      final difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        currentStreak++;
      } else if (difference > 1) {
        currentStreak = 1;
      }
    }

    lastStudyDate = now;
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }
  }

  Map<String, dynamic> toMap() => {
    'odId': odId,
    'name': name,
    'email': email,
    'totalStudyMinutes': totalStudyMinutes,
    'totalCardsStudied': totalCardsStudied,
    'totalDocuments': totalDocuments,
    'currentStreak': currentStreak,
    'lastStudyDate': lastStudyDate?.toIso8601String(),
    'longestStreak': longestStreak,
    'createdAt': createdAt.toIso8601String(),
    'userId': userId,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final profile = UserProfile()
      ..odId = map['odId']
      ..name = map['name']
      ..email = map['email']
      ..totalStudyMinutes = map['totalStudyMinutes'] ?? 0
      ..totalCardsStudied = map['totalCardsStudied'] ?? 0
      ..totalDocuments = map['totalDocuments'] ?? 0
      ..currentStreak = map['currentStreak'] ?? 0
      ..lastStudyDate = map['lastStudyDate'] != null
          ? DateTime.parse(map['lastStudyDate'])
          : null
      ..longestStreak = map['longestStreak'] ?? 0
      ..createdAt = map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now()
      ..userId = map['userId'];
    return profile;
  }
}
