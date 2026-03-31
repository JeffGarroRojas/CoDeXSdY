import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../features/documents/data/models/document.dart';
import '../../features/documents/data/models/study_session.dart';
import '../../features/documents/data/models/user_profile.dart';
import '../../features/flashcards/data/models/flashcard.dart';
import '../../features/auth/data/models/user_preferences.dart';
import '../../features/quiz/data/models/question.dart';
import '../../features/ai_assistant/data/models/chat_session.dart';

class ChatMessageModel {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String odId;

  ChatMessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.odId,
  });
}

class ChatMessageAdapter extends TypeAdapter<ChatMessageModel> {
  @override
  final int typeId = 4;

  @override
  ChatMessageModel read(BinaryReader reader) {
    return ChatMessageModel(
      id: reader.readString(),
      content: reader.readString(),
      isUser: reader.readBool(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      odId: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessageModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.content);
    writer.writeBool(obj.isUser);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeString(obj.odId);
  }
}

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  late Box<Document> _documentsBox;
  late Box<Flashcard> _flashcardsBox;
  late Box<StudySession> _sessionsBox;
  late Box<UserProfile> _profilesBox;
  late Box<UserPreferences> _preferencesBox;
  late Box _settingsBox;
  late Box<ChatMessageModel> _chatMessagesBox;
  late Box<QuizResult> _quizResultsBox;
  late Box<ChatSession> _chatSessionsBox;

