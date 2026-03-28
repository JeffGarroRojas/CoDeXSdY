import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/features/documents/data/models/document.dart';

void main() {
  group('Document', () {
    test('should create document with factory constructor', () {
      final doc = Document.create(
        odId: 'doc-1',
        title: 'Test Document',
        filePath: '/path/to/file.pdf',
        extractedText: 'Some extracted text content',
        userId: 'user-1',
        description: 'A test document',
      );

      expect(doc.odId, 'doc-1');
      expect(doc.title, 'Test Document');
      expect(doc.filePath, '/path/to/file.pdf');
      expect(doc.extractedText, 'Some extracted text content');
      expect(doc.userId, 'user-1');
      expect(doc.description, 'A test document');
      expect(doc.createdAt, isNotNull);
      expect(doc.updatedAt, isNotNull);
    });

    test('should create document without optional description', () {
      final doc = Document.create(
        odId: 'doc-2',
        title: 'No Description Doc',
        filePath: '/path/to/file.txt',
        extractedText: 'Content',
        userId: 'user-1',
      );

      expect(doc.odId, 'doc-2');
      expect(doc.description, isNull);
    });

    test('should convert to map correctly', () {
      final doc = Document.create(
        odId: 'doc-3',
        title: 'Map Test',
        filePath: '/path',
        extractedText: 'Text',
        userId: 'user-1',
      );

      final map = doc.toMap();

      expect(map['odId'], 'doc-3');
      expect(map['title'], 'Map Test');
      expect(map['filePath'], '/path');
      expect(map['extractedText'], 'Text');
      expect(map['userId'], 'user-1');
    });

    test('should create from map correctly', () {
      final map = {
        'odId': 'map-doc',
        'title': 'From Map',
        'description': 'Description from map',
        'filePath': '/map/path',
        'extractedText': 'Extracted from map',
        'userId': 'user-map',
        'createdAt': '2024-01-15T10:30:00.000Z',
        'updatedAt': '2024-01-15T11:00:00.000Z',
        'lastStudiedAt': '2024-01-15T12:00:00.000Z',
      };

      final doc = Document.fromMap(map);

      expect(doc.odId, 'map-doc');
      expect(doc.title, 'From Map');
      expect(doc.description, 'Description from map');
      expect(doc.filePath, '/map/path');
      expect(doc.extractedText, 'Extracted from map');
      expect(doc.userId, 'user-map');
      expect(doc.createdAt!.year, 2024);
      expect(doc.updatedAt!.year, 2024);
      expect(doc.lastStudiedAt!.year, 2024);
    });

    test('should handle missing optional fields in fromMap', () {
      final map = {
        'odId': 'minimal-doc',
        'title': 'Minimal',
        'filePath': '/path',
        'extractedText': 'Text',
        'userId': 'user-1',
      };

      final doc = Document.fromMap(map);

      expect(doc.description, isNull);
      expect(doc.lastStudiedAt, isNull);
      expect(doc.createdAt, isNotNull);
      expect(doc.updatedAt, isNotNull);
    });

    test('should handle null filePath in fromMap', () {
      final map = {
        'odId': 'no-path-doc',
        'title': 'No Path',
        'filePath': null,
        'extractedText': 'Text',
        'userId': 'user-1',
      };

      final doc = Document.fromMap(map);

      expect(doc.filePath, '');
    });
  });
}
