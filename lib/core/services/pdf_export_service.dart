import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfExportService {
  static Future<File> exportToTextFile({
    required String title,
    required String content,
    required String filename,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.txt');
    final textContent =
        '''
=====================================
$title
=====================================
Fecha: ${DateTime.now().toString().split(' ')[0]}

$content

=====================================
Generado por CoDeXSdY - CoDy AI
=====================================
''';
    await file.writeAsString(textContent);
    return file;
  }

  static Future<File> exportFlashcards({
    required List<Map<String, String>> flashcards,
    required String title,
  }) async {
    final content = StringBuffer();
    content.writeln('=====================================');
    content.writeln(title);
    content.writeln('=====================================');
    content.writeln('Fecha: ${DateTime.now().toString().split(' ')[0]}');
    content.writeln('');

    for (int i = 0; i < flashcards.length; i++) {
      final card = flashcards[i];
      content.writeln('--- Tarjeta ${i + 1} ---');
      content.writeln('PREGUNTA: ${card['front'] ?? ''}');
      content.writeln('RESPUESTA: ${card['back'] ?? ''}');
      content.writeln('');
    }

    content.writeln('=====================================');
    content.writeln('Generado por CoDeXSdY - CoDy AI');
    content.writeln('=====================================');

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/flashcards_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await file.writeAsString(content.toString());
    return file;
  }

  static Future<File> exportSummary({
    required String title,
    required String content,
    String? source,
  }) async {
    final textContent = StringBuffer();
    textContent.writeln('=====================================');
    textContent.writeln(title);
    textContent.writeln('=====================================');
    if (source != null) textContent.writeln('Fuente: $source');
    textContent.writeln('Fecha: ${DateTime.now().toString().split(' ')[0]}');
    textContent.writeln('');
    textContent.writeln(content);
    textContent.writeln('');
    textContent.writeln('=====================================');
    textContent.writeln('Generado por CoDeXSdY - CoDy AI');
    textContent.writeln('=====================================');

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/resumen_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await file.writeAsString(textContent.toString());
    return file;
  }

  static Future<File> exportQuiz({
    required String title,
    required String content,
    bool includeAnswers = true,
  }) async {
    final textContent = StringBuffer();
    textContent.writeln('=====================================');
    textContent.writeln(title);
    textContent.writeln('=====================================');
    textContent.writeln(includeAnswers ? 'CON RESPUESTAS' : 'SIN RESPUESTAS');
    textContent.writeln('Fecha: ${DateTime.now().toString().split(' ')[0]}');
    textContent.writeln('');
    textContent.writeln(content);
    textContent.writeln('');
    textContent.writeln('=====================================');
    textContent.writeln('Generado por CoDeXSdY - CoDy AI');
    textContent.writeln('=====================================');

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/quiz_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await file.writeAsString(textContent.toString());
    return file;
  }
}
