import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/groq_client.dart';
import '../../../../core/services/pdf_export_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../auth/data/models/user_preferences.dart';

final userPreferencesProvider = FutureProvider.family<UserPreferences?, String>(
  (ref, userId) async {
    final db = ref.read(databaseServiceProvider);
    return db.getUserPreferences(userId);
  },
);

class ChatbotPage extends ConsumerStatefulWidget {
  const ChatbotPage({super.key});

  @override
  ConsumerState<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends ConsumerState<ChatbotPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isSpeaking = false;
  String _currentSpeakingText = '';
  UserPreferences? _preferences;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
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

  void _toggleSpeech(String text) async {
    if (_isSpeaking && _currentSpeakingText == text) {
      await TTSService.instance.stop();
      setState(() {
        _isSpeaking = false;
        _currentSpeakingText = '';
      });
    } else {
      setState(() {
        _isSpeaking = true;
        _currentSpeakingText = text;
      });
      await TTSService.instance.speak(text);
      setState(() {
        _isSpeaking = false;
        _currentSpeakingText = '';
      });
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
            const Text('CoDy'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Seleccionar voz',
            onPressed: () => _showVoiceSelector(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Exportar',
            onPressed: () => _showExportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ref.read(chatMessagesProvider.notifier).clear();
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
              '¡Hola! Soy CoDy',
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
                      'CoDy',
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
            if (!isUser) ...[
              const SizedBox(height: 8),
              Wrap(
                children: [
                  TextButton.icon(
                    onPressed: () => _toggleSpeech(message.content),
                    icon: Icon(
                      _isSpeaking && _currentSpeakingText == message.content
                          ? Icons.stop
                          : Icons.volume_up,
                      size: 16,
                    ),
                    label: Text(
                      _isSpeaking && _currentSpeakingText == message.content
                          ? 'Detener'
                          : 'Escuchar',
                    ),
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
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Pregunta a CoDy...',
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
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isTyping ? null : _sendMessage,
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
                    : const Icon(Icons.send, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    ref.read(chatMessagesProvider.notifier).addMessage(text, true);

    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      const systemPrompt =
          '''Eres CoDy, un asistente de estudio amigable creado por Jeff. 
Ayudas a los estudiantes con resúmenes, flashcards, preguntas y respuestas.
Sé claro, respetuoso y útil. Responde en español.''';

      final response = await _getCoDyResponse(text, systemPrompt);
      ref.read(chatMessagesProvider.notifier).addMessage(response, false);
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

  Future<String> _getCoDyResponse(String message, String systemPrompt) async {
    final groqClient = ref.read(groqClientProvider);

    if (groqClient == null) {
      return '''Hola, soy CoDy. Parece que no tienes configurada tu API key de Groq.

Para activar mis funciones de IA:

1. Obtén una API key en: https://console.groq.com/keys
2. Ejecuta la app así:
   flutter run --dart-define=GROQ_API_KEY=tu_api_key_aqui

¡Una vez configurado, podré ayudarte con resúmenes, flashcards y preguntas!''';
    }

    if (groqClient.containsBlockedContent(message)) {
      return '''Soy CoDy y no puedo ayudarte con eso.

Estoy aquí para ayudarte con estudio, no con actividades peligrosas o ilegales.

¿Te gustaría que te ayude con algo académico?''';
    }

    try {
      String userContext = '';
      if (_preferences != null) {
        userContext = _preferences!.getContextForAI();
      }

      final systemContent =
          '''Eres CoDy, asistente de estudio creado por Jeff. Respondes SIEMPRE en español. Sé amigable, claro y respetuoso. Ayudas con resúmenes, flashcards, preguntas y más. Si alguien menciona suicidio o autolesión, ofrece números de ayuda profesional.

$userContext''';

      final response = await groqClient
          .chat(
            model: 'llama-3.3-70b-versatile',
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
    } on GroqException catch (e) {
      return 'Error de Groq: ${e.message}';
    } catch (e) {
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
      final content = messages
          .map((m) => '${m.isUser ? "Usuario" : "CoDy"}: ${m.content}')
          .join('\n\n');

      final file = await PdfExportService.exportSummary(
        title: 'Conversación con CoDy',
        content: content,
      );

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Generado por CoDeXSdY - CoDy AI');
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
      final content = messages
          .where((m) => !m.isUser)
          .map((m) => '- ${m.content}')
          .join('\n');

      final file = await PdfExportService.exportSummary(
        title: 'Notas de Estudio',
        content: content,
        source: 'Conversación con CoDy',
      );

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Generado por CoDeXSdY - CoDy AI');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }

  void _showVoiceSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Seleccionar Voz',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige cómo quieres que CoDy te hable',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 20),
            ...TTSService.instance.voices.map((voice) {
              final isSelected =
                  TTSService.instance.currentVoice.id == voice.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () async {
                    await TTSService.instance.setVoice(voice);
                    await TTSService.instance.speak('Hola, soy CoDy');
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.2)
                          : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.record_voice_over,
                            color: isSelected ? Colors.white : Colors.grey,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                voice.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.white,
                                ),
                              ),
                              Text(
                                voice.description,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
