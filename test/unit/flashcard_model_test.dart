import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/features/flashcards/data/models/flashcard.dart';

void main() {
  group('Flashcard', () {
    test('should create flashcard with default values', () {
      final card = Flashcard();

      expect(card.easeFactor, 2.5);
      expect(card.interval, 0);
      expect(card.repetitions, 0);
      expect(card.tags, isEmpty);
      expect(card.status, FlashcardStatus.newCard);
      expect(card.nextReview, isNotNull);
    });

    test('should create flashcard with factory constructor', () {
      final card = Flashcard.create(
        odId: 'test-id',
        front: 'Question',
        back: 'Answer',
        userId: 'user-1',
        tags: ['math', 'algebra'],
      );

      expect(card.odId, 'test-id');
      expect(card.front, 'Question');
      expect(card.back, 'Answer');
      expect(card.userId, 'user-1');
      expect(card.tags, ['math', 'algebra']);
      expect(card.easeFactor, 2.5);
    });

    test('should convert to map correctly', () {
      final card = Flashcard.create(
        odId: 'test-id',
        front: 'Question',
        back: 'Answer',
        userId: 'user-1',
      );

      final map = card.toMap();

      expect(map['odId'], 'test-id');
      expect(map['front'], 'Question');
      expect(map['back'], 'Answer');
      expect(map['userId'], 'user-1');
      expect(map['easeFactor'], 2.5);
      expect(map['interval'], 0);
      expect(map['repetitions'], 0);
    });

    test('should create from map correctly', () {
      final map = {
        'odId': 'map-id',
        'front': 'Map Question',
        'back': 'Map Answer',
        'userId': 'user-2',
        'easeFactor': 2.0,
        'interval': 5,
        'repetitions': 3,
        'statusIndex': 2,
        'tags': ['history'],
      };

      final card = Flashcard.fromMap(map);

      expect(card.odId, 'map-id');
      expect(card.front, 'Map Question');
      expect(card.back, 'Map Answer');
      expect(card.easeFactor, 2.0);
      expect(card.interval, 5);
      expect(card.repetitions, 3);
      expect(card.status, FlashcardStatus.review);
      expect(card.tags, ['history']);
    });

    test('should handle null dates in fromMap', () {
      final map = {
        'odId': 'test-id',
        'front': 'Q',
        'back': 'A',
        'userId': 'user-1',
      };

      final card = Flashcard.fromMap(map);

      expect(card.nextReview, isNotNull);
      expect(card.createdAt, isNotNull);
      expect(card.updatedAt, isNotNull);
    });

    test('should set status via enum', () {
      final card = Flashcard();

      card.status = FlashcardStatus.mastered;
      expect(card.statusIndex, 3);
      expect(card.status, FlashcardStatus.mastered);

      card.status = FlashcardStatus.learning;
      expect(card.statusIndex, 1);
      expect(card.status, FlashcardStatus.learning);
    });

    test('should handle missing optional fields in fromMap', () {
      final map = <String, dynamic>{
        'odId': 'test-id',
        'front': 'Q',
        'back': 'A',
        'userId': 'user-1',
      };

      final card = Flashcard.fromMap(map);

      expect(card.easeFactor, 2.5);
      expect(card.interval, 0);
      expect(card.repetitions, 0);
      expect(card.tags, isEmpty);
      expect(card.statusIndex, 0);
    });
  });

  group('FlashcardStatus', () {
    test('should have correct indices', () {
      expect(FlashcardStatus.newCard.index, 0);
      expect(FlashcardStatus.learning.index, 1);
      expect(FlashcardStatus.review.index, 2);
      expect(FlashcardStatus.mastered.index, 3);
    });

    test('should have 4 statuses', () {
      expect(FlashcardStatus.values.length, 4);
    });
  });
}
