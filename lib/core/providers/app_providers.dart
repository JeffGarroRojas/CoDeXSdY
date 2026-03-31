import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../services/ai_client.dart';
import '../services/sm2_algorithm.dart';
import '../../features/flashcards/data/models/flashcard.dart';
import '../../features/documents/data/models/user_profile.dart';
import '../../features/ai_assistant/data/models/chat_session.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final aiClientProvider = Provider<AIClient>((ref) {
  return AIClient();
});

final guestExpiryProvider = Provider<DateTime?>((ref) {
  final prefs = DatabaseService.instance.getUserPreferences('guest');
  if (prefs == null) return null;
  return prefs.guestSessionStart?.add(const Duration(days: 5));
});

final sm2AlgorithmProvider = Provider<SM2Algorithm>((ref) {
  return SM2Algorithm();
});

final currentUserIdProvider = StateProvider<String?>((ref) => null);

final userNameProvider = StateProvider<String>((ref) => 'Estudiante');

final flashcardsProvider = FutureProvider.family<List<Flashcard>, String>((
  ref,
  userId,
) async {
  final db = ref.read(databaseServiceProvider);
  return db.getFlashcards(userId);
});

final flashcardsNotifierProvider =
    StateNotifierProvider.family<
      FlashcardsNotifier,
      AsyncValue<List<Flashcard>>,
      String
    >((ref, userId) {
      final db = ref.read(databaseServiceProvider);
      return FlashcardsNotifier(db, userId);
    });

final dueFlashcardsProvider = FutureProvider.family<List<Flashcard>, String>((
  ref,
  userId,
) async {
  final db = ref.read(databaseServiceProvider);
  return db.getDueFlashcards(userId);
});

final profileProvider = FutureProvider.family<UserProfile?, String>((
  ref,
  userId,
) async {
  final db = ref.read(databaseServiceProvider);
  return db.getOrCreateProfile(userId);
});

class DocumentsNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final DatabaseService _db;
  final String userId;
  final Uuid _uuid = const Uuid();

  DocumentsNotifier(this._db, this.userId) : super(const AsyncValue.loading()) {
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    state = const AsyncValue.loading();
    try {
      final docs = _db.getDocuments(userId);
      state = AsyncValue.data(docs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<dynamic> addDocument({
    required String title,
    String? description,
    required String filePath,
    required String extractedText,
  }) async {
    final doc = await _db.createDocument(
      odId: _uuid.v4(),
      title: title,
      description: description,
      filePath: filePath,
      extractedText: extractedText,
      userId: userId,
    );
    await loadDocuments();
    return doc;
  }

  Future<void> deleteDocument(String odId) async {
    await _db.deleteDocument(odId);
    await loadDocuments();
  }
}

class FlashcardsNotifier extends StateNotifier<AsyncValue<List<Flashcard>>> {
  final DatabaseService _db;
  final String userId;

  FlashcardsNotifier(this._db, this.userId)
    : super(const AsyncValue.loading()) {
    loadFlashcards();
  }

  Future<void> loadFlashcards() async {
    state = const AsyncValue.loading();
    try {
      final cards = _db.getFlashcards(userId);
      state = AsyncValue.data(cards);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Flashcard> addFlashcard({
    String? documentId,
    required String front,
    required String back,
    List<String>? tags,
  }) async {
    final card = await _db.createFlashcard(
      documentId: documentId,
      front: front,
      back: back,
      tags: tags,
      userId: userId,
    );
    await loadFlashcards();
    return card;
  }

  Future<void> updateFlashcard(Flashcard card) async {
    await _db.updateFlashcard(card);
    await loadFlashcards();
  }

  Future<void> deleteFlashcard(String odId) async {
    await _db.deleteFlashcard(odId);
    await loadFlashcards();
  }

  Future<List<Flashcard>> saveFlashcardsFromText(String text) async {
    final parsed = _parseFlashcards(text);
    final saved = <Flashcard>[];
    for (final pair in parsed) {
      final card = await addFlashcard(
        front: pair['front']!,
        back: pair['back']!,
      );
      saved.add(card);
    }
    return saved;
  }

  List<Map<String, String>> _parseFlashcards(String text) {
    final results = <Map<String, String>>[];
    final patterns = [
      RegExp(
        r'Frente:\s*(.+?)\s*(?:Dorso:|Respuesta:|Back:)',
        dotAll: true,
        caseSensitive: false,
      ),
      RegExp(
        r'Pregunta:\s*(.+?)\s*(?:Respuesta:|Dorso:|Answer:)',
        dotAll: true,
        caseSensitive: false,
      ),
      RegExp(
        r'Q[;:]\s*(.+?)\s*A[;:]\s*(.+?)(?=\n\n|\n[A-Z]|$)',
        dotAll: true,
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final front = (match.group(1) ?? '').trim();
        String back;
        if (match.groupCount >= 2 && match.group(2) != null) {
          back = match.group(2)!;
        } else {
          final restOfMatch = text.substring(match.end).trim();
          final nextPattern = RegExp(r'^(.+?)(?=\n\n[DPS]|$)', dotAll: true);
          final nextMatch = nextPattern.firstMatch(restOfMatch);
          back =
              nextMatch?.group(1)?.trim() ??
              restOfMatch.split('\n').first.trim();
        }
        if (front.isNotEmpty && back.isNotEmpty) {
          results.add({'front': front, 'back': back});
        }
      }
    }

    return results;
  }
}

final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
      return ChatMessagesNotifier(ref);
    });

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromPersisted(persisted) {
    return ChatMessage(
      content: persisted.content,
      isUser: persisted.isUser,
      timestamp: persisted.timestamp,
    );
  }
}

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref _ref;
  static const String _currentChatId = 'default_chat';

  ChatMessagesNotifier(this._ref) : super([]) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final db = DatabaseService.instance;
      final persisted = db.getChatMessages(_currentChatId);
      state = persisted.map((p) => ChatMessage.fromPersisted(p)).toList();
    } catch (e) {
      debugPrint('Error loading chat messages: $e');
    }
  }

  Future<void> addMessage(String content, bool isUser) async {
    final message = ChatMessage(content: content, isUser: isUser);
    state = [...state, message];

    try {
      await DatabaseService.instance.saveChatMessage(
        odId: _currentChatId,
        content: content,
        isUser: isUser,
        userId: _ref.read(currentUserIdProvider) ?? 'anonymous',
      );
    } catch (e) {
      debugPrint('Error saving chat message: $e');
    }
  }

  Future<void> clear() async {
    state = [];
    try {
      await DatabaseService.instance.clearChatMessages(_currentChatId);
    } catch (e) {
      debugPrint('Error clearing chat messages: $e');
    }
  }

  void setMessages(List<ChatMessage> messages) {
    state = messages;
  }
}

