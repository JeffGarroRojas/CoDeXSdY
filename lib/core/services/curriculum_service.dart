import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class CurriculumService {
  static CurriculumService? _instance;
  static CurriculumService get instance => _instance ??= CurriculumService._();
  CurriculumService._();

  final Map<String, String> _curriculumContent = {};
  bool _isLoaded = false;

  Future<void> loadCurriculum() async {
    if (_isLoaded) return;

    try {
      final temasDir = Directory('assets/temas');
      if (!await temasDir.exists()) {
        await _loadFromAssets();
      } else {
        await _loadFromDirectory(temasDir);
      }
    } catch (e) {
      print('Error loading curriculum: $e');
    }
    _isLoaded = true;
  }

  Future<void> _loadFromAssets() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final topics = (json.decode(manifestContent) as Map).keys
          .where(
            (key) => key.startsWith('assets/temas/') && key.endsWith('.pdf'),
          )
          .toList();

      for (final assetPath in topics) {
        try {
          final fileName = assetPath
              .split('/')
              .last
              .replaceAll('.pdf', '')
              .toLowerCase();
          final content = await rootBundle.loadString(assetPath);
          _curriculumContent[fileName] = content;
        } catch (e) {
          print('Error loading $assetPath: $e');
        }
      }
    } catch (e) {
      print('Error reading asset manifest: $e');
    }
  }

  Future<void> _loadFromDirectory(Directory dir) async {
    if (!await dir.exists()) return;

    final files = dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.pdf'),
    );
    for (final file in files) {
      try {
        final fileName = file.path
            .split('/')
            .last
            .replaceAll('.pdf', '')
            .toLowerCase();
        final content = await file.readAsString();
        _curriculumContent[fileName] = content;
      } catch (e) {
        print('Error loading ${file.path}: $e');
      }
    }
  }

  String getCurriculumForSubject(String subject) {
    final subjectLower = subject.toLowerCase();

    if (subjectLower.contains('matemática')) {
      return _curriculumContent['matematicas'] ??
          _curriculumContent['matemáticas'] ??
          _curriculumContent['matematica_'] ??
          '';
    } else if (subjectLower.contains('ciencia') ||
        subjectLower.contains('biología')) {
      return _curriculumContent['biologia'] ?? '';
    } else if (subjectLower.contains('estudio') ||
        subjectLower.contains('social')) {
      return _curriculumContent['estudios_sociales'] ??
          _curriculumContent['estudios-sociales'] ??
          '';
    } else if (subjectLower.contains('español')) {
      return _curriculumContent['espanol'] ?? '';
    } else if (subjectLower.contains('cívica') ||
        subjectLower.contains('civica')) {
      return _curriculumContent['civica'] ?? '';
    } else if (subjectLower.contains('inglés') ||
        subjectLower.contains('ingles')) {
      return _curriculumContent['ingles'] ?? '';
    }

    return _curriculumContent.values.join('\n\n');
  }

  String buildEnhancedPrompt(String subject, List<String> topics) {
    final curriculum = getCurriculumForSubject(subject);

    if (curriculum.isEmpty) {
      return '';
    }

    return '''
MATERIAL DE ESTUDIO DEL MEP (Usa este contenido para crear preguntas realistas):
$curriculum
''';
  }
}
