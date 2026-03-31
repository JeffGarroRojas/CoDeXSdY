import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfGeneratorService {
  static PdfGeneratorService? _instance;
  static PdfGeneratorService get instance =>
      _instance ??= PdfGeneratorService._();
  PdfGeneratorService._();

  static final _primaryColor = PdfColor(99, 102, 241);
  static final _secondaryColor = PdfColor(60, 60, 60);
  static final _lightGray = PdfColor(128, 128, 128);
  static final _footerGray = PdfColor(150, 150, 150);
  static final _exampleColor = PdfColor(34, 197, 94);
  static final _tipColor = PdfColor(245, 158, 11);
  static final _whiteColor = PdfColor(255, 255, 255);
  static final _cardBgColor = PdfColor(245, 245, 250);
  static final _userColor = PdfColor(99, 102, 241);
  static final _dexColor = PdfColor(16, 185, 129);

  static const _pageWidth = 595.0;
  static const _pageHeight = 842.0;
  static const _marginLeft = 40.0;
  static const _marginRight = 40.0;
  static const _marginTop = 60.0;
  static const _marginBottom = 60.0;
  static const _contentWidth = _pageWidth - _marginLeft - _marginRight;

  PdfDocument? _document;
  int _currentPageNumber = 0;
  int _totalPages = 0;
  PdfPage? _currentPage;
  double _yPosition = 0;
  List<String> _tocEntries = [];
  Uint8List? _logoBytes;

  Future<void> _loadLogo(String? logoPath) async {
    if (logoPath == null) {
      _logoBytes = null;
      return;
    }
    try {
      final byteData = await rootBundle.load(logoPath);
      _logoBytes = byteData.buffer.asUint8List();
    } catch (e) {
      _logoBytes = null;
    }
  }

  PdfDocument _createDocument() {
    _document = PdfDocument();
    _currentPageNumber = 0;
    _totalPages = 0;
    _tocEntries = [];
    _yPosition = _marginTop;
    _currentPage = null;
    return _document!;
  }

  PdfPage _addNewPage() {
    _currentPage = _document!.pages.add();
    _currentPageNumber++;
    _totalPages++;
    _yPosition = _marginTop;
    _drawPageHeader();
    _drawPageFooter();
    return _currentPage!;
  }

  void _drawPageHeader() {
    if (_currentPage == null) return;

    if (_logoBytes != null) {
      final logoImage = PdfBitmap(_logoBytes!);
      _currentPage!.graphics.drawImage(
        logoImage,
        Rect.fromLTWH(_marginLeft, 15, 50, 30),
      );
    }

    _currentPage!.graphics.drawString(
      'CoDeXSdY',
      PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(_marginLeft + 60, 22, 150, 15),
      brush: PdfSolidBrush(_primaryColor),
    );
  }

  void _drawPageFooter() {
    if (_currentPage == null) return;

    _currentPage!.graphics.drawLine(
      PdfPen(_lightGray, width: 0.5),
      Offset(_marginLeft, _pageHeight - _marginBottom + 15),
      Offset(_pageWidth - _marginRight, _pageHeight - _marginBottom + 15),
    );

    _currentPage!.graphics.drawString(
      'CoDeXSdY - Tu asistente de estudio',
      PdfStandardFont(PdfFontFamily.helvetica, 8),
      bounds: Rect.fromLTWH(
        _marginLeft,
        _pageHeight - _marginBottom + 20,
        200,
        15,
      ),
      brush: PdfSolidBrush(_footerGray),
    );

    if (_totalPages > 0) {
      _currentPage!.graphics.drawString(
        'Pág. $_currentPageNumber',
        PdfStandardFont(PdfFontFamily.helvetica, 8),
        bounds: Rect.fromLTWH(
          _pageWidth - _marginRight - 60,
          _pageHeight - _marginBottom + 20,
          60,
          15,
        ),
        brush: PdfSolidBrush(_footerGray),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
    }
  }

  double _getMaxY() => _pageHeight - _marginBottom - 40;

  void _checkPageBreak(double requiredHeight) {
    if (_yPosition + requiredHeight > _getMaxY()) {
      _addNewPage();
    }
  }

  void addTitle(String title, {String? subtitle}) {
    if (_currentPage == null) _addNewPage();

    _yPosition += 20;

    _currentPage!.graphics.drawString(
      title,
      PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(_marginLeft, _yPosition, _contentWidth, 35),
      brush: PdfSolidBrush(_primaryColor),
    );
    _yPosition += 40;

    if (subtitle != null) {
      _currentPage!.graphics.drawString(
        subtitle,
        PdfStandardFont(PdfFontFamily.helvetica, 11),
        bounds: Rect.fromLTWH(_marginLeft, _yPosition, _contentWidth, 20),
        brush: PdfSolidBrush(_lightGray),
      );
      _yPosition += 25;
    }

    _currentPage!.graphics.drawLine(
      PdfPen(_primaryColor, width: 2),
      Offset(_marginLeft, _yPosition),
      Offset(_marginLeft + 100, _yPosition),
    );
    _yPosition += 20;
  }

  void addSectionTitle(String title) {
    _tocEntries.add(title);

    _checkPageBreak(40);

    _currentPage!.graphics.drawString(
      title.toUpperCase(),
      PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(_marginLeft, _yPosition, _contentWidth, 25),
      brush: PdfSolidBrush(_primaryColor),
    );
    _yPosition += 5;

    _currentPage!.graphics.drawLine(
      PdfPen(_primaryColor, width: 1),
      Offset(_marginLeft, _yPosition),
      Offset(_marginLeft + 80, _yPosition),
    );
    _yPosition += 20;
  }

  void addParagraph(String text, {double fontSize = 11}) {
    final lines = _wrapText(text, fontSize);
    final lineHeight = fontSize + 6;

    for (final line in lines) {
      _checkPageBreak(lineHeight);

      _currentPage!.graphics.drawString(
        line,
        PdfStandardFont(PdfFontFamily.helvetica, fontSize),
        bounds: Rect.fromLTWH(
          _marginLeft,
          _yPosition,
          _contentWidth,
          lineHeight,
        ),
        brush: PdfSolidBrush(_secondaryColor),
      );
      _yPosition += lineHeight;
    }
    _yPosition += 8;
  }

  void addExample(String text) {
    _checkPageBreak(50);

    const boxHeight = 30.0;

    _currentPage!.graphics.drawRectangle(
      bounds: Rect.fromLTWH(_marginLeft, _yPosition, _contentWidth, boxHeight),
      pen: PdfPen(_exampleColor, width: 1),
      brush: PdfSolidBrush(_exampleColor),
    );

    _currentPage!.graphics.drawString(
      'EJEMPLO',
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(_marginLeft + 8, _yPosition + 5, 80, 12),
      brush: PdfSolidBrush(_whiteColor),
    );

    final lines = _wrapText(text, 10);
    var lineY = _yPosition + 20;
    for (final line in lines.take(3)) {
      _currentPage!.graphics.drawString(
        line,
        PdfStandardFont(PdfFontFamily.helvetica, 10),
        bounds: Rect.fromLTWH(_marginLeft + 8, lineY, _contentWidth - 16, 14),
        brush: PdfSolidBrush(_secondaryColor),
      );
      lineY += 14;
    }

    _yPosition += boxHeight + 10;
  }

  void addTip(String text) {
    _checkPageBreak(50);

    const boxHeight = 30.0;

    _currentPage!.graphics.drawRectangle(
      bounds: Rect.fromLTWH(_marginLeft, _yPosition, _contentWidth, boxHeight),
      pen: PdfPen(_tipColor, width: 1),
      brush: PdfSolidBrush(_tipColor),
    );

    _currentPage!.graphics.drawString(
      'CONSEJO',
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(_marginLeft + 8, _yPosition + 5, 80, 12),
      brush: PdfSolidBrush(_whiteColor),
    );

    final lines = _wrapText(text, 10);
    var lineY = _yPosition + 20;
    for (final line in lines.take(3)) {
      _currentPage!.graphics.drawString(
        line,
        PdfStandardFont(PdfFontFamily.helvetica, 10),
        bounds: Rect.fromLTWH(_marginLeft + 8, lineY, _contentWidth - 16, 14),
        brush: PdfSolidBrush(_secondaryColor),
      );
      lineY += 14;
    }

    _yPosition += boxHeight + 10;
  }

  void addBulletList(List<String> items) {
    for (final item in items) {
      _checkPageBreak(20);

      _currentPage!.graphics.drawEllipse(
        Rect.fromLTWH(_marginLeft + 5, _yPosition + 3, 6, 6),
        brush: PdfSolidBrush(_primaryColor),
      );

      final lines = _wrapText(item, 10);
      for (var i = 0; i < lines.length; i++) {
        final xOffset = i == 0 ? _marginLeft + 18 : _marginLeft + 18;
        _currentPage!.graphics.drawString(
          lines[i],
          PdfStandardFont(PdfFontFamily.helvetica, 10),
          bounds: Rect.fromLTWH(xOffset, _yPosition, _contentWidth - 18, 16),
          brush: PdfSolidBrush(_secondaryColor),
        );
        _yPosition += 16;
      }
      _yPosition += 4;
    }
  }

  void addSpacer(double height) {
    _yPosition += height;
  }

  void addTableOfContents() {
    if (_tocEntries.isEmpty) return;

    _checkPageBreak(80);

    _currentPage!.graphics.drawString(
      'ÍNDICE',
      PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(_marginLeft, _yPosition, _contentWidth, 25),
      brush: PdfSolidBrush(_primaryColor),
    );
    _yPosition += 10;

    _currentPage!.graphics.drawLine(
      PdfPen(_primaryColor, width: 1),
      Offset(_marginLeft, _yPosition),
      Offset(_marginLeft + 60, _yPosition),
    );
    _yPosition += 20;

    for (var i = 0; i < _tocEntries.length; i++) {
      _checkPageBreak(22);

      _currentPage!.graphics.drawString(
        '${i + 1}. ${_tocEntries[i]}',
        PdfStandardFont(PdfFontFamily.helvetica, 11),
        bounds: Rect.fromLTWH(_marginLeft, _yPosition, _contentWidth - 50, 18),
        brush: PdfSolidBrush(_secondaryColor),
      );
      _yPosition += 22;
    }

    _yPosition += 20;
  }

  void addPageBreak() {
    _addNewPage();
  }

  List<String> _wrapText(String text, double fontSize) {
    final lines = <String>[];
    final words = text.split(' ');
    final maxChars = (_contentWidth / (fontSize * 0.5)).floor();
    var currentLine = '';

    for (final word in words) {
      if ((currentLine + word).length <= maxChars) {
        currentLine += (currentLine.isEmpty ? '' : ' ') + word;
      } else {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
        }
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }

  Future<Uint8List> generateSummary({
    required String title,
    required String subject,
    required String content,
    DateTime? generatedAt,
    String? logoPath,
  }) async {
    await _loadLogo(logoPath);
    _createDocument();
    _addNewPage();

    final date = generatedAt ?? DateTime.now();
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    addTitle(title, subtitle: 'Generado por CoDeXSdY - $dateStr');

    addTableOfContents();

    _parseAndAddContent(content);

    final List<int> bytesList = _document!.saveSync();
    _document!.dispose();
    _document = null;

    return Uint8List.fromList(bytesList);
  }

  void _parseAndAddContent(String content) {
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        addSpacer(10);
        continue;
      }

      if (trimmed.startsWith('**') && trimmed.endsWith('**')) {
        final sectionTitle = trimmed.replaceAll('**', '');
        addSectionTitle(sectionTitle);
      } else if (trimmed.toLowerCase().startsWith('ejemplo:')) {
        final text = trimmed.substring(8).trim();
        addExample(text);
      } else if (trimmed.toLowerCase().startsWith('consejo:') ||
          trimmed.toLowerCase().startsWith('tip:') ||
          trimmed.toLowerCase().startsWith('tip :')) {
        var text = trimmed;
        if (text.toLowerCase().startsWith('consejo:')) {
          text = text.substring(8).trim();
        } else {
          text = text.substring(4).trim();
          if (text.startsWith(':')) text = text.substring(1).trim();
        }
        addTip(text);
      } else if (trimmed.startsWith('- ')) {
        addBulletList([trimmed.substring(2)]);
      } else {
        addParagraph(trimmed);
      }
    }
  }

  Future<void> sharePdf({
    required Uint8List bytes,
    required String filename,
    required String text,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: text);
  }

  Future<File> savePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<Uint8List> generateChatExport({
    required String title,
    required List<Map<String, dynamic>> messages,
    required bool asNotes,
    DateTime? generatedAt,
    String? logoPath,
  }) async {
    await _loadLogo(logoPath);
    _createDocument();
    _addNewPage();

    final date = generatedAt ?? DateTime.now();
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    final subtitle = asNotes
        ? 'Notas de estudio - $dateStr'
        : 'Conversación con DeX - $dateStr';

    addTitle(title, subtitle: subtitle);
    addSpacer(10);

    if (asNotes) {
      _addNotesContent(messages);
    } else {
      _addConversationContent(messages);
    }

    final List<int> bytesList = _document!.saveSync();
    _document!.dispose();
    _document = null;

    return Uint8List.fromList(bytesList);
  }

  void _addConversationContent(List<Map<String, dynamic>> messages) {
    for (final msg in messages) {
      final isUser = msg['isUser'] == true;
      final content = msg['content'] as String? ?? '';
      final sender = isUser ? 'Usuario' : 'DeX';
      final color = isUser ? _userColor : _dexColor;

      if (content.trim().isEmpty) continue;

      _checkPageBreak(60);

      _currentPage!.graphics.drawString(
        sender,
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(_marginLeft, _yPosition, 100, 15),
        brush: PdfSolidBrush(color),
      );
      _yPosition += 18;

      final lines = _wrapText(content, 10);
      for (final line in lines) {
        _checkPageBreak(16);
        _currentPage!.graphics.drawString(
          line,
          PdfStandardFont(PdfFontFamily.helvetica, 10),
          bounds: Rect.fromLTWH(
            _marginLeft + 10,
            _yPosition,
            _contentWidth - 10,
            16,
          ),
          brush: PdfSolidBrush(_secondaryColor),
        );
        _yPosition += 16;
      }

      _yPosition += 15;

      _currentPage!.graphics.drawLine(
        PdfPen(_lightGray, width: 0.5),
        Offset(_marginLeft, _yPosition - 8),
        Offset(_pageWidth - _marginRight, _yPosition - 8),
      );
    }
  }

  void _addNotesContent(List<Map<String, dynamic>> messages) {
    for (final msg in messages) {
      final isUser = msg['isUser'] == true;
      if (isUser) continue;

      final content = msg['content'] as String? ?? '';
      if (content.trim().isEmpty) continue;

      _checkPageBreak(30);

      _currentPage!.graphics.drawEllipse(
        Rect.fromLTWH(_marginLeft + 3, _yPosition + 4, 6, 6),
        brush: PdfSolidBrush(_dexColor),
      );

      final lines = _wrapText(content, 11);
      for (var i = 0; i < lines.length; i++) {
        _checkPageBreak(18);
        _currentPage!.graphics.drawString(
          lines[i],
          PdfStandardFont(PdfFontFamily.helvetica, 11),
          bounds: Rect.fromLTWH(
            _marginLeft + 18,
            _yPosition,
            _contentWidth - 18,
            18,
          ),
          brush: PdfSolidBrush(_secondaryColor),
        );
        _yPosition += 18;
      }
      _yPosition += 8;
    }
  }

  Future<Uint8List> generateFlashcards({
    required String title,
    required List<Map<String, String>> cards,
    DateTime? generatedAt,
    String? logoPath,
  }) async {
    await _loadLogo(logoPath);
    _createDocument();
    _addNewPage();

    final date = generatedAt ?? DateTime.now();
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    addTitle(title, subtitle: 'Tarjetas de estudio - $dateStr');
    addSpacer(5);

    _currentPage!.graphics.drawString(
      'Total: ${cards.length} tarjetas',
      PdfStandardFont(PdfFontFamily.helvetica, 11),
      bounds: Rect.fromLTWH(_marginLeft, _yPosition, _contentWidth, 18),
      brush: PdfSolidBrush(_lightGray),
    );
    _yPosition += 20;

    for (var i = 0; i < cards.length; i++) {
      final front = cards[i]['front'] ?? '';
      final back = cards[i]['back'] ?? '';

      _checkPageBreak(120);

      _currentPage!.graphics.drawString(
        'TARJETA ${i + 1}',
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(_marginLeft, _yPosition, 100, 15),
        brush: PdfSolidBrush(_primaryColor),
      );
      _yPosition += 18;

      _currentPage!.graphics.drawRectangle(
        bounds: Rect.fromLTWH(_marginLeft, _yPosition, _contentWidth, 70),
        pen: PdfPen(_primaryColor, width: 1),
        brush: PdfSolidBrush(_cardBgColor),
      );

      _currentPage!.graphics.drawString(
        'PREGUNTA',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(_marginLeft + 8, _yPosition + 5, 80, 12),
        brush: PdfSolidBrush(_primaryColor),
      );

      final frontLines = _wrapText(front, 10);
      var frontY = _yPosition + 18;
      for (final line in frontLines.take(3)) {
        _currentPage!.graphics.drawString(
          line,
          PdfStandardFont(PdfFontFamily.helvetica, 10),
          bounds: Rect.fromLTWH(
            _marginLeft + 8,
            frontY,
            _contentWidth - 16,
            14,
          ),
          brush: PdfSolidBrush(_secondaryColor),
        );
        frontY += 14;
      }

      _currentPage!.graphics.drawLine(
        PdfPen(_lightGray, width: 0.5),
        Offset(_marginLeft + 8, _yPosition + 35),
        Offset(_pageWidth - _marginRight - 8, _yPosition + 35),
      );

      _currentPage!.graphics.drawString(
        'RESPUESTA',
        PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(_marginLeft + 8, _yPosition + 40, 80, 12),
        brush: PdfSolidBrush(_dexColor),
      );

      final backLines = _wrapText(back, 10);
      var backY = _yPosition + 53;
      for (final line in backLines.take(2)) {
        _currentPage!.graphics.drawString(
          line,
          PdfStandardFont(PdfFontFamily.helvetica, 10),
          bounds: Rect.fromLTWH(_marginLeft + 8, backY, _contentWidth - 16, 14),
          brush: PdfSolidBrush(_secondaryColor),
        );
        backY += 14;
      }

      _yPosition += 80;
      _yPosition += 10;
    }

    final List<int> bytesList = _document!.saveSync();
    _document!.dispose();
    _document = null;

    return Uint8List.fromList(bytesList);
  }
}
