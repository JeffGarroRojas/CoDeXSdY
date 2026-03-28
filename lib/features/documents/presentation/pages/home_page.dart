import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../quiz/presentation/pages/quiz_home_page.dart';
import '../../../quiz/presentation/pages/quiz_practice_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider) ?? 'guest';

    final db = DatabaseService.instance;
    final docs = db.getDocuments(userId);
    final cards = db.getFlashcards(userId);
    final sessions = db.getSessions(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CoDeXSdY',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuizPracticePage()),
              );
            },
            tooltip: 'Práctica',
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
                onPressed: () => _showAddOptions(context, ref, userId),
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              )
              .animate()
              .fadeIn(delay: 500.ms)
              .slideY(begin: 1, curve: Curves.easeOutBack)
              .then()
              .shimmer(
                delay: 2000.ms,
                duration: 3000.ms,
                color: Colors.white.withValues(alpha: 0.3),
              ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 24),
              _buildStatsRow(docs.length, cards.length, sessions.length),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildDocumentsSection(context, docs),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context, WidgetRef ref, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Qué quieres agregar?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description, color: Colors.blue),
              ),
              title: const Text('Subir Documento'),
              subtitle: const Text('PDF o texto para estudiar'),
              onTap: () {
                Navigator.pop(context);
                _uploadDocument(context, ref, userId);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.style, color: Colors.green),
              ),
              title: const Text('Crear Flashcard'),
              subtitle: const Text('Agregar tarjeta manualmente'),
              onTap: () {
                Navigator.pop(context);
                _showCreateFlashcard(context, ref, userId);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.purple),
              ),
              title: const Text('Generar con IA'),
              subtitle: const Text('Crear flashcards automáticamente'),
              onTap: () {
                Navigator.pop(context);
                _showGenerateWithAI(context, ref, userId);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDocument(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String text = '';
      final fileName = file.name;

      if (file.extension == 'txt' && file.bytes != null) {
        text = String.fromCharCodes(file.bytes!);
      } else if (file.extension == 'pdf') {
        final pdfContext = context;
        _showLoadingDialog(context, 'Extrayendo texto del PDF...');

        try {
          if (file.bytes != null) {
            text = await PdfService.instance.extractTextFromBytes(file.bytes!);
          } else if (file.path != null) {
            final pdfFile = File(file.path!);
            final isValid = await PdfService.instance.isValidPdf(pdfFile);
            if (!isValid) {
              Navigator.pop(pdfContext);
              ScaffoldMessenger.of(pdfContext).showSnackBar(
                const SnackBar(content: Text('El archivo no es un PDF válido')),
              );
              return;
            }
            text = await PdfService.instance.extractTextFromFile(pdfFile);
          } else {
            Navigator.pop(pdfContext);
            ScaffoldMessenger.of(pdfContext).showSnackBar(
              const SnackBar(content: Text('No se pudo acceder al archivo')),
            );
            return;
          }
          Navigator.pop(pdfContext);
        } catch (e) {
          Navigator.pop(pdfContext);
          ScaffoldMessenger.of(
            pdfContext,
          ).showSnackBar(SnackBar(content: Text('Error al procesar PDF: $e')));
          return;
        }
      }

      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo leer el archivo')),
        );
        return;
      }

      final db = DatabaseService.instance;
      await db.createDocument(
        odId: DateTime.now().millisecondsSinceEpoch.toString(),
        title: fileName.replaceAll(RegExp(r'\.[^.]+$'), ''),
        filePath: file.path ?? '',
        extractedText: text,
        userId: userId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Documento "$fileName" agregado!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showCreateFlashcard(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final frontController = TextEditingController();
    final backController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Flashcard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: frontController,
              decoration: const InputDecoration(
                labelText: 'Pregunta',
                hintText: 'Escribe la pregunta...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: backController,
              decoration: const InputDecoration(
                labelText: 'Respuesta',
                hintText: 'Escribe la respuesta...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (frontController.text.isEmpty || backController.text.isEmpty) {
                return;
              }
              final db = DatabaseService.instance;
              await db.createFlashcard(
                front: frontController.text,
                back: backController.text,
                userId: userId,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Flashcard creada!')),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showGenerateWithAI(BuildContext context, WidgetRef ref, String userId) {
    final topicController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crear con CoDy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '¿Qué quieres estudiar?',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: topicController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Tema',
                hintText: 'Ej: civica, matemáticas, biología...',
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Cómo quieres estudiar?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStudyOption(
              context: context,
              ref: ref,
              userId: userId,
              topicController: topicController,
              icon: Icons.style,
              color: Colors.green,
              title: 'Flashcards',
              subtitle: 'Tarjetas para memorizar',
              type: 'flashcards',
            ),
            const SizedBox(height: 8),
            _buildStudyOption(
              context: context,
              ref: ref,
              userId: userId,
              topicController: topicController,
              icon: Icons.summarize,
              color: Colors.blue,
              title: 'Resumen',
              subtitle: 'Resumen del tema',
              type: 'resumen',
            ),
            const SizedBox(height: 8),
            _buildStudyOption(
              context: context,
              ref: ref,
              userId: userId,
              topicController: topicController,
              icon: Icons.quiz,
              color: Colors.orange,
              title: 'Examen Simulado',
              subtitle: 'Preguntas de práctica',
              type: 'examen',
            ),
            const SizedBox(height: 8),
            _buildStudyOption(
              context: context,
              ref: ref,
              userId: userId,
              topicController: topicController,
              icon: Icons.help_outline,
              color: Colors.purple,
              title: 'Preguntas y Respuestas',
              subtitle: 'Explicación del tema',
              type: 'preguntas',
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyOption({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required TextEditingController topicController,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String type,
  }) {
    return InkWell(
      onTap: () async {
        final topic = topicController.text.trim();
        if (topic.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingresa un tema primero')),
          );
          return;
        }
        Navigator.pop(context);

        switch (type) {
          case 'flashcards':
            await _generateFlashcardsWithAI(context, ref, userId, topic);
            break;
          case 'resumen':
            await _generateResumenWithAI(context, ref, userId, topic);
            break;
          case 'examen':
            await _generateExamenWithAI(context, ref, userId, topic);
            break;
          case 'preguntas':
            await _generatePreguntasWithAI(context, ref, userId, topic);
            break;
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Future<void> _generateFlashcardsWithAI(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String topic,
  ) async {
    final groqClient = ref.read(groqClientProvider);
    if (groqClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CoDy no está disponible. Verifica tu conexión.'),
        ),
      );
      return;
    }

    final dialogContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CoDy está generando flashcards...'),
                  SizedBox(height: 4),
                  Text(
                    'Esto puede tardar unos segundos',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final response = await groqClient
          .generateFlashcardsFromTopic(topic: topic, count: 5)
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () {
              throw Exception(
                'La generación tardó demasiado. Intenta de nuevo.',
              );
            },
          );

      if (response.trim().isEmpty) {
        throw Exception('No se recibieron flashcards. Intenta de nuevo.');
      }

      final db = DatabaseService.instance;
      int created = 0;

      final flashcards = _parseFlashcardsResponse(response);
      if (flashcards.isEmpty) {
        throw Exception('No pude entender las flashcards generadas.');
      }

      for (final card in flashcards) {
        await db.createFlashcard(
          front: card['front']!,
          back: card['back']!,
          tags: [topic],
          userId: userId,
        );
        created++;
      }

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text('¡$created flashcards generadas sobre $topic!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        final errorMsg = e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Error al generar flashcards: $e';
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, String>> _parseFlashcardsResponse(String response) {
    final results = <Map<String, String>>[];
    final frontPattern = RegExp(
      r'(?:Frente|Pregunta|Pregunta:|Front:)\s*(.+?)(?:\n|Dorso:|Respuesta:|Answer:|Back:)',
      dotAll: true,
    );
    final backPattern = RegExp(
      r'(?:Dorso|Respuesta|Answer|Back):\s*(.+?)(?=\n\n|Frente|Pregunta|$)',
      dotAll: true,
    );

    final fronts = frontPattern.allMatches(response);
    final backs = backPattern.allMatches(response);

    final frontList = fronts
        .map((m) => m.group(1)?.trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final backList = backs
        .map((m) => m.group(1)?.trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    for (int i = 0; i < frontList.length && i < backList.length; i++) {
      results.add({'front': frontList[i], 'back': backList[i]});
    }

    return results;
  }

  Future<void> _generateResumenWithAI(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String topic,
  ) async {
    final groqClient = ref.read(groqClientProvider);
    if (groqClient == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CoDy no está disponible.')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CoDy está creando el resumen...'),
                  const SizedBox(height: 4),
                  Text(
                    'Analizando: $topic',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final response = await groqClient
          .generateSummary(content: topic, maxTokens: 800)
          .timeout(const Duration(seconds: 90));

      if (response.trim().isEmpty) {
        throw Exception('No recibí respuesta. Intenta de nuevo.');
      }

      if (context.mounted) {
        Navigator.pop(context);
        _showResumenDialog(context, topic, response);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        final errorMsg = e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Error: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showResumenDialog(BuildContext context, String topic, String resumen) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.summarize, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text('Resumen: $topic')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(resumen, style: const TextStyle(fontSize: 14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateExamenWithAI(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String topic,
  ) async {
    final groqClient = ref.read(groqClientProvider);
    if (groqClient == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CoDy no está disponible.')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CoDy está creando tu examen...'),
                  SizedBox(height: 4),
                  Text(
                    'Generando preguntas de práctica',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final response = await groqClient
          .chat(
            messages: [
              {
                'role': 'system',
                'content':
                    'Eres CoDy, asistente de estudio. Genera un mini examen de 5 preguntas de opción múltiple sobre el tema dado. Formato: Pregunta: ... A) ... B) ... C) ... D) ... Respuesta: (letra correcta)',
              },
              {'role': 'user', 'content': 'Crea un examen sobre: $topic'},
            ],
            maxTokens: 2000,
          )
          .timeout(const Duration(seconds: 90));

      if (response.trim().isEmpty) {
        throw Exception('No recibí respuesta. Intenta de nuevo.');
      }

      if (context.mounted) {
        Navigator.pop(context);
        _showExamenDialog(context, topic, response);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        final errorMsg = e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Error: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showExamenDialog(BuildContext context, String topic, String examen) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.quiz, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text('Examen: $topic')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: SingleChildScrollView(
            child: Text(examen, style: const TextStyle(fontSize: 14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePreguntasWithAI(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String topic,
  ) async {
    final groqClient = ref.read(groqClientProvider);
    if (groqClient == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CoDy no está disponible.')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CoDy está explicando...'),
                  SizedBox(height: 4),
                  Text(
                    'Preparando el tema para ti',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final response = await groqClient
          .chat(
            messages: [
              {
                'role': 'system',
                'content':
                    'Eres CoDy, asistente de estudio. Explica el tema de forma clara y amigable. Usa ejemplos y haz que sea fácil de entender. Estructura la respuesta con puntos clave.',
              },
              {'role': 'user', 'content': 'Explícame sobre: $topic'},
            ],
            maxTokens: 1500,
          )
          .timeout(const Duration(seconds: 90));

      if (response.trim().isEmpty) {
        throw Exception('No recibí respuesta. Intenta de nuevo.');
      }

      if (context.mounted) {
        Navigator.pop(context);
        _showPreguntasDialog(context, topic, response);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        final errorMsg = e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Error: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPreguntasDialog(
    BuildContext context,
    String topic,
    String explicacion,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: Colors.purple),
            const SizedBox(width: 8),
            Expanded(child: Text('Aprende: $topic')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: Text(
              explicacion,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.waving_hand, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '¡Bienvenido de vuelta!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Continúa aprendiendo con CoDy',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.2)
        .shimmer(
          delay: 1000.ms,
          duration: 2000.ms,
          color: Colors.white.withValues(alpha: 0.2),
        );
  }

  Widget _buildStatsRow(int docCount, int cardCount, int sessionCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Documentos',
            docCount,
            Icons.description,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Flashcards',
            cardCount,
            Icons.style,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Sesiones',
            sessionCount,
            Icons.timer,
            Colors.orange,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: count),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Exámenes MEP',
                Icons.school,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizHomePage()),
                ),
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Práctica Libre',
                Icons.quiz,
                Colors.teal,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizPracticePage()),
                ),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context, List<dynamic> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentos Recientes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (docs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No hay documentos aún',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sube documentos para crear flashcards automáticamente',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...docs
              .take(3)
              .map(
                (doc) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          doc.title ?? 'Sin título',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }
}
