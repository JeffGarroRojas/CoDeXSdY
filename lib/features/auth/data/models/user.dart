import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 5)
class User extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String email;

  @HiveField(2)
  String? name;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  bool isAdmin = false;

  @HiveField(5)
  DateTime? lastLogin;

  User();

  User.create({
    required this.id,
    required this.email,
    this.name,
    this.isAdmin = false,
  }) : createdAt = DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'isAdmin': isAdmin,
    'lastLogin': lastLogin?.toIso8601String(),
  };

  factory User.fromMap(Map<String, dynamic> map) {
    final user = User()
      ..id = map['id']
      ..email = map['email']
      ..name = map['name']
      ..createdAt = map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now()
      ..isAdmin = map['isAdmin'] ?? false
      ..lastLogin = map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'])
          : null;
    return user;
  }
}