  static const String _chatMessagesBoxName = 'chat_messages';

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DocumentAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FlashcardAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(FlashcardStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(UserPreferencesAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(QuizResultAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(ChatSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(ChatMessageItemAdapter());
    }

    _documentsBox = await Hive.openBox<Document>('documents');
    _flashcardsBox = await Hive.openBox<Flashcard>('flashcards');
    _sessionsBox = await Hive.openBox<StudySession>('sessions');
    _profilesBox = await Hive.openBox<UserProfile>('profiles');
    _preferencesBox = await Hive.openBox<UserPreferences>('preferences');
    _settingsBox = await Hive.openBox('settings');
    _chatMessagesBox = await Hive.openBox<ChatMessageModel>(
      _chatMessagesBoxName,
    );
    _chatSessionsBox = await Hive.openBox<ChatSession>('chat_sessions');
    _quizResultsBox = await Hive.openBox<QuizResult>('quiz_results');

    debugPrint('Database initialized with chat persistence');
  }

  // ==================== APP SETTINGS ====================

  static const String _introShownKey = 'introShown';
  static const String _currentUserIdKey = 'currentUserId';
  static const String _demoStartDateKey = 'demoStartDate';

  bool get isIntroShown =>
      _settingsBox.get(_introShownKey, defaultValue: false);

  Future<void> setIntroShown(bool value) async {
    await _settingsBox.put(_introShownKey, value);
  }

  String? getCurrentUserId() => _settingsBox.get(_currentUserIdKey);

  Future<void> setCurrentUserId(String userId) async {
    await _settingsBox.put(_currentUserIdKey, userId);
  }

  DateTime? getDemoStartDate() {
    final timestamp = _settingsBox.get(_demoStartDateKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> setDemoStartDate(DateTime date) async {
    await _settingsBox.put(_demoStartDateKey, date.millisecondsSinceEpoch);
  }

  Future<void> clearDemoData() async {
    await _settingsBox.delete(_currentUserIdKey);
    await _settingsBox.delete(_demoStartDateKey);
    await _documentsBox.clear();
    await _flashcardsBox.clear();
    await _sessionsBox.clear();
    await _profilesBox.clear();
    await _preferencesBox.clear();
    await _chatMessagesBox.clear();
  }

  // ==================== DOCUMENTS ====================

  Future<Document> createDocument({
    required String odId,
    required String title,
    String? description,
    required String filePath,
    required String extractedText,
    required String userId,
  }) async {
    final doc = Document.create(
      odId: odId,
      title: title,
      description: description,
      filePath: filePath,
      extractedText: extractedText,
      userId: userId,
    );

    await _documentsBox.put(odId, doc);
    return doc;
  }

  List<Document> getDocuments(String userId) =>
      _documentsBox.values.where((d) => d.userId == userId).toList();

  Future<void> deleteDocument(String odId) async {
    await _documentsBox.delete(odId);
    final cards = _flashcardsBox.values
        .where((f) => f.documentId == odId)
        .toList();
    for (final card in cards) {
      await _flashcardsBox.delete(card.odId);
    }
  }

  // ==================== FLASHCARDS ====================

  Future<Flashcard> createFlashcard({
    String? documentId,
    required String front,
    required String back,
    List<String>? tags,
    required String userId,
  }) async {
    final card = Flashcard.create(
      odId: DateTime.now().millisecondsSinceEpoch.toString(),
      documentId: documentId,
      front: front,
      back: back,
      tags: tags,
      userId: userId,
    );

    await _flashcardsBox.put(card.odId, card);
    return card;
  }

  List<Flashcard> getFlashcards(String userId) =>
      _flashcardsBox.values.where((f) => f.userId == userId).toList();

  List<Flashcard> getFlashcardsForDocument(String documentId) =>
      _flashcardsBox.values.where((f) => f.documentId == documentId).toList();

  List<Flashcard> getDueFlashcards(String userId) => _flashcardsBox.values
      .where(
        (f) =>
            f.userId == userId &&
            (f.nextReview == null || f.nextReview!.isBefore(DateTime.now())),
      )
      .toList();

  Future<void> updateFlashcard(Flashcard card) async {
    card.updatedAt = DateTime.now();
    await _flashcardsBox.put(card.odId, card);
  }

  Future<void> deleteFlashcard(String odId) async {
    await _flashcardsBox.delete(odId);
  }

  // ==================== SESSIONS ====================

  Future<StudySession> startSession({
    String? documentId,
    required String userId,
  }) async {
    final session = StudySession.create(documentId: documentId, userId: userId);
    await _sessionsBox.put(session.odId, session);
    return session;
  }

  Future<void> completeSession(StudySession session) async {
    session.complete();
    await _sessionsBox.put(session.odId, session);
  }

  List<StudySession> getSessions(String userId) =>
      _sessionsBox.values.where((s) => s.userId == userId).toList();

  // ==================== PROFILE ====================

  UserProfile? getProfile(String userId) =>
      _profilesBox.values.where((p) => p.userId == userId).firstOrNull;

  Future<UserProfile> getOrCreateProfile(String userId) async {
    var profile = getProfile(userId);
    if (profile == null) {
      profile = UserProfile.create(odId: userId, userId: userId);
      await _profilesBox.put(profile.odId, profile);
    }
    return profile;
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _profilesBox.put(profile.odId, profile);
  }

  // ==================== USER PREFERENCES ====================

  UserPreferences? getUserPreferences(String userId) =>
      _preferencesBox.values.where((p) => p.userId == userId).firstOrNull;

  Future<UserPreferences> getOrCreateUserPreferences(String userId) async {
    var prefs = getUserPreferences(userId);
    if (prefs == null) {
      prefs = UserPreferences.create(
        odId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
      );
      await _preferencesBox.put(prefs.odId, prefs);
    }
    return prefs;
  }

  Future<void> updateUserPreferences(UserPreferences prefs) async {
    prefs.updatedAt = DateTime.now();
    await _preferencesBox.put(prefs.odId, prefs);
  }

  // ==================== CHAT MESSAGES ====================

  Future<void> saveChatMessage({
    required String odId,
    required String content,
    required bool isUser,
    required String userId,
  }) async {
    final message = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: isUser,
      timestamp: DateTime.now(),
      odId: odId,
    );
    await _chatMessagesBox.put(message.id, message);
  }

  List<ChatMessageModel> getChatMessages(String odId) {
    return _chatMessagesBox.values.where((m) => m.odId == odId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> clearChatMessages(String odId) async {
    final messages = _chatMessagesBox.values
        .where((m) => m.odId == odId)
        .toList();
    for (final message in messages) {
      await _chatMessagesBox.delete(message.id);
    }
  }

  Future<void> clearAllChatMessages() async {
    await _chatMessagesBox.clear();
  }

  // ==================== UTILS ====================

  Future<void> clearUserData(String userId) async {
    final docs = getDocuments(userId);
    for (final doc in docs) {
      await deleteDocument(doc.odId);
    }
    final cards = getFlashcards(userId);
    for (final card in cards) {
      await deleteFlashcard(card.odId);
    }
    final sessions = getSessions(userId);
    for (final session in sessions) {
      await _sessionsBox.delete(session.odId);
    }
    final results = getQuizResults(userId);
    for (final result in results) {
      await _quizResultsBox.delete(result.odId);
    }
  }

  // ==================== QUIZ RESULTS ====================

  Future<void> saveQuizResult({
    required String odId,
    required String userId,
    required int totalQuestions,
    required int correctAnswers,
    required int levelIndex,
    required int categoryIndex,
    required int durationSeconds,
    required List<int> userAnswers,
  }) async {
    final result = QuizResult.create(
      odId: odId,
      userId: userId,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      levelIndex: levelIndex,
      categoryIndex: categoryIndex,
      durationSeconds: durationSeconds,
      userAnswers: userAnswers,
    );
    await _quizResultsBox.put(odId, result);
  }

  List<QuizResult> getQuizResults(String userId) {
    return _quizResultsBox.values.where((r) => r.userId == userId).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  List<QuizResult> getQuizResultsBySubject(String userId, int categoryIndex) {
    return _quizResultsBox.values
        .where((r) => r.userId == userId && r.categoryIndex == categoryIndex)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  Map<int, List<QuizResult>> getQuizResultsGroupedBySubject(String userId) {
    final results = getQuizResults(userId);
    final grouped = <int, List<QuizResult>>{};
    for (final result in results) {
      grouped.putIfAbsent(result.categoryIndex, () => []).add(result);
    }
    return grouped;
  }

  QuizResult? getQuizResult(String odId) {
    return _quizResultsBox.get(odId);
  }

  Future<void> deleteQuizResult(String odId) async {
    await _quizResultsBox.delete(odId);
  }

  Future<void> clearQuizResults(String userId) async {
    final results = getQuizResults(userId);
    for (final result in results) {
      await _quizResultsBox.delete(result.odId);
    }
  }

  int getTotalQuizzesTaken(String userId) {
    return _quizResultsBox.values.where((r) => r.userId == userId).length;
  }

  double getOverallPassRate(String userId) {
    final results = getQuizResults(userId);
    if (results.isEmpty) return 0;
    final passed = results.where((r) => r.passed).length;
    return (passed / results.length) * 100;
  }

  Future<void> setGuestSession(bool isGuest) async {
    await _settingsBox.put('isGuest', isGuest);
    if (isGuest) {
      await _settingsBox.put(
        'guestSessionStart',
        DateTime.now().toIso8601String(),
      );
    }
  }

  bool isGuestSession() {
    return _settingsBox.get('isGuest', defaultValue: false) as bool;
  }

  DateTime? getGuestSessionStart() {
    final startStr = _settingsBox.get('guestSessionStart') as String?;
    if (startStr == null) return null;
    return DateTime.parse(startStr);
  }

  int getGuestDaysRemaining() {
    final start = getGuestSessionStart();
    if (start == null) return 5;
    final daysSinceStart = DateTime.now().difference(start).inDays;
    return (5 - daysSinceStart).clamp(0, 5);
  }

  Future<void> clearGuestData() async {
    await _flashcardsBox.clear();
    await _documentsBox.clear();
    await _sessionsBox.clear();
    await _quizResultsBox.clear();
    await _settingsBox.put('isGuest', false);
    await _settingsBox.put('guestSessionStart', null);
  }

  String? getGuestUserId() {
    return _settingsBox.get('guestUserId') as String?;
  }

  Future<void> setGuestUserId(String guestId) async {
    await _settingsBox.put('guestUserId', guestId);
  }

  bool hasGuestData() {
    final guestId = getGuestUserId();
    if (guestId == null) return false;

    final documents = getDocuments(guestId);
    final flashcards = getFlashcards(guestId);
    final sessions = getSessions(guestId);
    final results = getQuizResults(guestId);

    return documents.isNotEmpty ||
        flashcards.isNotEmpty ||
        sessions.isNotEmpty ||
        results.isNotEmpty;
  }

  Future<void> migrateGuestDataToUser(String newUserId) async {
    final guestId = getGuestUserId();
    if (guestId == null) return;

    debugPrint('Migrating data from $guestId to $newUserId');

    final documents = getDocuments(guestId);
    for (final doc in documents) {
      final newDoc = Document.create(
        odId: 'migrated_${doc.odId}_${DateTime.now().millisecondsSinceEpoch}',
        title: doc.title,
        description: doc.description,
        filePath: doc.filePath,
        extractedText: doc.extractedText,
        userId: newUserId,
      );
      await _documentsBox.put(newDoc.odId, newDoc);
    }

    final flashcards = getFlashcards(guestId);
    for (final card in flashcards) {
      final newCard = Flashcard.create(
        odId: 'migrated_${card.odId}_${DateTime.now().millisecondsSinceEpoch}',
        front: card.front,
        back: card.back,
        userId: newUserId,
        tags: card.tags,
      );
      await _flashcardsBox.put(newCard.odId, newCard);
    }

    final sessions = getSessions(guestId);
    for (final session in sessions) {
      final newSession = StudySession.create(
        documentId: session.documentId,
        userId: newUserId,
      );
      newSession.odId =
          'migrated_${session.odId}_${DateTime.now().millisecondsSinceEpoch}';
      newSession.startTime = session.startTime;
      newSession.endTime = session.endTime;
      newSession.cardsStudied = session.cardsStudied;
      newSession.correctAnswers = session.correctAnswers;
      newSession.incorrectAnswers = session.incorrectAnswers;
      newSession.totalTimeMinutes = session.totalTimeMinutes;
      await _sessionsBox.put(newSession.odId, newSession);
    }

    final results = getQuizResults(guestId);
    for (final result in results) {
      final newResult = QuizResult.create(
        odId:
            'migrated_${result.odId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: newUserId,
        totalQuestions: result.totalQuestions,
        correctAnswers: result.correctAnswers,
        levelIndex: result.levelIndex,
        categoryIndex: result.categoryIndex,
        durationSeconds: result.durationSeconds,
        userAnswers: result.userAnswers,
      );
      await _quizResultsBox.put(newResult.odId, newResult);
    }

    await _settingsBox.delete('guestUserId');
    await _settingsBox.put('isGuest', false);

    debugPrint('Migration completed successfully');
  }

  Future<void> clearOnlyGuestData() async {
    final guestId = getGuestUserId();
    if (guestId == null) return;

    final docKeys = _documentsBox.keys.where((k) {
      final doc = _documentsBox.get(k);
      return doc?.userId == guestId;
    }).toList();
    for (final key in docKeys) {
      await _documentsBox.delete(key);
    }

    final cardKeys = _flashcardsBox.keys.where((k) {
      final card = _flashcardsBox.get(k);
      return card?.userId == guestId;
    }).toList();
    for (final key in cardKeys) {
      await _flashcardsBox.delete(key);
    }

    final sessionKeys = _sessionsBox.keys.where((k) {
      final session = _sessionsBox.get(k);
      return session?.userId == guestId;
    }).toList();
    for (final key in sessionKeys) {
      await _sessionsBox.delete(key);
    }

    final resultKeys = _quizResultsBox.keys.where((k) {
      final result = _quizResultsBox.get(k);
      return result?.userId == guestId;
    }).toList();
    for (final key in resultKeys) {
      await _quizResultsBox.delete(key);
    }

    await _settingsBox.delete('guestUserId');
  }

  // ==================== CHAT SESSIONS ====================

  Future<ChatSession> createChatSession({
    required String userId,
    String? name,
    String? context,
  }) async {
    final id = 'chat_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final session = ChatSession(
      id: id,
      name: name ?? 'Nueva conversación',
      messages: [],
      createdAt: now,
      updatedAt: now,
      userId: userId,
      context: context,
      messageCount: 0,
    );

    await _chatSessionsBox.put(id, session);
    return session;
  }

  List<ChatSession> getChatSessions(String userId) {
    final sessions = _chatSessionsBox.values
        .where((s) => s.userId == userId)
        .toList();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  ChatSession? getChatSession(String sessionId) {
    return _chatSessionsBox.get(sessionId);
  }

  Future<void> updateChatSession(ChatSession session) async {
    session.updatedAt = DateTime.now();
    await _chatSessionsBox.put(session.id, session);
  }

  Future<void> renameChatSession(String sessionId, String newName) async {
    final session = _chatSessionsBox.get(sessionId);
    if (session != null) {
      session.name = newName;
      session.updatedAt = DateTime.now();
      await _chatSessionsBox.put(sessionId, session);
    }
  }

  Future<void> addMessageToSession(
    String sessionId,
    String content,
    bool isUser,
  ) async {
    final session = _chatSessionsBox.get(sessionId);
    if (session != null) {
      final message = ChatMessageItem(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        isUser: isUser,
        timestamp: DateTime.now(),
      );
      session.messages.add(message);
      session.messageCount = session.messages.length;
      session.updatedAt = DateTime.now();
      await _chatSessionsBox.put(sessionId, session);
    }
  }

  Future<void> deleteChatSession(String sessionId) async {
    await _chatSessionsBox.delete(sessionId);
  }

  Future<void> deleteAllChatSessions(String userId) async {
    final keysToDelete = _chatSessionsBox.keys.where((key) {
      final session = _chatSessionsBox.get(key);
      return session?.userId == userId;
    }).toList();

    for (final key in keysToDelete) {
      await _chatSessionsBox.delete(key);
    }
  }

  String generateSessionName(List<ChatMessageItem> messages) {
    if (messages.isEmpty) return 'Nueva conversación';

    final firstUserMessage = messages.firstWhere(
      (m) => m.isUser,
      orElse: () => messages.first,
    );

    final content = firstUserMessage.content;
    if (content.length > 40) {
      return '${content.substring(0, 40)}...';
    }
    return content;
  }
}