final chatSessionsProvider =
    StateNotifierProvider<ChatSessionsNotifier, List<ChatSession>>((ref) {
      final userId = ref.watch(currentUserIdProvider) ?? 'anonymous';
      return ChatSessionsNotifier(ref, userId);
    });

class ChatSessionsNotifier extends StateNotifier<List<ChatSession>> {
  final Ref _ref;
  final String _userId;

  ChatSessionsNotifier(this._ref, this._userId) : super([]) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    try {
      final db = DatabaseService.instance;
      state = db.getChatSessions(_userId);
    } catch (e) {
      debugPrint('Error loading chat sessions: $e');
    }
  }

  Future<ChatSession> createSession({String? name, String? context}) async {
    final db = DatabaseService.instance;
    final session = await db.createChatSession(
      userId: _userId,
      name: name,
      context: context,
    );
    await loadSessions();
    return session;
  }

  Future<void> renameSession(String sessionId, String newName) async {
    final db = DatabaseService.instance;
    await db.renameChatSession(sessionId, newName);
    await loadSessions();
  }

  Future<void> deleteSession(String sessionId) async {
    final db = DatabaseService.instance;
    await db.deleteChatSession(sessionId);
    await loadSessions();
  }

  Future<void> addMessage(String sessionId, String content, bool isUser) async {
    final db = DatabaseService.instance;
    await db.addMessageToSession(sessionId, content, isUser);
    await loadSessions();
  }

  Future<void> updateSessionNameFromMessages(
    String sessionId,
    List<ChatMessage> messages,
  ) async {
    final db = DatabaseService.instance;
    final session = db.getChatSession(sessionId);
    if (session != null && session.name == 'Nueva conversación') {
      final newName = db.generateSessionName(
        messages
            .map(
              (m) => ChatMessageItem(
                id: 'temp',
                content: m.content,
                isUser: m.isUser,
                timestamp: m.timestamp,
              ),
            )
            .toList(),
      );
      await db.renameChatSession(sessionId, newName);
      await loadSessions();
    }
  }
}

final currentChatSessionProvider = StateProvider<ChatSession?>((ref) => null);
