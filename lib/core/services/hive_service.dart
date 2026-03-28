import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../features/documents/data/models/document.dart';
import '../../features/documents/data/models/study_session.dart';
import '../../features/documents/data/models/user_profile.dart';
import '../../features/flashcards/data/models/flashcard.dart';
import '../../features/auth/data/models/user.dart';

class HiveService {
  static const String documentsBox = 'documents';
  static const String flashcardsBox = 'flashcards';
  static const String sessionsBox = 'sessions';
  static const String profileBox = 'profile';
  static const String usersBox = 'users';

  late Box<Document> _documentsBox;
  late Box<Flashcard> _flashcardsBox;
  late Box<StudySession> _sessionsBox;
  late Box<UserProfile> _profileBox;
  late Box<User> _usersBox;

  final _uuid = const Uuid();

  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(DocumentAdapter());
    Hive.registerAdapter(FlashcardAdapter());
    Hive.registerAdapter(FlashcardStatusAdapter());
    Hive.registerAdapter(StudySessionAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(UserAdapter());

    _documentsBox = await Hive.openBox<Document>(documentsBox);
    _flashcardsBox = await Hive.openBox<Flashcard>(flashcardsBox);
    _sessionsBox = await Hive.openBox<StudySession>(sessionsBox);
    _profileBox = await Hive.openBox<UserProfile>(profileBox);
    _usersBox = await Hive.openBox<User>(usersBox);

    await _createDefaultAdmin();
  }

  Future<void> _createDefaultAdmin() async {
    final existingAdmin = _usersBox.values
        .where((u) => u.email == 'admin@admin')
        .firstOrNull;
    if (existingAdmin == null) {
      final admin = User.create(
        id: _uuid.v4(),
        email: 'admin@admin',
        passwordHash: User.hashPassword('admin'),
        name: 'Administrador',
        isAdmin: true,
      );
      await _usersBox.put(admin.id, admin);
    }
  }

  String generateId() => _uuid.v4();

  Future<Document> createDocument({
    required String title,
    String? description,
    required String filePath,
    required String extractedText,
  }) async {
    final doc = Document.create(
      odId: generateId(),
      title: title,
      description: description,
      filePath: filePath,
      extractedText: extractedText,
    );
    await _documentsBox.put(doc.odId, doc);
    return doc;
  }

  List<Document> getAllDocuments() => _documentsBox.values.toList();

  Document? getDocument(String odId) => _documentsBox.get(odId);

  Future<void> deleteDocument(String odId) async {
    await _documentsBox.delete(odId);
    final relatedCards = _flashcardsBox.values
        .where((f) => f.documentId == odId)
        .toList();
    for (final card in relatedCards) {
      await _flashcardsBox.delete(card.odId);
    }
  }

  Future<Flashcard> createFlashcard({
    String? documentId,
    required String front,
    required String back,
    List<String>? tags,
  }) async {
    final card = Flashcard.create(
      odId: generateId(),
      documentId: documentId,
      front: front,
      back: back,
      tags: tags,
    );
    await _flashcardsBox.put(card.odId, card);
    return card;
  }

  List<Flashcard> getAllFlashcards() => _flashcardsBox.values.toList();

  List<Flashcard> getFlashcardsForDocument(String documentId) =>
      _flashcardsBox.values.where((f) => f.documentId == documentId).toList();

  List<Flashcard> getDueFlashcards() => _flashcardsBox.values
      .where(
        (f) => f.nextReview == null || f.nextReview!.isBefore(DateTime.now()),
      )
      .toList();

  Future<void> updateFlashcard(Flashcard card) async {
    card.updatedAt = DateTime.now();
    await _flashcardsBox.put(card.odId, card);
  }

  Future<void> deleteFlashcard(String odId) async {
    await _flashcardsBox.delete(odId);
  }

  Future<StudySession> startSession({String? documentId}) async {
    final session = StudySession.create(documentId: documentId);
    await _sessionsBox.put(session.odId, session);
    return session;
  }

  Future<void> completeSession(StudySession session) async {
    session.complete();
    await _sessionsBox.put(session.odId, session);
  }

  List<StudySession> getAllSessions() => _sessionsBox.values.toList();

  List<StudySession> getSessionsForDocument(String documentId) =>
      _sessionsBox.values.where((s) => s.documentId == documentId).toList();

  UserProfile? getProfile() {
    if (_profileBox.isEmpty) return null;
    return _profileBox.values.first;
  }

  Future<UserProfile> getOrCreateProfile() async {
    var profile = getProfile();
    if (profile == null) {
      profile = UserProfile.create(odId: generateId());
      await _profileBox.put(profile.odId, profile);
    }
    return profile;
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _profileBox.put(profile.odId, profile);
  }

  Future<void> clearAll() async {
    await _documentsBox.clear();
    await _flashcardsBox.clear();
    await _sessionsBox.clear();
    await _profileBox.clear();
  }

  // ==================== AUTENTICACIÓN ====================

  User? getUserByEmail(String email) {
    return _usersBox.values.where((u) => u.email == email).firstOrNull;
  }

  User? getUserById(String id) {
    return _usersBox.get(id);
  }

  List<User> getAllUsers() {
    return _usersBox.values.toList();
  }

  Future<User> createUser({
    required String email,
    required String password,
    required String name,
    bool isAdmin = false,
  }) async {
    final existingUser = getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('El usuario ya existe');
    }

    final user = User.create(
      id: _uuid.v4(),
      email: email,
      passwordHash: User.hashPassword(password),
      name: name,
      isAdmin: isAdmin,
    );
    await _usersBox.put(user.id, user);
    return user;
  }

  Future<User?> login(String email, String password) async {
    final user = getUserByEmail(email);
    if (user == null) return null;

    if (user.checkPassword(password)) {
      user.lastLogin = DateTime.now();
      await _usersBox.put(user.id, user);
      return user;
    }
    return null;
  }

  Future<void> updateUser(User user) async {
    await _usersBox.put(user.id, user);
  }

  Future<void> deleteUser(String id) async {
    await _usersBox.delete(id);
  }
}
