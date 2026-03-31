import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../quiz/presentation/pages/quiz_home_page.dart';
import '../../../ai_assistant/presentation/pages/chatbot_page.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeContent(),
    const QuizHomePage(),
    const _ProfileContent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _buildDeXFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0f111a),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Inicio'),
              _buildNavItem(1, Icons.school_rounded, 'Exámenes'),
              _buildNavItem(2, Icons.person_rounded, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeXFAB() {
    return GestureDetector(
          onTap: _showDeXMenu,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 2000.ms,
        )
        .shimmer(duration: 3000.ms, color: Colors.white.withValues(alpha: 0.3));
  }

  void _showDeXMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DeXMenuSheet(),
    );
  }
}

class _DeXMenuSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DeXMenuSheet> createState() => _DeXMenuSheetState();
}

class _DeXMenuSheetState extends ConsumerState<_DeXMenuSheet> {
  final ImagePicker _picker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted && _lastWords.isNotEmpty) {
              _sendToChatbot(_lastWords);
            }
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error de voz: ${error.errorMsg}'),
                action: SnackBarAction(label: 'Configurar', onPressed: () {}),
              ),
            );
            setState(() {
              _speechEnabled = false;
              _isListening = false;
            });
          }
        },
      );
      setState(() {});
    } catch (e) {
      debugPrint('Speech init error: $e');
      if (mounted) {
        setState(() => _speechEnabled = false);
      }
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Microfono no disponible')));
      return;
    }

    setState(() => _isListening = true);
    _lastWords = '';
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
        });
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

  void _sendToChatbot(String question) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatbotPage(initialMessage: question)),
    );
  }

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        Navigator.pop(context);
        _showProcessingDialog();

        try {
          final bytes = await photo.readAsBytes();
          final base64Image = base64Encode(bytes);
          final aiClient = ref.read(aiClientProvider);

          if (aiClient != null) {
            final response = await aiClient.extractTextAndAnalyze(
              imageBase64: base64Image,
            );

            if (mounted) {
              Navigator.pop(context);
              _showAnalysisResult(response);
            }
          } else {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('DeX no está disponible')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al abrir cámara: $e')));
      }
    }
  }

  void _showProcessingDialog() {
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
                  Text('DeX procesando...'),
                  SizedBox(height: 4),
                  Text(
                    'Extrayendo texto y analizando',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnalysisResult(String analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0f111a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 8),
            Text('Análisis de DeX', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: SingleChildScrollView(
            child: Text(
              analysis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _sendToChatbot(analysis);
            },
            icon: const Icon(Icons.chat),
            label: const Text('Preguntar más'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0f111a),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DeX',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Tu asistente de estudio 12.°',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDeXOption(
              context: context,
              icon: Icons.camera_alt_rounded,
              color: Colors.amber,
              title: 'Escanear Apuntes',
              subtitle: 'Tomar foto y analizar con IA',
              onTap: _openCamera,
            ),
            const SizedBox(height: 12),
            _buildDeXOption(
              context: context,
              icon: _isListening ? Icons.stop_circle : Icons.mic_rounded,
              color: Colors.red,
              title: _isListening ? 'Escuchando...' : 'Preguntar por Voz',
              subtitle: _isListening
                  ? (_lastWords.isEmpty ? 'Habla ahora...' : _lastWords)
                  : 'Habla tu duda',
              onTap: _isListening ? _stopListening : _startListening,
              isActive: _isListening,
            ),
            const SizedBox(height: 12),
            _buildDeXOption(
              context: context,
              icon: Icons.psychology_rounded,
              color: Colors.purple,
              title: 'Chat con DeX',
              subtitle: 'Pregunta lo que necesites',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatbotPage()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDeXOption({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.2),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isActive ? 0.4 : 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 500.ms,
                  ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[600],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature estará disponible pronto!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent();

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  final PageController _examPageController = PageController(
    viewportFraction: 0.92,
  );
  int _currentExamIndex = 0;

  final List<Map<String, dynamic>> _examSubjects = [
    {
      'name': 'Matemáticas',
      'icon': Icons.calculate,
      'color': Colors.blue,
      'questions': 50,
      'minutes': 90,
    },
    {
      'name': 'Ciencias',
      'icon': Icons.science,
      'color': Colors.green,
      'questions': 50,
      'minutes': 90,
    },
    {
      'name': 'Estudios Sociales',
      'icon': Icons.public,
      'color': Colors.brown,
      'questions': 50,
      'minutes': 90,
    },
    {
      'name': 'Español',
      'icon': Icons.menu_book,
      'color': Colors.red,
      'questions': 50,
      'minutes': 90,
    },
  ];

  @override
  void dispose() {
    _examPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider) ?? 'guest';
    final userName = ref.watch(userNameProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0f111a),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(userName),
              const SizedBox(height: 16),
              _buildExamOfTheDayCard(context),
              const SizedBox(height: 16),
              _buildRecentDocuments(context, userId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Hola, $name!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '¿Listo para el MEP?',
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1);
  }

  Widget _buildExamOfTheDayCard(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _examPageController,
            onPageChanged: (index) {
              setState(() => _currentExamIndex = index);
            },
            itemCount: _examSubjects.length,
            itemBuilder: (context, index) {
              final subject = _examSubjects[index];
              return _buildExamCard(subject, context, index);
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_examSubjects.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentExamIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentExamIndex == index
                    ? AppTheme.primaryColor
                    : Colors.grey[600],
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildExamCard(
    Map<String, dynamic> subject,
    BuildContext context,
    int index,
  ) {
    final color = subject['color'] as Color;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Examen del Día',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                subject['icon'] as IconData,
                color: Colors.white24,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subject['name'] as String,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${subject['questions']} preguntas • ${subject['minutes']} min',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizHomePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'INICIAR',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Materias',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSubjectIcon(
              context,
              Icons.calculate_rounded,
              Colors.blue,
              'Matemáticas',
              () => _navigateToExam(context, 'Matemáticas'),
            ),
            _buildSubjectIcon(
              context,
              Icons.science_rounded,
              Colors.green,
              'Ciencias',
              () => _navigateToExam(context, 'Ciencias'),
            ),
            _buildSubjectIcon(
              context,
              Icons.menu_book_rounded,
              Colors.orange,
              'Español',
              () => _navigateToExam(context, 'Español'),
            ),
            _buildSubjectIcon(
              context,
              Icons.public_rounded,
              Colors.purple,
              'Estudios',
              () => _navigateToExam(context, 'Estudios Sociales'),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildSubjectIcon(
    BuildContext context,
    IconData icon,
    Color color,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }

  void _navigateToExam(BuildContext context, String subject) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizHomePage()),
    );
  }

  Widget _buildRecentDocuments(BuildContext context, String userId) {
    final recentResults = DatabaseService.instance.getQuizResults(userId)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final displayResults = recentResults.take(3).toList();

    if (displayResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad Reciente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...displayResults.map((result) {
          final subjectNames = [
            'Matemáticas',
            'Ciencias',
            'Estudios Sociales',
            'Español',
            'Inglés',
            'Biología',
            'Química',
            'Física',
            'Historia',
            'Geografía',
            'Cívica',
            'Filosofía',
          ];
          final subject =
              subjectNames[result.categoryIndex.clamp(
                0,
                subjectNames.length - 1,
              )];
          final timeAgo = _getTimeAgo(result.completedAt);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildActivityItem(
              Icons.quiz_rounded,
              result.passed ? Colors.green : Colors.orange,
              'Simulacro MEP',
              '$subject • ${result.correctAnswers}/${result.totalQuestions} correctas',
              timeAgo,
            ),
          );
        }),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} h';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return 'Hace ${(diff.inDays / 7).floor()} sem';
    }
  }

  Widget _buildActivityItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    String time,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _LibraryContent extends ConsumerWidget {
  const _LibraryContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f111a),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Biblioteca',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPDFCard(
                    'Biología',
                    'MEP 12.°',
                    Icons.biotech,
                    Colors.green,
                  ),
                  _buildPDFCard(
                    'Química',
                    'MEP 12.°',
                    Icons.science,
                    Colors.blue,
                  ),
                  _buildPDFCard(
                    'Física',
                    'MEP 12.°',
                    Icons.electric_bolt,
                    Colors.amber,
                  ),
                  _buildPDFCard(
                    'Matemáticas',
                    'MEP 12.°',
                    Icons.calculate,
                    Colors.purple,
                  ),
                  _buildPDFCard(
                    'Estudios Sociales',
                    'MEP 12.°',
                    Icons.public,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPDFCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[600]),
        ],
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final userId = ref.watch(currentUserIdProvider) ?? 'guest';

    return Scaffold(
      backgroundColor: const Color(0xFF0f111a),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildProfileHeader(userName),
              const SizedBox(height: 32),
              _buildStatsGrid(ref),
              const SizedBox(height: 24),
              _buildProgressSection(context, userId),
              const SizedBox(height: 24),
              _buildSettingsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.purple],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '12.° Año • MEP',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider) ?? 'guest';
    final documents = DatabaseService.instance.getDocuments(userId).length;
    final flashcards = DatabaseService.instance.getFlashcards(userId).length;
    final results = DatabaseService.instance.getQuizResults(userId).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Exámenes',
            '$results',
            Icons.quiz,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Flashcards',
            '$flashcards',
            Icons.style,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Docs',
            '$documents',
            Icons.description,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, String userId) {
    final results = DatabaseService.instance.getQuizResults(userId);

    if (results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Icon(Icons.quiz, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Sin exámenes aún',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Completa tu primer simulacro MEP',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final subjectNames = [
      'Matemáticas',
      'Ciencias',
      'Estudios Sociales',
      'Español',
      'Inglés',
      'Biología',
      'Química',
      'Física',
      'Historia',
      'Geografía',
      'Cívica',
      'Filosofía',
    ];
    final subjectColors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.red,
      Colors.cyan,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
      Colors.lime,
    ];
    final Map<int, List<dynamic>> bySubject = {};
    for (final r in results) {
      bySubject.putIfAbsent(r.categoryIndex, () => []).add(r);
    }

    final sortedSubjects = bySubject.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final displaySubjects = sortedSubjects.take(4);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso MEP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...displaySubjects.map((entry) {
            final idx = entry.key;
            final resList = entry.value;
            final totalCorrect = resList.fold<int>(
              0,
              (sum, r) => sum + (r.correctAnswers as int),
            );
            final totalQuestions = resList.fold<int>(
              0,
              (sum, r) => sum + (r.totalQuestions as int),
            );
            final progress = totalQuestions > 0
                ? totalCorrect / totalQuestions
                : 0.0;
            final name = subjectNames[idx.clamp(0, subjectNames.length - 1)];
            final color = subjectColors[idx.clamp(0, subjectColors.length - 1)];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white)),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: color.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildSettingsItem(Icons.notifications, 'Notificaciones', true),
          _buildSettingsItem(Icons.info, 'Acerca de', false),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, bool hasToggle) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[400]),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: hasToggle
          ? Switch(
              value: true,
              onChanged: (v) {},
              activeColor: AppTheme.primaryColor,
            )
          : Icon(Icons.chevron_right, color: Colors.grey[600]),
    );
  }
}
