import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  static PdfService? _instance;
  static PdfService get instance => _instance ??= PdfService._();
  PdfService._();

  Future<String> extractTextFromFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return extractTextFromBytes(bytes);
    } catch (e) {
      throw PdfServiceException(message: 'Error al leer el archivo PDF: $e');
    }
  }

  Future<String> extractTextFromBytes(Uint8List bytes) async {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final textExtractor = PdfTextExtractor(document);
      final text = textExtractor.extractText();
      document.dispose();

      if (text.trim().isEmpty) {
        throw PdfServiceException(message: 'El PDF no contiene texto legible');
      }

      return text;
    } catch (e) {
      if (e is PdfServiceException) rethrow;
      throw PdfServiceException(message: 'Error al extraer texto del PDF: $e');
    }
  }

  Future<List<String>> extractPages(Uint8List bytes) async {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final pages = <String>[];

      for (int i = 0; i < document.pages.count; i++) {
        final textExtractor = PdfTextExtractor(document);
        final pageText = textExtractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        if (pageText.trim().isNotEmpty) {
          pages.add(pageText.trim());
        }
      }

      document.dispose();
      return pages;
    } catch (e) {
      throw PdfServiceException(
        message: 'Error al extraer páginas del PDF: $e',
      );
    }
  }

  Future<int> getPageCount(Uint8List bytes) async {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final count = document.pages.count;
      document.dispose();
      return count;
    } catch (e) {
      throw PdfServiceException(message: 'Error al contar páginas del PDF: $e');
    }
  }

  Future<bool> isValidPdf(File file) async {
    try {
      if (!file.path.toLowerCase().endsWith('.pdf')) {
        return false;
      }

      final bytes = await file.readAsBytes();
      if (bytes.length < 5) {
        return false;
      }

      final header = String.fromCharCodes(bytes.sublist(0, 5));
      return header == '%PDF-';
    } catch (e) {
      return false;
    }
  }

  Future<String> extractTextPreview(File file, {int maxLength = 500}) async {
    final text = await extractTextFromFile(file);
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
}

class PdfServiceException implements Exception {
  final String message;

  PdfServiceException({required this.message});

  @override
  String toString() => 'PdfServiceException: $message';
}
