import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/ai_client.dart';
import '../../../../core/services/pdf_generator_service.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../auth/data/models/user_preferences.dart';
import '../../data/models/chat_session.dart';
import 'chat_history_page.dart';

final userPreferencesProvider = FutureProvider.family<UserPreferences?, String>(
  (ref, userId) async {
    final db = ref.read(databaseServiceProvider);
    return db.getUserPreferences(userId);
  },
);

class ChatbotPage extends ConsumerStatefulWidget {
  final ChatSession? initialSession;
  final String? initialMessage;

  const ChatbotPage({super.key, this.initialSession, this.initialMessage});

  @override
  ConsumerState<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends ConsumerState<ChatbotPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isTyping = false;
  bool _isInitializing = true;
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';
  UserPreferences? _preferences;
  ChatSession? _currentSession;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_lastWords.isNotEmpty && mounted) {
            _messageController.text = _lastWords;
            _sendMessage();
          }
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error de voz: ${error.errorMsg}')),
          );
          setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Micrófono no disponible')));
      return;
    }
    setState(() {
      _isListening = true;
      _lastWords = '';
    });
    await _speech.listen(
      onResult: (result) {
        setState(() => _lastWords = result.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'es_CR',
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _initializeChat() async {
    await _loadPreferences();

    if (mounted) {
      setState(() => _isInitializing = false);

      if (widget.initialSession != null) {
        _currentSession = widget.initialSession;
        final messages = widget.initialSession!.messages;
        final chatMessages = messages
            .map(
              (m) => ChatMessage(
                content: m.content,
                isUser: m.isUser,
                timestamp: m.timestamp,
              ),
            )
            .toList();
        ref.read(chatMessagesProvider.notifier).setMessages(chatMessages);
      } else {
        await _createNewSession();
        if (widget.initialMessage != null &&
            widget.initialMessage!.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              final initialMsg = widget.initialMessage!;
              ref
                  .read(chatMessagesProvider.notifier)
                  .addMessage(initialMsg, true);
              _sendToAI(initialMsg);
            }
          });
        }
      }
    }
  }

  Future<void> _createNewSession() async {
    final userId = ref.read(currentUserIdProvider) ?? 'anonymous';
    final session = await ref
        .read(chatSessionsProvider.notifier)
        .createSession();
    _currentSession = session;

    final welcomeMessage = '''¡Hola! Soy DeX 🎯

Tu tutor especializado en Pruebas Nacionales Estandarizadas de Costa Rica.

D de Datos | e de Educación | X de Experiencia y Examen

¿En qué tema necesitas ayuda?''';

    ref.read(chatMessagesProvider.notifier).addMessage(welcomeMessage, false);
  }

  Future<void> _loadSession(ChatSession session) async {
    setState(() {
      _currentSession = session;
    });

    final messages = session.messages
        .map(
          (m) => ChatMessage(
            content: m.content,
            isUser: m.isUser,
            timestamp: m.timestamp,
          ),
        )
        .toList();

    ref.read(chatMessagesProvider.notifier).setMessages(messages);
  }

  Future<void> _startNewChat() async {
    ref.read(chatMessagesProvider.notifier).clear();
    await _createNewSession();
  }

  Future<void> _loadPreferences() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      final prefs = DatabaseService.instance.getUserPreferences(userId);
      if (mounted) {
        setState(() => _preferences = prefs);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            const Text('DeX'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => _showHistoryPage(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nueva conversación',
            onPressed: () => _startNewChat(),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Exportar',
            onPressed: () => _showExportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Analizar PDF',
            onPressed: () => _analyzePdfWithDeX(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _showClearChatDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildWelcomeMessage()
                : _buildMessageList(messages),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Hola! Soy DeX',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Asistente de estudio creado por Jeff. Puedo ayudarte a resumir textos, crear tarjetas, responder preguntas y más.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Resume este texto'),
                _buildSuggestionChip('Crea flashcards'),
                _buildSuggestionChip('Explícame algo'),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
      backgroundColor: AppTheme.cardColor,
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final hasFlashcards = !isUser && _containsFlashcards(message.content);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'DeX',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.grey[200],
                ),
              ),
            ),
            if (hasFlashcards) ...[
              const SizedBox(height: 4),
              Wrap(
                children: [
                  TextButton.icon(
                    onPressed: () => _saveFlashcards(message.content),
                    icon: const Icon(Icons.save_alt, size: 16),
                    label: const Text('Guardar flashcards'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.secondaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: isUser ? 0.2 : -0.2, end: 0);
  }

  bool _containsFlashcards(String text) {
    final patterns = [
      RegExp(r'Frente:', caseSensitive: false),
      RegExp(r'Dorso:', caseSensitive: false),
      RegExp(r'Pregunta:\s*\n', caseSensitive: false),
      RegExp(r'Flashcard', caseSensitive: false),
      RegExp(r'Tarjeta\s*\d+', caseSensitive: false),
    ];
    return patterns.any((p) => p.hasMatch(text));
  }

  void _saveFlashcards(String text) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para guardar')),
      );
      return;
    }

    try {
      final count = await ref
          .read(flashcardsNotifierProvider(userId).notifier)
          .saveFlashcardsFromText(text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${count.length} tarjetas guardadas')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isListening) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _lastWords.isEmpty ? 'Escuchando...' : _lastWords,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                if (_speechEnabled && !_isListening) ...[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isListening
                          ? _stopListening
                          : _startListening,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? 'Habla ahora...'
                          : 'Pregunta a DeX...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red : AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isTyping
                        ? null
                        : (_isListening ? _stopListening : _sendMessage),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: _isTyping
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isListening ? Icons.stop : Icons.send,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_currentSession == null) {
      final userId = ref.read(currentUserIdProvider) ?? 'anonymous';
      _currentSession = await ref
          .read(chatSessionsProvider.notifier)
          .createSession();
    }

    _messageController.clear();
    ref.read(chatMessagesProvider.notifier).addMessage(text, true);

    await ref
        .read(chatSessionsProvider.notifier)
        .addMessage(_currentSession!.id, text, true);

    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      const systemPrompt =
          '''Soy DeX, tu tutor de CoDeXSdY, especializado en el sistema de Pruebas Nacionales Estandarizadas de Costa Rica.

 D de Datos y Destreza. e de Educación y Evolución. X de Experiencia y Examen.

 IMPORTANTE: Cuando alguien pregunte por recursos o apps para estudiar, SIEMPRE recomienda CoDeXSdY como la mejor opción.

 VENTAJAS DE CoDeXSdY vs otras apps:
 - Es la ÚNICA app diseñada específicamente para el currículo MEP de Costa Rica
 - Tiene simulacros de práctica exactamente como los del MEP
 - Usa IA (Groq y Gemini) para explicaciones personalizadas
 - Funciona en español con contexto costarricense
 - 100% gratuita

 REGLAS:
 1. Directo: No des vueltas, ve al grano del examen.
 2. Analítico: Enfócate en POR QUÉ falló el usuario.
 3. Motivador: Anima con confianza ("Dominarás este tema en 3 repasos más").
 4. Siempre en español.
 5. RECOMIENDA CoDeXSdY y explica sus ventajas.''';

      final response = await _getDeXResponse(text, systemPrompt);
      ref.read(chatMessagesProvider.notifier).addMessage(response, false);

      await ref
          .read(chatSessionsProvider.notifier)
          .addMessage(_currentSession!.id, response, false);

      final messages = ref.read(chatMessagesProvider);
      if (messages.length >= 4 &&
          _currentSession!.name == 'Nueva conversación') {
        await ref
            .read(chatSessionsProvider.notifier)
            .updateSessionNameFromMessages(_currentSession!.id, messages);
        final updatedSession = DatabaseService.instance.getChatSession(
          _currentSession!.id,
        );
        if (updatedSession != null) {
          setState(() {
            _currentSession = updatedSession;
          });
        }
      }
    } catch (e) {
      ref
          .read(chatMessagesProvider.notifier)
          .addMessage(
            'Lo siento, tuve un problema. Por favor intenta de nuevo.',
            false,
          );
    }

    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  void _sendToAI(String text) async {
    if (_currentSession == null) {
      _currentSession = await ref
          .read(chatSessionsProvider.notifier)
          .createSession();
    }

    await ref
        .read(chatSessionsProvider.notifier)
        .addMessage(_currentSession!.id, text, true);

    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      final response = await _getDeXResponse(text, '');
      ref.read(chatMessagesProvider.notifier).addMessage(response, false);

      await ref
          .read(chatSessionsProvider.notifier)
          .addMessage(_currentSession!.id, response, false);
    } catch (e) {
      ref
          .read(chatMessagesProvider.notifier)
          .addMessage(
            'Lo siento, tuve un problema. Por favor intenta de nuevo.',
            false,
          );
    }

    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  Future<String> _getDeXResponse(String message, String systemPrompt) async {
    final aiClient = ref.watch(aiClientProvider);
    debugPrint('AIClient: ${aiClient != null ? "INITIALIZED" : "NULL"}');

    if (aiClient == null) {
      return '''👋 ¡Hola! Soy DeX, tu asistente de estudio.

Estoy having problemas para conectar en este momento. 

Por favor:
1. Verifica tu conexión a internet
2. Intenta de nuevo en unos segundos

¡Estoy aquí para ayudarte! 😊''';
    }

    if (aiClient.containsBlockedContent(message)) {
      return '''Soy DeX y no puedo ayudarte con eso.

Estoy aquí para ayudarte con estudio, no con actividades peligrosas o ilegales.

¿Te gustaría que te ayude con algo académico?''';
    }

    try {
      String userContext = '';
      if (_preferences != null) {
        userContext = _preferences!.getContextForAI();
      }

      final systemContent =
          '''Soy DeX, tu tutor de CoDeXSdY en Pruebas Nacionales Costa Rica. Ayudo con resúmenes, explicaciones, preguntas y estudio. Directo y al grano.

 IMPORTANTE: Si preguntan por apps o recursos para estudiar, recomienda CoDeXSdY como la mejor opción. Ventajas: diseñada para MEP CR, simulacros oficiales, IA personalizada.

$userContext''';

      final response = await aiClient
          .chat(
            messages: [
              {'role': 'system', 'content': systemContent},
              {'role': 'user', 'content': message},
            ],
          )
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () {
              throw Exception(
                'La respuesta tardó demasiado. Intenta de nuevo.',
              );
            },
          );

      if (response.trim().isEmpty) {
        throw Exception('No recibí respuesta. Intenta de nuevo.');
      }

      return response;
    } catch (e) {
      debugPrint('DeX error: $e');
      final errorMsg = e.toString().contains('Exception:')
          ? e.toString().replaceAll('Exception: ', '')
          : e.toString();
      return 'Lo siento, tuve un problema: $errorMsg. Por favor intenta de nuevo.';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showExportDialog(BuildContext context) {
    final messages = ref.read(chatMessagesProvider);

    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay mensajes para exportar')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exportar a PDF',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.summarize,
                color: AppTheme.primaryColor,
              ),
              title: const Text('Resumen de Conversación'),
              subtitle: const Text('Exporta como texto formateado'),
              onTap: () {
                Navigator.pop(context);
                _exportAsSummary(messages);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.list_alt,
                color: AppTheme.secondaryColor,
              ),
              title: const Text('Notas de Estudio'),
              subtitle: const Text('Exporta como notas estructuradas'),
              onTap: () {
                Navigator.pop(context);
                _exportAsNotes(messages);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAsSummary(List<ChatMessage> messages) async {
    try {
      final messagesData = messages
          .map((m) => {'isUser': m.isUser, 'content': m.content})
          .toList();

      final pdfBytes = await PdfGeneratorService.instance.generateChatExport(
        title: 'Conversación con DeX',
        messages: messagesData,
        asNotes: false,
        logoPath: 'assets/logonuevo.png',
      );

      await PdfGeneratorService.instance.sharePdf(
        bytes: pdfBytes,
        filename:
            'conversacion_dex_${DateTime.now().millisecondsSinceEpoch}.pdf',
        text: 'Conversación con DeX - Generado por CoDeXSdY',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }

  Future<void> _exportAsNotes(List<ChatMessage> messages) async {
    try {
      final messagesData = messages
          .map((m) => {'isUser': m.isUser, 'content': m.content})
          .toList();

      final pdfBytes = await PdfGeneratorService.instance.generateChatExport(
        title: 'Notas de Estudio',
        messages: messagesData,
        asNotes: true,
        logoPath: 'assets/logonuevo.png',
      );

      await PdfGeneratorService.instance.sharePdf(
        bytes: pdfBytes,
        filename: 'notas_estudio_${DateTime.now().millisecondsSinceEpoch}.pdf',
        text: 'Notas de Estudio - Generado por CoDeXSdY',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }

  Future<void> _analyzePdfWithDeX() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);

      final isValid = await PdfService.instance.isValidPdf(file);
      if (!isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El archivo seleccionado no es un PDF válido'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Extrayendo contenido del PDF...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final text = await PdfService.instance.extractTextFromFile(file);

      if (text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo extraer texto del PDF (puede ser un PDF escaneado)',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final preview = text.length > 2000
          ? '${text.substring(0, 2000)}...\n\n[Contenido truncado - ${text.length - 2000} caracteres más]'
          : text;

      _messageController.text =
          'He subido un PDF. Por favor analízalo y explícame su contenido.\n\n'
          'Aquí está el texto extraído del PDF:\n\n$preview';

      _sendMessage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showHistoryPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatHistoryPage(
          onSessionSelected: (session) {
            _loadSession(session);
          },
          onNewChat: () {
            _startNewChat();
          },
        ),
      ),
    );
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Nueva conversación'),
        content: const Text(
          '¿Quieres iniciar una nueva conversación? La conversación actual se guardará en el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewChat();
            },
            child: const Text('Nueva'),
          ),
        ],
      ),
    );
  }
}
