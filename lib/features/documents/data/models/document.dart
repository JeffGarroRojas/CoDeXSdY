import 'package:hive/hive.dart';

part 'document.g.dart';

@HiveType(typeId: 0)
class Document extends HiveObject {
  @HiveField(0)
  late String odId;

  @HiveField(1)
  late String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  late String filePath;

  @HiveField(4)
  late String extractedText;

  @HiveField(5)
  DateTime? createdAt;

  @HiveField(6)
  DateTime? updatedAt;

  @HiveField(7)
  DateTime? lastStudiedAt;

  @HiveField(8)
  late String userId;

  Document();

  Document.create({
    required this.odId,
    required this.title,
    this.description,
    required this.filePath,
    required this.extractedText,
    required this.userId,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() => {
    'odId': odId,
    'title': title,
    'description': description,
    'filePath': filePath,
    'extractedText': extractedText,
    'userId': userId,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'lastStudiedAt': lastStudiedAt?.toIso8601String(),
  };

  factory Document.fromMap(Map<String, dynamic> map) {
    final doc = Document()
      ..odId = map['odId']
      ..title = map['title']
      ..description = map['description']
      ..filePath = map['filePath'] ?? ''
      ..extractedText = map['extractedText']
      ..userId = map['userId']
      ..createdAt = map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now()
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now()
      ..lastStudiedAt = map['lastStudiedAt'] != null
          ? DateTime.parse(map['lastStudiedAt'])
          : null;
    return doc;
  }
}
