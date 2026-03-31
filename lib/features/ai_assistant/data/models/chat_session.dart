import 'package:hive/hive.dart';

part 'chat_session.g.dart';

@HiveType(typeId: 13)
class ChatSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final List<ChatMessageItem> messages;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  final String userId;

  @HiveField(6)
  final String? context;

  @HiveField(7)
  int messageCount;

  ChatSession({
    required this.id,
    required this.name,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.context,
    this.messageCount = 0,
  });

  ChatSession copyWith({
    String? id,
    String? name,
    List<ChatMessageItem>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? context,
    int? messageCount,
  }) {
    return ChatSession(
      id: id ?? this.id,
      name: name ?? this.name,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      context: context ?? this.context,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  String get preview {
    if (messages.isEmpty) return 'Sin mensajes';
    final lastMessage = messages.last;
    final content = lastMessage.content;
    if (content.length > 60) {
      return '${content.substring(0, 60)}...';
    }
    return content;
  }
}

@HiveType(typeId: 14)
class ChatMessageItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final bool isUser;

  @HiveField(3)
  final DateTime timestamp;

  ChatMessageItem({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}
