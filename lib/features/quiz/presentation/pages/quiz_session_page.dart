import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/pdf_generator_service.dart';
import '../../data/models/question.dart';
import '../../../../core/providers/app_providers.dart';

class QuizSessionPage extends ConsumerStatefulWidget {
  final int levelIndex;
  final String subjectName;
  final int subjectIndex;
  final int questionCount;
  final int durationMinutes;
  final List<String> topics;

  const QuizSessionPage({
    super.key,
    required this.levelIndex,
    required this.subjectName,
    required this.subjectIndex,
    required this.questionCount,
    required this.durationMinutes,
    required this.topics,
  });

  @override
  ConsumerState<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends ConsumerState<QuizSessionPage> {
  late List<Question> _questions;
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  late int _remainingSeconds;
  Timer? _timer;
  int _correctAnswers = 0;
  int _hintedCorrectAnswers = 0;
  final List<int> _userAnswers = [];
  final List<bool> _usedHint = [];
  final List<int?> _eliminatedOptions = [];
  final List<int> _questionTimes = [];
  int _questionStartTime = 0;
  bool _examFinished = false;
  bool _isAnalyzing = false;
  String? _aiAnalysis;
  String _analyzingMessage = 'Preparando análisis...';
  bool _isGeneratingNewQuestions = false;
  String _generatingMessage = 'Preparando nuevas preguntas...';
  List<Question>? _newQuestions;
  Timer? _loadingTimer;
  int _loadingIndex = 0;
  bool _isLoading = true;
  String _loadingMessage = 'DeX está generando el examen...';
  bool _isGeneratingPDF = false;
  String _pdfMessage = 'Generando resumen...';

  @override
  void initState() {
    super.initState();
    final timePerQuestion = 1.8;
    _remainingSeconds = (widget.questionCount * timePerQuestion * 60).round();
    _generateExamWithAI();
  }

  Future<void> _generateExamWithAI() async {
    final aiClient = ref.read(aiClientProvider);

    if (aiClient == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'DeX no está disponible. Cargando preguntas locales...',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        _loadLocalQuestions();
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage =
          'DeX está generando el examen de ${widget.subjectName}...';
    });

    _showLoadingDialog();

    try {
      final allQuestions = <Question>[];
      const totalLotes = 5;
      const preguntasPorLote = 10;

      for (int lote = 1; lote <= totalLotes; lote++) {
        setState(() {
          _loadingMessage =
              'Generando lote $lote/$totalLotes de $preguntasPorLote preguntas...';
        });

        final response = await aiClient
            .generateMEPLote(
              subject: widget.subjectName,
              topics: widget.topics,
              loteNumber: lote,
              count: preguntasPorLote,
            )
            .timeout(const Duration(seconds: 180));

        final loteQuestions = _parseJSONQuestions(response);
        allQuestions.addAll(loteQuestions);
      }

      if (mounted) {
        Navigator.pop(context);
      }

      if (allQuestions.isNotEmpty) {
        setState(() {
          _questions = allQuestions;
          _isLoading = false;
        });
        _initializeExam();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '¡Examen generado! ${allQuestions.length} preguntas listas',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('No se pudieron entender las preguntas generadas');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll("Exception: ", "")}. Usando preguntas locales.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      _loadLocalQuestions();
    }
  }

  List<Question> _parseJSONQuestions(String response) {
    final questions = <Question>[];

    try {
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;

      if (jsonStart == -1 || jsonEnd == 0) {
        debugPrint('No se encontró JSON válido en la respuesta');
        return [];
      }

      final jsonStr = response.substring(jsonStart, jsonEnd);
      final data = json.decode(jsonStr) as List;

      for (int i = 0; i < data.length; i++) {
        final item = data[i] as Map<String, dynamic>;
        final options = List<String>.from(item['options'] ?? []);

        if (options.length < 4) {
          while (options.length < 4) {
            options.add('Opción adicional');
          }
        }

        questions.add(
          Question.create(
            odId: 'mep_${DateTime.now().microsecondsSinceEpoch}_$i',
            question: item['question'] ?? '',
            options: options.take(4).toList(),
            correctAnswerIndex: (item['correctIndex'] ?? 0).clamp(0, 3),
            explanation: item['explanation'] ?? 'Respuesta correcta.',
            categoryIndex: widget.subjectIndex,
            levelIndex: 2,
            topic: item['topic'] ?? widget.subjectName,
          ),
        );
      }

      debugPrint('Parsed ${questions.length} preguntas del JSON');
    } catch (e) {
      debugPrint('Error parseando JSON: $e');
    }

    return questions;
  }

  void _showLoadingDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              Timer.periodic(const Duration(milliseconds: 500), (timer) {
                if (!mounted || !context.mounted) {
                  timer.cancel();
                  return;
                }
                setDialogState(() {
                  _loadingIndex = (_loadingIndex + 1) % 4;
                });
              });

              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedOpacity(
                            opacity: _loadingIndex >= index ? 1.0 : 0.3,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: AppTheme.primaryColor,
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _loadingMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Máximo 2 minutos',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }

  void _loadLocalQuestions() {
    final localQuestions = _getQuestionsForSubject(
      widget.subjectIndex,
      widget.levelIndex,
    );
    localQuestions.shuffle();

    setState(() {
      _questions = localQuestions.take(widget.questionCount).toList();
      _isLoading = false;
    });
    _initializeExam();
  }

  void _initializeExam() {
    _questions.shuffle();
    for (int i = 0; i < _questions.length; i++) {
      _usedHint.add(false);
      _eliminatedOptions.add(null);
    }
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _finishExam();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _selectAnswer(int index) {
    if (_answered) return;

    final question = _questions[_currentIndex];
    final isCorrectAnswer = question.isCorrect(index);
    final usedHint = _usedHint[_currentIndex];

    setState(() {
      _selectedAnswer = index;
      _answered = true;
      _userAnswers.add(index);

      if (isCorrectAnswer) {
        _correctAnswers++;
        if (usedHint) {
          _hintedCorrectAnswers++;
        }
      }
    });
  }

  void _useHint() {
    if (_answered || _usedHint[_currentIndex]) return;

    final question = _questions[_currentIndex];
    final correctIndex = question.correctAnswerIndex;

    List<int> wrongIndices = [];
    for (int i = 0; i < question.options.length; i++) {
      if (i != correctIndex) {
        wrongIndices.add(i);
      }
    }

    wrongIndices.shuffle();
    final eliminated = wrongIndices.first;

    setState(() {
      _usedHint[_currentIndex] = true;
      _eliminatedOptions[_currentIndex] = eliminated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pista usada: Se eliminó una opción incorrecta. '
                'Si aciertas, solo contarás 0.5 puntos.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[800],
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Entendido',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      _finishExam();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _selectedAnswer =
            _userAnswers.isNotEmpty && _userAnswers.length > _currentIndex
            ? _userAnswers[_currentIndex]
            : null;
        _answered = _selectedAnswer != null;
      });
    }
  }

  void _finishExam() {
    _timer?.cancel();
    _saveQuizResult();
    setState(() => _examFinished = true);
  }

  Future<void> _saveQuizResult() async {
    final userId = ref.read(currentUserIdProvider) ?? 'demo';
    await DatabaseService.instance.saveQuizResult(
      odId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      totalQuestions: _questions.length,
      correctAnswers: _correctAnswers,
      levelIndex: widget.levelIndex,
      categoryIndex: widget.subjectIndex,
      durationSeconds: widget.durationMinutes * 60 - _remainingSeconds,
      userAnswers: _userAnswers,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
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
                      Icons.auto_awesome,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: 1500.ms,
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
              const SizedBox(height: 32),
              Text(
                'Generando examen...',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'DeX está creando ${widget.questionCount} preguntas sobre ${widget.subjectName}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (_examFinished) {
      return _buildResultsPage();
    }
    return _buildExamPage();
  }

  Widget _buildExamPage() {
    final question = _questions[_currentIndex];
    final isLowTime = _remainingSeconds < 300;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showExitDialog,
          ),
          title: Text(widget.subjectName),
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLowTime
                    ? Colors.red.withValues(alpha: 0.2)
                    : AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 18,
                    color: isLowTime ? Colors.red : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isLowTime ? Colors.red : AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Column(
          children: [
            _buildProgress(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildQuestionCard(question),
                    const SizedBox(height: 20),
                    _buildOptions(question),
                    if (_answered) ...[
                      const SizedBox(height: 20),
                      _buildExplanation(question),
                    ],
                  ],
                ),
              ),
            ),
            if (_answered) _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pregunta ${_currentIndex + 1} de ${_questions.length}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${(_currentIndex + 1) * 100 ~/ _questions.length}%',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: AppTheme.surfaceColor,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.2),
            AppTheme.secondaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Pregunta ${_currentIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (!_usedHint[_currentIndex] && !_answered)
                IconButton(
                  icon: const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber,
                  ),
                  onPressed: _useHint,
                  tooltip: 'Usar pista (-0.5 punto)',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildOptions(Question question) {
    final letters = ['A', 'B', 'C', 'D'];
    final eliminatedIndex = _eliminatedOptions[_currentIndex];

    return Column(
      children: List.generate(question.options.length, (index) {
        if (eliminatedIndex == index && !_answered) {
          return const SizedBox.shrink();
        }

        final isSelected = _selectedAnswer == index;
        final isCorrect = question.correctAnswerIndex == index;

        Color? bgColor;
        Color? borderColor;
        IconData? icon;

        if (_answered) {
          if (isCorrect) {
            bgColor = Colors.green.withValues(alpha: 0.2);
            borderColor = Colors.green;
            icon = Icons.check_circle;
          } else if (isSelected && !isCorrect) {
            bgColor = Colors.red.withValues(alpha: 0.2);
            borderColor = Colors.red;
            icon = Icons.cancel;
          }
        } else if (isSelected) {
          bgColor = AppTheme.primaryColor.withValues(alpha: 0.2);
          borderColor = AppTheme.primaryColor;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _selectAnswer(index),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor ?? AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor ?? Colors.grey.withValues(alpha: 0.3),
                  width: isSelected || (_answered && isCorrect) ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected || (_answered && isCorrect)
                          ? (borderColor ?? AppTheme.primaryColor)
                          : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        letters[index],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected || (_answered && isCorrect)
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question.options[index],
                      style: TextStyle(
                        fontSize: 15,
                        color: isSelected && !_answered
                            ? borderColor
                            : Colors.grey[200],
                      ),
                    ),
                  ),
                  if (icon != null)
                    Icon(icon, color: borderColor ?? Colors.green),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
      }),
    );
  }

  Widget _buildExplanation(Question question) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Explicación',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.explanation,
            style: TextStyle(color: Colors.grey[300], height: 1.4),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousQuestion,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (_currentIndex > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _nextQuestion,
              icon: Icon(
                _currentIndex == _questions.length - 1
                    ? Icons.check
                    : Icons.arrow_forward,
              ),
              label: Text(
                _currentIndex == _questions.length - 1
                    ? 'Finalizar'
                    : 'Siguiente',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir del examen?'),
        content: const Text('Si sales ahora, no se guardarán tus respuestas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPage() {
    final percentage = (_correctAnswers / _questions.length * 100).round();
    final topicStats = _calculateTopicStats();
    final timeStats = _calculateTimeStats();

    return Scaffold(
      backgroundColor: const Color(0xFF0f111a),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildThermometerGauge(percentage),
              const SizedBox(height: 24),
              _buildMessageByPercentage(percentage),
              const SizedBox(height: 24),
              _buildTimeComparison(timeStats),
              const SizedBox(height: 24),
              _buildTopicBreakdown(topicStats),
              const SizedBox(height: 24),
              if (_isAnalyzing)
                _buildLoadingCard(_analyzingMessage)
              else if (_aiAnalysis != null)
                _buildAIAnalysisCard()
              else
                _buildDeXActionCard(topicStats),
              const SizedBox(height: 24),
              _buildResultsActions(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThermometerGauge(int percentage) {
    Color gaugeColor;
    String status;
    IconData statusIcon;

    if (percentage < 60) {
      gaugeColor = Colors.red;
      status = 'Alerta';
      statusIcon = Icons.warning_rounded;
    } else if (percentage < 80) {
      gaugeColor = Colors.amber;
      status = 'Cerca de la meta';
      statusIcon = Icons.trending_up;
    } else {
      gaugeColor = Colors.green;
      status = '¡Dominio Total!';
      statusIcon = Icons.emoji_events;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Termómetro MEP',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: gaugeColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: gaugeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: gaugeColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: TextStyle(
                        color: gaugeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation(gaugeColor),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0%',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                '50%',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                '100%',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildMessageByPercentage(int percentage) {
    String message;
    Color color;

    if (percentage < 60) {
      message =
          'Necesitas reforzar este tema. Revisa los errores y practica más.';
      color = Colors.red;
    } else if (percentage < 80) {
      message = '¡Vas bien! Repasa los temas donde fallaste para mejorar.';
      color = Colors.amber;
    } else {
      message = '¡Excelente! Estás listo para las Pruebas Nacionales.';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.grey[300])),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildTimeComparison(Map<String, dynamic> timeStats) {
    final avgTime = timeStats['avgTime'] as double;
    final idealTime = 1.8;
    final isSlow = avgTime > idealTime * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: isSlow ? Colors.orange : Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Análisis de Tiempo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeStat(
                  'Promedio',
                  '${avgTime.toStringAsFixed(1)} min',
                  avgTime <= idealTime ? Colors.green : Colors.orange,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[700]),
              Expanded(
                child: _buildTimeStat(
                  'Ideal',
                  '${idealTime.toStringAsFixed(1)} min',
                  Colors.blue,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[700]),
              Expanded(
                child: _buildTimeStat(
                  'Total',
                  '${timeStats['totalMinutes']} min',
                  Colors.purple,
                ),
              ),
            ],
          ),
          if (isSlow) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.speed, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Zona de peligro: Dedicaste demasiado tiempo por pregunta',
                      style: TextStyle(color: Colors.orange[300], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildTimeStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildTopicBreakdown(Map<String, List<int>> topicStats) {
    final topics = topicStats.entries.toList()
      ..sort((a, b) {
        final aPct = a.value[1] / (a.value[0] == 0 ? 1 : a.value[0]);
        final bPct = b.value[1] / (b.value[0] == 0 ? 1 : b.value[0]);
        return aPct.compareTo(bPct);
      });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bookmark, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Desglose por Temas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topics.map((entry) {
            final total = entry.value[0];
            final correct = entry.value[1];
            final pct = total > 0 ? (correct / total * 100).round() : 0;
            final isWeak = pct < 70;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '$correct/$total',
                            style: TextStyle(
                              color: isWeak ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (isWeak ? Colors.red : Colors.green)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$pct%',
                              style: TextStyle(
                                color: isWeak ? Colors.red : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isWeak) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _askDeXAboutTopic(entry.key),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.purple,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation(
                        pct >= 90
                            ? Colors.green
                            : pct >= 70
                            ? Colors.amber
                            : Colors.red,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildDeXActionCard(Map<String, List<int>> topicStats) {
    final weakTopics = topicStats.entries
        .where((e) {
          final pct = e.value[0] > 0 ? e.value[1] / e.value[0] : 0;
          return pct < 0.7;
        })
        .take(1)
        .toList();

    if (weakTopics.isEmpty) return const SizedBox.shrink();

    final weakTopic = weakTopics.first.key;
    final wrongCount = weakTopics.first.value[0] - weakTopics.first.value[1];

    return GestureDetector(
      onTap: () => _askDeXAboutTopic(weakTopic),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.blue, Colors.purple]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿DeX, por qué fallé?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Analiza tus $wrongCount errores en "$weakTopic" y genera un plan de estudio.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Map<String, List<int>> _calculateTopicStats() {
    final stats = <String, List<int>>{};
    for (int i = 0; i < _questions.length; i++) {
      final topic = _questions[i].topic;
      if (!stats.containsKey(topic)) {
        stats[topic] = [0, 0];
      }
      stats[topic]![0]++;
      if (_questions[i].isCorrect(_userAnswers[i])) {
        stats[topic]![1]++;
      }
    }
    return stats;
  }

  Map<String, dynamic> _calculateTimeStats() {
    if (_questionTimes.isEmpty) {
      return {'avgTime': 1.8, 'totalMinutes': 90};
    }

    final totalSeconds = _questionTimes.fold<int>(0, (a, b) => a + b);
    final totalMinutes = (totalSeconds / 60).round();
    final avgTime = totalSeconds / _questionTimes.length / 60;

    return {'avgTime': avgTime, 'totalMinutes': totalMinutes};
  }

  Future<void> _askDeXAboutTopic(String topic) async {
    setState(() {
      _isAnalyzing = true;
      _analyzingMessage = 'DeX analiza "$topic"...';
    });

    final aiClient = ref.read(aiClientProvider);
    if (aiClient == null) {
      setState(() {
        _isAnalyzing = false;
        _aiAnalysis = 'DeX no está disponible.';
      });
      return;
    }

    final wrongQuestions = <Map<String, dynamic>>[];
    for (int i = 0; i < _questions.length; i++) {
      if (_questions[i].topic == topic &&
          !_questions[i].isCorrect(_userAnswers[i])) {
        wrongQuestions.add(_questions[i].toMap());
      }
    }

    try {
      final analysis = await aiClient
          .chat(
            messages: [
              {
                'role': 'system',
                'content':
                    '''Soy DeX, tu tutor en Pruebas Nacionales Costa Rica.

El estudiante falló en "$topic". 

MÍO DIRECTO Y ANALÍTICO:
1. Di POR QUÉ falló (error común específico)
2. Explica el concepto en 2 líneas MAX
3. Dame un consejo para recordar
4. Anima: "Lo dominarás en 3 repasos"

Máximo 150 palabras. Sin rodeos.''',
              },
              {
                'role': 'user',
                'content':
                    'Fallaste en:\n${wrongQuestions.map((q) => '- ${q["question"]}').join("\n")}\n\n¿Por qué fallé y qué debo hacer?',
              },
            ],
            maxTokens: 1500,
          )
          .timeout(const Duration(seconds: 60));

      setState(() {
        _aiAnalysis = analysis;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _aiAnalysis = 'Error al analizar. Intenta de nuevo.';
      });
    }
  }

  Widget _buildResultsActions() {
    final incorrectCount = _questions.length - _correctAnswers;

    return Column(
      children: [
        if (_isGeneratingPDF)
          _buildLoadingCard(_pdfMessage)
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generateSummaryPDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Descargar Resumen en PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red[700],
              ),
            ),
          ).animate().fadeIn(delay: 600.ms),
        const SizedBox(height: 12),
        if (incorrectCount > 0)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showReviewMistakes(context),
              icon: const Icon(Icons.rate_review),
              label: Text('Revisar $incorrectCount errores'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ).animate().fadeIn(delay: 700.ms),
        const SizedBox(height: 12),
        if (_isGeneratingNewQuestions)
          _buildLoadingCard(_generatingMessage)
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _retakeWithNewQuestions,
              icon: const Icon(Icons.refresh),
              label: const Text('Repetir con preguntas diferentes'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ).animate().fadeIn(delay: 800.ms),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _saveResultToProfile();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Guardar y Volver al Inicio'),
          ),
        ).animate().fadeIn(delay: 900.ms),
      ],
    );
  }

  Future<void> _saveResultToProfile() async {
    try {
      final db = ref.read(databaseServiceProvider);
      final userId = ref.read(currentUserIdProvider) ?? 'guest';
      final odId = 'quiz_${DateTime.now().millisecondsSinceEpoch}';
      final totalTime = _remainingSeconds > 0
          ? (widget.questionCount * 1.8 * 60).round() - _remainingSeconds
          : 0;

      await db.saveQuizResult(
        odId: odId,
        userId: userId,
        totalQuestions: _questions.length,
        correctAnswers: _correctAnswers,
        levelIndex: widget.levelIndex,
        categoryIndex: widget.subjectIndex,
        durationSeconds: totalTime,
        userAnswers: _userAnswers,
      );

      debugPrint('Resultado guardado: $odId');
    } catch (e) {
      debugPrint('Error guardando resultado: $e');
    }
  }

  // TODO: Eliminar código duplicado entre aquí y _ReviewMistakesPage

  Widget _buildLoadingCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(strokeWidth: 3),
                Icon(Icons.psychology, color: AppTheme.primaryColor, size: 28),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              message,
              key: ValueKey(message),
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildAIAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.2),
            AppTheme.secondaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Análisis de DeX',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _aiAnalysis!,
            style: TextStyle(color: Colors.grey[300], height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildActionButtons(bool passed, int incorrectCount) {
    return Column(
      children: [
        if (_aiAnalysis == null && !_isAnalyzing)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _analyzeResults,
              icon: const Icon(Icons.psychology),
              label: const Text('Análisis con DeX'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),
        if (incorrectCount > 0)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showReviewMistakes(context),
              icon: const Icon(Icons.rate_review),
              label: Text('Revisar $incorrectCount errores'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 12),
        if (_isGeneratingPDF)
          _buildLoadingCard(_pdfMessage)
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generateSummaryPDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Descargar Resumen en PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red[700],
              ),
            ),
          ).animate().fadeIn(delay: 550.ms),
        const SizedBox(height: 12),
        if (_isGeneratingNewQuestions)
          _buildLoadingCard(_generatingMessage)
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _retakeWithNewQuestions,
              icon: const Icon(Icons.refresh),
              label: const Text('Repetir con preguntas diferentes'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  Future<void> _analyzeResults() async {
    setState(() {
      _isAnalyzing = true;
      _analyzingMessage = 'Preparando análisis...';
      _loadingIndex = 0;
    });

    final messages = [
      'Analizando respuestas...',
      'Revisando ${widget.subjectName}...',
      'Identificando temas difíciles...',
      'Generando recomendaciones...',
      'Casi listo...',
    ];

    _loadingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_loadingIndex < messages.length - 1 && mounted) {
        setState(() {
          _loadingIndex++;
          _analyzingMessage = messages[_loadingIndex];
        });
      }
    });

    final aiClient = ref.read(aiClientProvider);
    if (aiClient == null) {
      _loadingTimer?.cancel();
      setState(() {
        _isAnalyzing = false;
        _aiAnalysis =
            'DeX no está disponible en este momento. '
            'Asegúrate de tener conexión a internet.';
      });
      return;
    }

    try {
      final questionData = _questions.map((q) => q.toMap()).toList();
      final analysis = await aiClient
          .analyzeQuizResults(
            questions: questionData,
            userAnswers: _userAnswers,
            subject: widget.subjectName,
            level: widget.levelIndex + 10,
          )
          .timeout(const Duration(seconds: 60));

      _loadingTimer?.cancel();
      if (mounted) {
        setState(() {
          _aiAnalysis = analysis;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      _loadingTimer?.cancel();
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _aiAnalysis =
              'No pude analizar los resultados. '
              'Revisa los temas: ${_getWeakTopics().join(", ")}';
        });
      }
    }
  }

  List<String> _getWeakTopics() {
    final weakTopics = <String, int>{};
    for (int i = 0; i < _questions.length; i++) {
      if (!_questions[i].isCorrect(_userAnswers[i])) {
        final topic = _questions[i].topic;
        weakTopics[topic] = (weakTopics[topic] ?? 0) + 1;
      }
    }
    final sorted = weakTopics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }

  Future<void> _generateSummaryPDF() async {
    setState(() {
      _isGeneratingPDF = true;
      _pdfMessage = 'Preparando resumen...';
    });

    final aiClient = ref.read(aiClientProvider);
    String summaryContent;

    if (aiClient != null) {
      try {
        final topics = _getUniqueTopics();
        setState(() => _pdfMessage = 'DeX está escribiendo el resumen...');

        final response = await aiClient
            .chat(
              messages: [
                {
                  'role': 'system',
                  'content':
                      '''Soy DeX, tu tutor en Pruebas Nacionales Costa Rica.

Genera resúmenes DIRECTOS para el examen:
- Nombre del tema en **negrita** (con ** al inicio y final)
- Definición: 1 línea
- Ejemplo: Práctico y claro (usa "Ejemplo:" al inicio)
- Consejo: Para no olvidarlo (usa "Consejo:" al inicio)

Máximo conciso. Ve al grano.''',
                },
                {
                  'role': 'user',
                  'content':
                      'Resumen para ${widget.subjectName}:\n${topics.join("\n")}\n\n'
                      'Para cada tema incluye:\n1. **Nombre del tema**\n2. Una definición de 1-2 oraciones\n3. Un ejemplo práctico simple (comienza con "Ejemplo:")\n4. Un consejo para recordar (comienza con "Consejo:")\n\nSé muy conciso y claro.',
                },
              ],
              maxTokens: 8000,
            )
            .timeout(const Duration(seconds: 120));

        summaryContent = response;
      } catch (e) {
        summaryContent = _getLocalSummary();
      }
    } else {
      summaryContent = _getLocalSummary();
    }

    try {
      final pdfBytes = await PdfGeneratorService.instance.generateSummary(
        title: 'Resumen de ${widget.subjectName}',
        subject: widget.subjectName,
        content: summaryContent,
        logoPath: 'assets/logonuevo.png',
      );

      await PdfGeneratorService.instance.sharePdf(
        bytes: pdfBytes,
        filename:
            'resumen_${widget.subjectName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        text: 'Resumen de ${widget.subjectName} - Generado por CoDeXSdY',
      );

      if (mounted) {
        setState(() => _isGeneratingPDF = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resumen descargado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingPDF = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _getUniqueTopics() {
    final topics = <String>{};
    for (final q in _questions) {
      topics.add(q.topic);
    }
    return topics.toList();
  }

  String _getLocalSummary() {
    final topics = _getUniqueTopics();
    final buffer = StringBuffer();

    for (final topic in topics) {
      buffer.writeln('**$topic**');
      buffer.writeln(_getTopicSummary(topic));
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _getTopicSummary(String topic) {
    final summaries =
        _localTopicSummaries[topic] ??
        'Tema importante de ${widget.subjectName}. Repasa los conceptos básicos.';
    return summaries;
  }

  static const Map<String, String> _localTopicSummaries = {
    'Álgebra':
        'Rama de las matemáticas que usa letras y símbolos para representar números.\n'
        'Ejemplo: Si 2x + 3 = 7, entonces x = 2.\n'
        'Consejo: Siempre aísla la variable en un lado de la ecuación.',
    'Geometría':
        'Estudia las formas, tamaños y posiciones de figuras.\n'
        'Ejemplo: Un triángulo tiene 3 lados y la suma de sus ángulos es 180°.\n'
        'Consejo: Memoriza las fórmulas de áreas y perímetros.',
    'Estadística':
        'Ciencia de recopilar y analizar datos.\n'
        'Ejemplo: La media (promedio) de 4, 6, 8 es (4+6+8)/3 = 6.\n'
        'Consejo: Moda = lo que más se repite. Mediana = el del medio.',
    'Funciones':
        'Relación donde cada entrada tiene una única salida.\n'
        'Ejemplo: y = 2x + 1. Si x=3, entonces y=7.\n'
        'Consejo: Una función es como una máquina que transforma inputs en outputs.',
    'Trigonometría':
        'Estudia las relaciones entre los lados y ángulos de triángulos.\n'
        'Ejemplo: sen(30°) = 0.5, cos(60°) = 0.5, tan(45°) = 1.\n'
        'Consejo: SOH-CAH-TOA: Seno=Opuesto/Hipotenusa, etc.',
    'Biología':
        'Ciencia que estudia los seres vivos.\n'
        'Ejemplo: La célula es la unidad básica de la vida.\n'
        'Consejo: ADN guarda información genética, ARN la copia.',
    'Química':
        'Ciencia que estudia la materia y sus transformaciones.\n'
        'Ejemplo: El agua (H2O) se forma con 2 átomos de hidrógeno y 1 de oxígeno.\n'
        'Consejo: La tabla periódica organiza los elementos por número atómico.',
    'Física':
        'Ciencia que estudia la materia, energía y sus interacciones.\n'
        'Ejemplo: F = ma. Si m=10kg y a=5m/s², entonces F=50N.\n'
        'Consejo: La energía no se crea ni se destruye, solo se transforma.',
    'Historia de Costa Rica':
        'Estudio del pasado costarricense.\n'
        'Ejemplo: Costa Rica se independizó el 15 de septiembre de 1821.\n'
        'Consejo: Recuerda las fechas clave: 1821 (independencia), 1856 (Campaña Nacional).',
    'Historia':
        'Estudio de los eventos del pasado.\n'
        'Ejemplo: Las guerras mundiales fueron conflictos globales del siglo XX.\n'
        'Consejo: Conecta eventos para entender las causas y consecuencias.',
    'Geografía':
        'Estudio de la Tierra y sus características.\n'
        'Ejemplo: Costa Rica está en Centroamérica, entre Nicaragua y Panamá.\n'
        'Consejo: Localiza países, capitales y regiones naturales.',
    'Cívica':
        'Estudio de los derechos y deberes ciudadanos.\n'
        'Ejemplo: En democracia, los ciudadanos votan para elegir gobernantes.\n'
        'Consejo: La Constitución Política es la ley suprema del país.',
    'Economía':
        'Ciencia que estudia cómo usamos los recursos.\n'
        'Ejemplo: Oferta y demanda determinan los precios.\n'
        'Consejo: PIB mide la producción total de un país.',
    'Gramática':
        'Conjunto de reglas que gobiernan un idioma.\n'
        'Ejemplo: Sujeto + Verbo + Complemento = Oración básica.\n'
        'Consejo: Identifica primero el verbo para encontrar el sujeto.',
    'Literatura':
        'Arte de escribir y analizar textos creativos.\n'
        'Ejemplo: Metáfora: "La vida es un sueño" (comparación sin "como").\n'
        'Consejo: Conoce los movimientos literarios: Romanticismo, Modernismo, etc.',
  };

  Future<void> _retakeWithNewQuestions() async {
    setState(() {
      _isGeneratingNewQuestions = true;
      _generatingMessage = 'Preparando nuevas preguntas...';
      _loadingIndex = 0;
    });

    final messages = [
      'Buscando temas difíciles...',
      'Generando preguntas de ${widget.subjectName}...',
      'Creando opciones de respuesta...',
      'Agregando explicaciones...',
      'Revisando calidad...',
      'Casi listo...',
    ];

    _loadingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_loadingIndex < messages.length - 1 && mounted) {
        setState(() {
          _loadingIndex++;
          _generatingMessage = messages[_loadingIndex];
        });
      }
    });

    final aiClient = ref.read(aiClientProvider);

    try {
      final weakTopics = _getWeakTopics().isNotEmpty
          ? _getWeakTopics()
          : widget.topics;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Generando con DeX (máx 2 minutos)...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );

      debugPrint(
        'Iniciando generación de preguntas para ${widget.subjectName}...',
      );

      final response = await aiClient
          .generateNewQuestions(
            subject: widget.subjectName,
            level: widget.levelIndex + 10,
            count: widget.questionCount,
            topics: weakTopics,
          )
          .timeout(const Duration(seconds: 90));

      final newQuestions = _parseAIQuestions(response);
      _loadingTimer?.cancel();

      if (newQuestions.isNotEmpty) {
        setState(() {
          _newQuestions = newQuestions;
          _isGeneratingNewQuestions = false;
        });
        if (mounted) _showRetakeDialog();
        return;
      }

      _loadLocalQuestions();
    } catch (e) {
      _loadingTimer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll("Exception: ", "")}. Usando preguntas locales.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _loadLocalQuestions();
    }
  }

  List<Question> _parseAIQuestions(String response) {
    try {
      debugPrint('AI Response length: ${response.length}');

      String jsonStr = _extractJsonFromResponse(response);

      if (jsonStr.isEmpty) {
        debugPrint('No se encontró JSON en la respuesta');
        return [];
      }

      final List<dynamic> data = jsonDecode(jsonStr);

      if (data.isEmpty) {
        debugPrint('El array JSON está vacío');
        return [];
      }

      final questions = <Question>[];

      for (int i = 0; i < data.length; i++) {
        try {
          final item = data[i];

          // Aceptar diferentes nombres de campos
          String question =
              item['question']?.toString() ??
              item['enunciado']?.toString() ??
              item['pregunta']?.toString() ??
              '';
          if (question.isEmpty) {
            debugPrint('Pregunta $i sin texto, saltando');
            continue;
          }

          List<String> options = [];
          final optionsRaw =
              item['options'] ?? item['opciones'] ?? item['choices'];
          if (optionsRaw is List && optionsRaw.isNotEmpty) {
            options = optionsRaw.map((e) => e.toString().trim()).toList();
          } else if (optionsRaw is String && optionsRaw.isNotEmpty) {
            options = optionsRaw.split(',').map((e) => e.trim()).toList();
          }

          if (options.length < 2 || options.isEmpty) {
            debugPrint('Pregunta $i sin opciones válidas, saltando');
            continue;
          }

          while (options.length < 4) {
            options.add('Opción ${options.length + 1}');
          }

          int correctIndex = 0;

          // Buscar el índice de respuesta correcta en diferentes campos
          if (item['correctIndex'] is int) {
            correctIndex = item['correctIndex'];
          } else if (item['correctAnswerIndex'] is int) {
            correctIndex = item['correctAnswerIndex'];
          } else {
            // Buscar en texto de respuesta correcta
            final answerFields = [
              'correctAnswer',
              'respuesta',
              'answer',
              'correcta',
            ];
            for (final field in answerFields) {
              if (item[field] is String) {
                final correctAnswer = item[field].toString().toUpperCase();
                if (correctAnswer.contains('A') ||
                    correctAnswer.contains('1')) {
                  correctIndex = 0;
                  break;
                } else if (correctAnswer.contains('B') ||
                    correctAnswer.contains('2')) {
                  correctIndex = 1;
                  break;
                } else if (correctAnswer.contains('C') ||
                    correctAnswer.contains('3')) {
                  correctIndex = 2;
                  break;
                } else if (correctAnswer.contains('D') ||
                    correctAnswer.contains('4')) {
                  correctIndex = 3;
                  break;
                }
              }
            }
          }

          correctIndex = correctIndex.clamp(0, options.length - 1);

          questions.add(
            Question.create(
              odId: 'ai_${DateTime.now().millisecondsSinceEpoch}_$i',
              question: question,
              options: options.take(4).toList(),
              correctAnswerIndex: correctIndex,
              explanation:
                  item['explanation']?.toString() ??
                  item['explicacion']?.toString() ??
                  'Revisa el tema.',
              categoryIndex: widget.subjectIndex,
              levelIndex: widget.levelIndex,
              topic:
                  item['topic']?.toString() ??
                  item['tema']?.toString() ??
                  widget.subjectName,
            ),
          );
        } catch (e) {
          debugPrint('Error parsing pregunta $i: $e');
          continue;
        }
      }

      debugPrint('Parsed ${questions.length} preguntas');
      return questions;
    } catch (e) {
      debugPrint('Error parsing AI questions: $e');
      return [];
    }
  }

  String _extractJsonFromResponse(String text) {
    // Limpiar texto de markdown si existe
    text = text
        .replaceAll(RegExp(r'```json\s*'), '[')
        .replaceAll(RegExp(r'```\s*'), '');
    text = text.replaceAll(RegExp(r'`'), '');

    // Buscar array JSON [...]
    final firstBracket = text.indexOf('[');
    final lastBracket = text.lastIndexOf(']');

    if (firstBracket != -1 && lastBracket != -1 && firstBracket < lastBracket) {
      String jsonStr = text.substring(firstBracket, lastBracket + 1);
      jsonStr = jsonStr.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
      return jsonStr.trim();
    }

    // Buscar objeto JSON con propiedad "preguntas" o "questions"
    final firstBrace = text.indexOf('{');
    final lastBrace = text.lastIndexOf('}');

    if (firstBrace != -1 && lastBrace != -1 && firstBrace < lastBrace) {
      String jsonStr = text.substring(firstBrace, lastBrace + 1);

      // Intentar extraer el array interno
      final arrayMatch = RegExp(
        r'"(?:preguntas|questions|questionsArr)"\s*:\s*(\[[^\]]+\])',
      ).firstMatch(jsonStr);
      if (arrayMatch != null) {
        return arrayMatch.group(1) ?? '';
      }

      jsonStr = jsonStr.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
      return jsonStr.trim();
    }

    return '';
  }

  void _showRetakeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Nuevas preguntas listas'),
          ],
        ),
        content: Text(
          'DeX ha generado ${_newQuestions!.length} preguntas diferentes '
          'basadas en los temas que necesitas repasar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Más tarde'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizSessionPage(
                    levelIndex: widget.levelIndex,
                    subjectName: widget.subjectName,
                    subjectIndex: widget.subjectIndex,
                    questionCount: widget.questionCount,
                    durationMinutes: widget.durationMinutes,
                    topics: widget.topics,
                  ),
                ),
              );
            },
            child: const Text('Comenzar'),
          ),
        ],
      ),
    );
  }

  void _showReviewMistakes(BuildContext context) {
    final incorrectQuestions = <Question>[];
    final incorrectAnswers = <int>[];

    for (int i = 0; i < _questions.length; i++) {
      if (!_questions[i].isCorrect(_userAnswers[i])) {
        incorrectQuestions.add(_questions[i]);
        incorrectAnswers.add(_userAnswers[i]);
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ReviewMistakesPage(
          questions: incorrectQuestions,
          userAnswers: incorrectAnswers,
          subjectName: widget.subjectName,
        ),
      ),
    );
  }

  Widget _buildScoreCard(int percentage) {
    final adjustedCorrect = _correctAnswers - (_hintedCorrectAnswers * 0.5);
    final hintsUsed = _hintedCorrectAnswers;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.3),
            AppTheme.secondaryColor.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            '$percentage%',
            style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (hintsUsed > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Usaste $hintsUsed pista${hintsUsed > 1 ? 's' : ''} (-${(hintsUsed * 0.5).toStringAsFixed(1)} puntos)',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            '${adjustedCorrect.toStringAsFixed(1)} de ${_questions.length} puntos',
            style: TextStyle(fontSize: 18, color: Colors.grey[300]),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            Icons.check_circle,
            Colors.green,
            _correctAnswers.toString(),
            'Correctas',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            Icons.cancel,
            Colors.red,
            (_questions.length - _correctAnswers).toString(),
            'Incorrectas',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            Icons.timer,
            Colors.blue,
            _formatTime(widget.durationMinutes * 60 - _remainingSeconds),
            'Tiempo',
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildStatItem(
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  List<Question> _getQuestionsForSubject(int subjectIndex, int levelIndex) {
    switch (subjectIndex) {
      case 0:
        return _mathQuestions[levelIndex] ?? [];
      case 1:
        return _scienceQuestions[levelIndex] ?? [];
      case 2:
        return _socialStudiesQuestions[levelIndex] ?? [];
      case 3:
        return _spanishQuestions[levelIndex] ?? [];
      default:
        return [];
    }
  }

  static List<Question> _createMathQuestions() {
    return [
      _createQ(
        '¿Cuál es el resultado de 2x + 3 = 7?',
        ['x = 2', 'x = 4', 'x = 3', 'x = 5'],
        0,
        'Para resolver: 2x = 7 - 3, entonces x = 4/2 = 2',
        'Álgebra',
      ),
      _createQ(
        '¿Cuánto mide la suma de los ángulos internos de un triángulo?',
        ['90°', '180°', '360°', '270°'],
        1,
        'La suma de los ángulos internos de cualquier triángulo es siempre 180°.',
        'Geometría',
      ),
      _createQ(
        '¿Qué es la moda en estadística?',
        [
          'El valor máximo',
          'El valor que más se repite',
          'El promedio',
          'El valor mínimo',
        ],
        1,
        'La moda es el valor que aparece con mayor frecuencia.',
        'Estadística',
      ),
      _createQ(
        'Resuelve: √144',
        ['11', '12', '13', '14'],
        1,
        'La raíz cuadrada de 144 es 12.',
        'Álgebra',
      ),
      _createQ(
        '¿Cuál es el área de un círculo con radio 3?',
        ['6π', '9π', '3π', '12π'],
        1,
        'Área = π × r² = π × 9 = 9π',
        'Geometría',
      ),
      _createQ(
        '¿Qué tipo de número es √2?',
        ['Racional', 'Irracional', 'Entero', 'Natural'],
        1,
        '√2 no puede expresarse como fracción, es irracional.',
        'Álgebra',
      ),
      _createQ(
        '¿Cuál es el valor de π aproximado?',
        ['2.14', '3.14', '4.14', '3.41'],
        1,
        'π ≈ 3.1415926535...',
        'Geometría',
      ),
      _createQ(
        '¿Qué es una ecuación de segundo grado?',
        ['ax + b = 0', 'ax² + bx + c = 0', 'ax³ + bx = 0', 'ax = b'],
        1,
        'Una ecuación cuadrática tiene x elevada al cuadrado.',
        'Álgebra',
      ),
      _createQ(
        '¿Cuál es el perímetro de un cuadrado de lado 5?',
        ['10', '20', '25', '15'],
        1,
        'Perímetro = 4 × lado = 4 × 5 = 20',
        'Geometría',
      ),
      _createQ(
        '¿Qué es el MCM de 4 y 6?',
        ['2', '12', '24', '8'],
        1,
        'MCM(4,6) = 12',
        'Álgebra',
      ),
      _createQ(
        '¿Cuál es el volumen de una esfera de radio 3?',
        ['36π', '27π', '108π', '12π'],
        0,
        'V = (4/3)πr³ = (4/3)π(27) = 36π',
        'Geometría',
      ),
      _createQ(
        '¿Qué es una función lineal?',
        ['y = ax² + bx + c', 'y = mx + b', 'y = ax²', 'y = k'],
        1,
        'Una función lineal tiene forma y = mx + b y su gráfica es una recta.',
        'Funciones',
      ),
      _createQ(
        '¿Cuál es el 20% de 150?',
        ['20', '25', '30', '35'],
        2,
        '20% de 150 = 0.20 × 150 = 30',
        'Álgebra',
      ),
      _createQ(
        '¿Qué es el teorema de Pitágoras?',
        ['a² + b² = c²', 'a + b = c', 'a × b = c', 'a/b = c'],
        0,
        'En un triángulo rectángulo: a² + b² = c²',
        'Geometría',
      ),
      _createQ(
        '¿Cuál es el resultado de 3² × 2³?',
        ['36', '48', '72', '24'],
        2,
        '3² = 9, 2³ = 8, 9 × 8 = 72',
        'Álgebra',
      ),
      _createQ(
        '¿Qué es la mediana?',
        ['El promedio', 'El valor del medio', 'El valor máximo', 'La suma'],
        1,
        'La mediana es el valor central cuando se ordenan los datos.',
        'Estadística',
      ),
      _createQ(
        '¿Cuántos grados tiene un ángulo recto?',
        ['45°', '90°', '180°', '360°'],
        1,
        'Un ángulo recto mide exactamente 90°.',
        'Geometría',
      ),
      _createQ(
        '¿Qué es una fracción equivalente a 1/2?',
        ['2/4', '3/6', 'Ambas son equivalentes', 'Ninguna'],
        2,
        '1/2 = 2/4 = 3/6 son equivalentes.',
        'Álgebra',
      ),
      _createQ(
        '¿Cuál es el área de un rectángulo de base 8 y altura 5?',
        ['13', '40', '26', '80'],
        1,
        'Área = base × altura = 8 × 5 = 40',
        'Geometría',
      ),
      _createQ(
        '¿Qué es el seno en un triángulo rectángulo?',
        [
          'Lado adyacente/hipotenusa',
          'Lado opuesto/hipotenusa',
          'Hipotenusa/lado opuesto',
          'Base/altura',
        ],
        1,
        'sen(θ) = lado opuesto / hipotenusa',
        'Trigonometría',
      ),
      _createQ(
        '¿Cuál es el resultado de 8 ÷ 1/2?',
        ['4', '8', '16', '12'],
        2,
        'Dividir por 1/2 es multiplicar por 2: 8 × 2 = 16',
        'Álgebra',
      ),
      _createQ(
        '¿Qué es una progresión aritmética?',
        [
          'Serie con razón constante',
          'Serie con diferencia constante',
          'Serie geométrica',
          'Serie infinita',
        ],
        1,
        'En una PA, la diferencia entre términos es constante.',
        'Álgebra',
      ),
      _createQ(
        '¿Cuál es el coseno de 0°?',
        ['0', '1', '∞', '-1'],
        1,
        'cos(0°) = 1',
        'Trigonometría',
      ),
      _createQ(
        '¿Qué es el rango en estadística?',
        ['El promedio', 'Máximo - Mínimo', 'La moda', 'La mediana'],
        1,
        'Rango = valor máximo - valor mínimo',
        'Estadística',
      ),
      _createQ(
        '¿Cuántos lados tiene un hexágono?',
        ['5', '6', '7', '8'],
        1,
        'Un hexágono tiene 6 lados.',
        'Geometría',
      ),
      _createQ(
        '¿Qué es log₂(8)?',
        ['2', '3', '4', '8'],
        1,
        'log₂(8) = 3 porque 2³ = 8',
        'Álgebra',
      ),
      _createQ(
        '¿Cuál es la ecuación de una recta con pendiente 2 que pasa por (0,3)?',
        ['y = 2x + 3', 'y = 3x + 2', 'y = 2x - 3', 'y = 3x - 2'],
        0,
        'y = mx + b donde m=2, b=3',
        'Funciones',
      ),
      _createQ(
        '¿Qué es el volumen de un cubo de arista 4?',
        ['16', '48', '64', '96'],
        2,
        'V = a³ = 4³ = 64',
        'Geometría',
      ),
      _createQ(
        '¿Cuál es la tangente de 45°?',
        ['0', '1', '√2', '∞'],
        1,
        'tan(45°) = 1',
        'Trigonometría',
      ),
      _createQ(
        '¿Qué tipo de ángulo mide más de 90° pero menos de 180°?',
        ['Agudo', 'Recto', 'Obtuso', 'Llano'],
        2,
        'Un ángulo obtuso está entre 90° y 180°.',
        'Geometría',
      ),
      _createQ(
        '¿Cuál es el resultado de (-3) × (-4)?',
        ['-12', '12', '-7', '7'],
        1,
        'Negativo por negativo es positivo: (-3)(-4) = 12',
        'Álgebra',
      ),
      _createQ(
        '¿Qué es la varianza?',
        [
          'Promedio de cuadrados',
          'Dispersión de datos al cuadrado',
          'Moda elevada',
          'Diferencia de medianas',
        ],
        1,
        'La varianza mide la dispersión de los datos.',
        'Estadística',
      ),
      _createQ(
        '¿Cuántas diagonales tiene un pentágono?',
        ['3', '5', '7', '10'],
        1,
        'Un pentágono tiene 5 diagonales.',
        'Geometría',
      ),
      _createQ(
        '¿Qué es eˣ?',
        [
          'Función lineal',
          'Función exponencial',
          'Función logarítmica',
          'Función cuadrática',
        ],
        1,
        'eˣ es una función exponencial con base e ≈ 2.718',
        'Funciones',
      ),
      _createQ(
        '¿Cuál es el área de un triángulo de base 6 y altura 4?',
        ['10', '12', '24', '48'],
        1,
        'Área = (b × h)/2 = (6 × 4)/2 = 12',
        'Geometría',
      ),
      _createQ(
        '¿Qué es el seny?',
        ['Coseno', 'Seno', 'Tangente', 'Cotangente'],
        1,
        'sen y = cateto opuesto / hipotenusa',
        'Trigonometría',
      ),
      _createQ(
        '¿Cuál es la desviación estándar?',
        ['Raíz cuadrada de la varianza', 'Promedio', 'Moda', 'Rango'],
        0,
        'Desviación estándar = √varianza',
        'Estadística',
      ),
      _createQ(
        '¿Qué forma tiene la gráfica de y = x²?',
        ['Línea recta', 'Parábola', 'Círculo', 'Hipérbola'],
        1,
        'y = x² es una parábola.',
        'Funciones',
      ),
      _createQ(
        '¿Cuántos grados tiene un ángulo completo?',
        ['180°', '270°', '360°', '90°'],
        2,
        'Un ángulo completo mide 360°.',
        'Geometría',
      ),
      _createQ(
        '¿Qué es ln(e²)?',
        ['e', '2e', '2', 'e²'],
        2,
        'ln(e²) = 2 porque e² = e²',
        'Álgebra',
      ),
      _createQ(
        '¿Cuál es el teorema del residuo?',
        ['Evaluar polinomios', 'Dividir polinomios', 'Factorizar', 'Graficar'],
        0,
        'El teorema del residuo evalúa polinomios.',
        'Álgebra',
      ),
      _createQ(
        '¿Qué es el circumcentro?',
        [
          'Centro del círculo inscrito',
          'Centro del círculo circunscrito',
          'Punto medio',
          'Incentro',
        ],
        1,
        'Es el centro de la circunferencia que pasa por los vértices.',
        'Geometría',
      ),
      _createQ(
        '¿Cuál es la suma de los primeros 10 números naturales?',
        ['45', '50', '55', '60'],
        2,
        'S = n(n+1)/2 = 10(11)/2 = 55',
        'Álgebra',
      ),
      _createQ(
        '¿Qué es el incentro?',
        [
          'Centro de la circunferencia',
          'Centro del círculo inscrito',
          'Punto de intersección',
          'Baricentro',
        ],
        1,
        'Es el centro del círculo inscrito en el triángulo.',
        'Geometría',
      ),
      _createQ(
        '¿Cuál es la fórmula de la distancia entre dos puntos?',
        [
          '|x₂-x₁| + |y₂-y₁|',
          '√((x₂-x₁)² + (y₂-y₁)²)',
          '√((x₂+x₁)² + (y₂+y₁)²)',
          '(x₂-x₁)(y₂-y₁)',
        ],
        1,
        'd = √((x₂-x₁)² + (y₂-y₁)²)',
        'Geometría',
      ),
      _createQ(
        '¿Qué es una matriz identidad 2×2?',
        ['[[1,0],[0,0]]', '[[1,0],[0,1]]', '[[0,1],[1,0]]', '[[1,1],[1,1]]'],
        1,
        'La matriz identidad tiene 1s en la diagonal y 0s en el resto.',
        'Álgebra',
      ),
      _createQ(
        '¿Cuál es el baricentro de un triángulo?',
        ['Punto medio', 'Centroide', 'Ortocentro', 'Circuncentro'],
        1,
        'Es la intersección de las medianas.',
        'Geometría',
      ),
      _createQ(
        '¿Qué es el determinante de una matriz 2×2 [[a,b],[c,d]]?',
        ['ad + bc', 'ad - bc', 'a + b + c + d', 'ac - bd'],
        1,
        'det = ad - bc',
        'Álgebra',
      ),
      _createQ(
        '¿Cuál es el área de un trapecio con bases 4 y 6 y altura 5?',
        ['10', '25', '50', '20'],
        1,
        'A = ((b₁+b₂)/2)×h = ((4+6)/2)×5 = 25',
        'Geometría',
      ),
      _createQ(
        '¿Qué son coordenadas polares?',
        ['(x,y)', '(r,θ)', '(a,b)', '(m,b)'],
        1,
        'Las coordenadas polares son (radio, ángulo).',
        'Geometría',
      ),
    ];
  }

  static List<Question> _createScienceQuestions() {
    return [
      _createQ(
        '¿Qué es la fotosíntesis?',
        [
          'Respiración celular',
          'Proceso donde las plantas producen alimento usando luz solar',
          'Digestión de alimentos',
          'Circulación de la sangre',
        ],
        1,
        'Las plantas convierten luz solar, CO₂ y agua en glucosa y oxígeno.',
        'Biología',
      ),
      _createQ(
        '¿Cuál es la unidad básica de la vida?',
        ['El átomo', 'La célula', 'El órgano', 'El tejido'],
        1,
        'La célula es la unidad fundamental de la vida.',
        'Biología',
      ),
      _createQ(
        '¿Qué es la tabla periódica?',
        [
          'Una tabla de multiplicar',
          'Organización de elementos químicos',
          'Lista de países',
          'Calendario de eventos',
        ],
        1,
        'Organiza los 118 elementos químicos según sus propiedades.',
        'Química',
      ),
      _createQ(
        '¿Qué es la Ley de Newton de la gravitación universal?',
        [
          'F = ma',
          'Todo cuerpo atrae a otro con fuerza proporcional a sus masas',
          'E = mc²',
          'V = IR',
        ],
        1,
        'Todo objeto con masa atrae a otros proporcionalmente.',
        'Física',
      ),
      _createQ(
        '¿Qué es el ADN?',
        [
          'Ácido desoxirribonucleico',
          'Una proteína',
          'Un lípido',
          'Un carbohidrato',
        ],
        0,
        'El ADN contiene la información genética.',
        'Biología',
      ),
      _createQ(
        '¿Qué es la teoría de la relatividad?',
        [
          'E = mc²',
          'Todo se mueve respecto a un éter',
          'La luz es una partícula',
          'El tiempo es absoluto',
        ],
        0,
        'E = mc² establece que masa y energía son equivalentes.',
        'Física',
      ),
      _createQ(
        '¿Qué órgano bombear sangre al cuerpo?',
        ['Los pulmones', 'El corazón', 'El cerebro', 'El hígado'],
        1,
        'El corazón es el órgano que bombea sangre.',
        'Biología',
      ),
      _createQ(
        '¿Qué es el sistema nervioso central?',
        [
          'Corazón y pulmones',
          'Cerebro y médula espinal',
          'Hígado y riñones',
          'Músculos y huesos',
        ],
        1,
        'El SNC está formado por cerebro y médula espinal.',
        'Biología',
      ),
      _createQ(
        '¿Qué es un átomo?',
        [
          'La molécula más pequeña',
          'La unidad más pequeña de un elemento',
          'Una célula',
          'Un electrón',
        ],
        1,
        'El átomo es la unidad más pequeña de la materia.',
        'Química',
      ),
      _createQ(
        '¿Qué es la velocidad?',
        [
          'Distancia / Tiempo',
          'Tiempo / Distancia',
          'Distancia × Tiempo',
          'Distancia + Tiempo',
        ],
        0,
        'v = d/t (rapidez con dirección).',
        'Física',
      ),
      _createQ(
        '¿Qué es la mitosis?',
        [
          'División celular que produce células idénticas',
          'Fusión de células',
          'Muerte celular',
          'Reproducción sexual',
        ],
        0,
        'La mitosis produce dos células idénticas.',
        'Biología',
      ),
      _createQ(
        '¿Qué es un enlace covalente?',
        [
          'Compartición de electrones',
          'Transferencia de electrones',
          'Attacción iónica',
          'Enlace metálico',
        ],
        0,
        'En un enlace covalente los átomos comparten electrones.',
        'Química',
      ),
      _createQ(
        '¿Qué es la energía cinética?',
        [
          'Energía de posición',
          'Energía de movimiento',
          'Energía térmica',
          'Energía nuclear',
        ],
        1,
        'La energía cinética depende de la velocidad.',
        'Física',
      ),
      _createQ(
        '¿Qué son los glóbulos rojos?',
        [
          'Células que combaten enfermedades',
          'Células que transportan oxígeno',
          'Células que coagulan la sangre',
          'Células nerviosas',
        ],
        1,
        'Los glóbulos rojos transportan oxígeno con hemoglobina.',
        'Biología',
      ),
      _createQ(
        '¿Qué es un ácido?',
        [
          'Sustancia con pH > 7',
          'Sustancia con pH < 7',
          'Sustancia neutra',
          'Base fuerte',
        ],
        1,
        'Los ácidos tienen pH menor que 7.',
        'Química',
      ),
      _createQ(
        '¿Qué es la Ley de Ohm?',
        ['V = IR', 'P = IV', 'F = ma', 'E = mc²'],
        0,
        'Voltaje = Corriente × Resistencia',
        'Física',
      ),
      _createQ(
        '¿Qué es la teoría celular?',
        [
          'Todo ser vivo está hecho de células',
          'Las células son squares',
          'Los átomos forman células',
          'Las plantas no tienen células',
        ],
        0,
        'Todos los seres vivos están compuestos de células.',
        'Biología',
      ),
      _createQ(
        '¿Qué es un isótopo?',
        [
          'Átomo con diferente número de neutrones',
          'Átomo con diferente número de protones',
          'Molécula diferente',
          'Elemento nuevo',
        ],
        0,
        'Isótopos del mismo elemento tienen diferente número de neutrones.',
        'Química',
      ),
      _createQ(
        '¿Qué es el trabajo en física?',
        ['W = F × d', 'W = F/d', 'W = F + d', 'W = F - d'],
        0,
        'Trabajo = Fuerza × Distancia',
        'Física',
      ),
      _createQ(
        '¿Qué es la meiosis?',
        [
          'División celular para crecimiento',
          'División celular para reproducción',
          'División del núcleo',
          'Fusión celular',
        ],
        1,
        'La meiosis produce células sexuales (gametos).',
        'Biología',
      ),
      _createQ(
        '¿Qué es la tabla de Mendel?',
        [
          'Genética básica',
          'Primera ley de Mendel',
          'Cruces genéticos',
          'Herencia',
        ],
        0,
        'Establece las bases de la herencia genética.',
        'Biología',
      ),
      _createQ(
        '¿Qué es un orbital atómico?',
        [
          'Órbita circular',
          'Región donde es probable encontrar electrones',
          'Nivel de energía fijo',
          'Próximo al núcleo',
        ],
        1,
        'Los orbitales son zonas de probabilidad electrónica.',
        'Química',
      ),
      _createQ(
        '¿Qué es la gravedad?',
        [
          'Fuerza de repulsión',
          'Fuerza de atracción entre masas',
          'Energía potencial',
          'Movimiento rectilíneo',
        ],
        1,
        'La gravedad atrae objetos con masa entre sí.',
        'Física',
      ),
      _createQ(
        '¿Qué es el sistema respiratorio?',
        [
          'Conjunto de órganos para respirar',
          'Sistema circulatorio',
          'Sistema digestivo',
          'Sistema nervioso',
        ],
        0,
        'Incluye pulmones, bronquios, traquea.',
        'Biología',
      ),
      _createQ(
        '¿Qué es una reacción exotérmica?',
        [
          'Absorbe calor',
          'Libera calor',
          'No cambia la temperatura',
          'Requiere catalizador',
        ],
        1,
        'Las reacciones exotérmicas liberan energía térmica.',
        'Química',
      ),
      _createQ(
        '¿Qué es la potencia?',
        [
          'Energía / Tiempo',
          'Energía × Tiempo',
          'Trabajo / Masa',
          'Fuerza × Velocidad',
        ],
        0,
        'P = W/t (rapidez de transferencia de energía).',
        'Física',
      ),
      _createQ(
        '¿Qué es el sistema inmune?',
        ['Combate enfermedades', 'Digestión', 'Circulación', 'Respiración'],
        0,
        'El sistema inmune nos protege de infecciones.',
        'Biología',
      ),
      _createQ(
        '¿Qué es un mol?',
        [
          '6.02 × 10²³ partículas',
          'Un gramo',
          'Un litro',
          'Una unidad de energía',
        ],
        0,
        'Un mol contiene el número de Avogadro de partículas.',
        'Química',
      ),
      _createQ(
        '¿Qué es el movimiento circular uniforme?',
        [
          'Movimiento con velocidad constante en círculo',
          'Aceleración constante',
          'Movimiento lineal',
          'Caída libre',
        ],
        0,
        'Rapidez constante, dirección cambia continuamente.',
        'Física',
      ),
      _createQ(
        '¿Qué es la selección natural?',
        [
          'Supervivencia del más apto',
          'Reproducción forzada',
          'Mutación dirigida',
          'Extinción natural',
        ],
        0,
        'Los organismos mejor adaptados sobreviven y se reproducen.',
        'Biología',
      ),
      _createQ(
        '¿Qué es un enlace iónico?',
        [
          'Compartición de electrones',
          'Transferencia de electrones',
          'Compartición parcial',
          'Enlace de hidrógeno',
        ],
        1,
        'Se forma por transferencia de electrones.',
        'Química',
      ),
      _createQ(
        '¿Qué es la aceleración?',
        [
          'Cambio en la velocidad',
          'Rapidez constante',
          'Distancia recorrida',
          'Tiempo transcurrido',
        ],
        0,
        'a = Δv/Δt (cambio de velocidad en el tiempo).',
        'Física',
      ),
      _createQ(
        '¿Qué es la osmosis?',
        [
          'Paso de agua por membrana selectiva',
          'Paso de sales',
          'División celular',
          'Síntesis de proteínas',
        ],
        0,
        'El agua se mueve de menor a mayor concentración de solutos.',
        'Biología',
      ),
      _createQ(
        '¿Qué es el número atómico?',
        [
          'Cantidad de neutrones',
          'Cantidad de protones',
          'Cantidad de electrones totales',
          'Peso molecular',
        ],
        1,
        'El número atómico indica la cantidad de protones.',
        'Química',
      ),
      _createQ(
        '¿Qué es la energía potencial?',
        [
          'Energía de movimiento',
          'Energía almacenada por posición',
          'Energía térmica',
          'Energía cinética',
        ],
        1,
        'Ep = mgh (energía por altura).',
        'Física',
      ),
      _createQ(
        '¿Qué son los ribosomas?',
        [
          'Síntesis de proteínas',
          'Almacenamiento de energía',
          'Reproducción celular',
          'Transporte',
        ],
        0,
        'Los ribosomas sintetizan proteínas.',
        'Biología',
      ),
      _createQ(
        '¿Qué es la electronegatividad?',
        ['Afinidad por electrones', 'Radio atómico', 'Valencia', 'Densidad'],
        0,
        'Mide la capacidad de un átomo de atraer electrones.',
        'Química',
      ),
      _createQ(
        '¿Qué es la ley de Coulomb?',
        ['F = kq₁q₂/r²', 'V = IR', 'P = IV', 'E = mc²'],
        0,
        'Fuerza entre cargas eléctricas.',
        'Física',
      ),
      _createQ(
        '¿Qué es el ARN?',
        [
          'Ácido ribonucleico',
          'Ácido desoxirribonucleico',
          'Proteína',
          'Lípido',
        ],
        0,
        'El ARN participa en la síntesis de proteínas.',
        'Biología',
      ),
      _createQ(
        '¿Qué es un catalizador?',
        [
          'Acelera reacción sin consumirse',
          'Ralentiza reacción',
          'Participa en la reacción',
          'Cambia la temperatura',
        ],
        0,
        'Los catalizadores aceleran reacciones sin consumirse.',
        'Química',
      ),
      _createQ(
        '¿Qué es el campo magnético?',
        [
          'Región donde actúa fuerza magnética',
          'Corriente eléctrica',
          'Voltaje',
          'Resistencia',
        ],
        0,
        'El campo magnético ejerce fuerza sobre cargas en movimiento.',
        'Física',
      ),
      _createQ(
        '¿Qué es la homeostasis?',
        ['Equilibrio interno', 'Crecimiento', 'Reproducción', 'Metabolismo'],
        0,
        'Mantenimiento del equilibrio interno del organismo.',
        'Biología',
      ),
      _createQ(
        '¿Qué es la configuración electrónica?',
        [
          'Distribución de electrones en orbitales',
          'Estructura del núcleo',
          'Arreglo de protones',
          'Organización de neutrones',
        ],
        0,
        'Describe cómo están distribuidos los electrones.',
        'Química',
      ),
      _createQ(
        '¿Qué es la fuerza centrípeta?',
        [
          'Fuerza hacia el centro del círculo',
          'Fuerza hacia afuera',
          'Velocidad tangencial',
          'Aceleración lineal',
        ],
        0,
        'La fuerza centrípeta apunta hacia el centro de la trayectoria circular.',
        'Física',
      ),
      _createQ(
        '¿Qué es la evolución biológica?',
        [
          'Cambio de especies a lo largo del tiempo',
          'Extinción',
          'Estasis',
          'Mutación',
        ],
        0,
        'Las especies cambian gradualmente con el tiempo.',
        'Biología',
      ),
      _createQ(
        '¿Qué es el punto de ebullición?',
        [
          'Temperatura donde hierve un líquido',
          'Temperatura de fusión',
          'Temperatura ambiente',
          'Punto crítico',
        ],
        0,
        'Es la temperatura a la cual un líquido hierve.',
        'Química',
      ),
      _createQ(
        '¿Qué es la Ley de Hooke?',
        ['F = -kx', 'F = ma', 'V = IR', 'P = IV'],
        0,
        'La fuerza es proporcional a la deformación.',
        'Física',
      ),
      _createQ(
        '¿Qué es la fotosfera?',
        [
          'Capa exterior del Sol',
          'Núcleo solar',
          'Atmósfera terrestre',
          'Capa de ozono',
        ],
        0,
        'La fotosfera es la superficie visible del Sol.',
        'Física',
      ),
      _createQ(
        '¿Qué es el LHC?',
        [
          'Gran Colisionador de Hadrones',
          'Laboratorio de Química',
          'Centro de Biología',
          'Instituto de Física',
        ],
        0,
        'El LHC es el acelerador de partículas más grande del mundo.',
        'Física',
      ),
    ];
  }

  static List<Question> _createSocialStudiesQuestions() {
    return [
      _createQ(
        '¿En qué año se independizó Costa Rica?',
        ['1821', '1823', '1825', '1810'],
        0,
        'Costa Rica se independizó el 15 de septiembre de 1821.',
        'Historia de Costa Rica',
      ),
      _createQ(
        '¿Quién fue Juan Rafael Mora Porras?',
        [
          'Primer presidente',
          'Segundo presidente de Costa Rica',
          'Gobernante colonial',
          'Libertador',
        ],
        1,
        'Fue el segundo presidente (1849-1859).',
        'Historia de Costa Rica',
      ),
      _createQ(
        '¿Qué es Mesoamérica?',
        [
          'Región cultural prehispánica',
          'Un país',
          'Una religión',
          'Una lengua',
        ],
        0,
        'Región donde se desarrollaron aztecas, mayas y nicoyas.',
        'Historia',
      ),
      _createQ(
        '¿Qué fue la Primera Guerra Mundial?',
        [
          'Conflicto 1914-1918',
          'Guerra civil española',
          'Revolución francesa',
          'Guerra fría',
        ],
        0,
        'Conflicto global entre 1914 y 1918.',
        'Historia',
      ),
      _createQ(
        '¿Qué es el TLC?',
        [
          'Acuerdo comercial entre países',
          'Tratado de paz',
          'Ley ambiental',
          'Acuerdo militar',
        ],
        0,
        'Los TLC reducen barreras comerciales.',
        'Economía',
      ),
      _createQ(
        '¿Qué es la globalización?',
        [
          'Interconexión mundial',
          'Aislamiento',
          'Regionalización',
          'Localización',
        ],
        0,
        'Proceso de interconexión económica, cultural y política.',
        'Economía',
      ),
      _createQ(
        '¿Cuál es la capital de Costa Rica?',
        ['San José', 'Alajuela', 'Cartago', 'Heredia'],
        0,
        'San José es la capital y ciudad más grande.',
        'Geografía',
      ),
      _createQ(
        '¿Qué es el PIB?',
        [
          'Producto Interno Bruto',
          'Precio Internacional Base',
          'Programa de Inversión Bancaria',
          'Plan de Integración Básico',
        ],
        0,
        'Es el valor total de bienes y servicios producidos.',
        'Economía',
      ),
      _createQ(
        '¿Quién fue José Figueres Ferrer?',
        ['Presidente y figura histórica', 'Escritor', 'Deportista', 'Músico'],
        0,
        'Figueres abolió el ejército y fue presidente tres veces.',
        'Historia de Costa Rica',
      ),
      _createQ(
        '¿Qué son los derechos humanos?',
        [
          'Libertades fundamentales',
          'Derechos laborales',
          'Obligaciones',
          'Privilegios',
        ],
        0,
        'Son derechos inherentes a todas las personas.',
        'Cívica',
      ),
      _createQ(
        '¿Qué océano está al oeste de Costa Rica?',
        ['Océano Pacífico', 'Océano Atlántico', 'Mar Caribe', 'Océano Índico'],
        0,
        'Costa Rica tiene costa en el Pacífico.',
        'Geografía',
      ),
      _createQ(
        '¿Qué es la democracia?',
        [
          'Gobierno del pueblo',
          'Gobierno de un dictador',
          'Monarquía',
          'Anarquía',
        ],
        0,
        'Sistema donde el pueblo elige a sus gobernantes.',
        'Cívica',
      ),
      _createQ(
        '¿Qué cordillera atraviesa Costa Rica?',
        [
          'Cordillera Central y Talamanca',
          'Cordillera de los Andes',
          'Sierra Madre',
          'Himalaya',
        ],
        0,
        'Costa Rica tiene dos cordilleras principales.',
        'Geografía',
      ),
      _createQ(
        '¿Qué es la inflación?',
        [
          'Aumento generalizado de precios',
          'Bajada de precios',
          'Estabilidad económica',
          'Devaluación',
        ],
        0,
        'La inflación reduce el poder adquisitivo.',
        'Economía',
      ),
      _createQ(
        '¿Quién fue Juan Santamaría?',
        [
          'Héroe nacional en la Campaña Nacional',
          'Primer presidente',
          'Explorador español',
          'Invasor británico',
        ],
        0,
        'Santamaría quemó el paso de Rivas en 1856.',
        'Historia de Costa Rica',
      ),
      _createQ(
        '¿Qué es la Constitución Política?',
        [
          'Ley suprema del país',
          'Ley ordinaria',
          'Reglamento municipal',
          'Decreto ejecutivo',
        ],
        0,
        'La Constitución es la norma fundamental.',
        'Cívica',
      ),
      _createQ(
        '¿Qué país limitaba al norte con Costa Rica?',
        ['Nicaragua', 'Panamá', 'Colombia', 'Honduras'],
        0,
        'Nicaragua está al norte de Costa Rica.',
        'Geografía',
      ),
      _createQ(
        '¿Qué es el comercio internacional?',
        [
          'Intercambio de bienes entre países',
          'Comercio local',
          'Venta en ferias',
          'Tienda virtual',
        ],
        0,
        'Incluye importaciones y exportaciones.',
        'Economía',
      ),
      _createQ(
        '¿Qué es la ciudadanía?',
        [
          'Condición de pertenecer a un Estado',
          'Ser residente',
          'Ser turista',
          'Ser extranjero',
        ],
        0,
        'Da derechos y obligaciones políticas.',
        'Cívica',
      ),
      _createQ(
        '¿Qué símbolo aparece en la bandera de Costa Rica?',
        ['Escudo con tres volcanes', 'Águila', 'Sol', 'Luna'],
        0,
        'El escudo tiene tres volcanes y dos océanos.',
        'Cívica',
      ),
      _createQ(
        '¿Qué es el desarrollo sostenible?',
        [
          'Satisfacer necesidades sin comprometer el futuro',
          'Crecimiento rápido',
          'Industrialización total',
          'Conservación absoluta',
        ],
        0,
        'Equilibrio entre economía, ambiente y sociedad.',
        'Economía',
      ),
      _createQ(
        '¿Qué cultura prehispánica habitó Costa Rica?',
        ['Chorotega, bribri, cabécar', 'Azteca', 'Maya', 'Inca'],
        0,
        'Costa Rica tenía culturas indígenas diversas.',
        'Historia',
      ),
      _createQ(
        '¿Qué es el homeschooling?',
        ['Educación en casa', 'Escuela pública', 'Universidad', 'Colegio'],
        0,
        'Modalidad de educación alternativa en el hogar.',
        'Educación',
      ),
      _createQ(
        '¿Qué es el sistema previsional?',
        [
          'Pensiones y jubilaciones',
          'Salud pública',
          'Educación',
          'Transporte',
        ],
        0,
        'Garantiza ingresos en la vejez.',
        'Economía',
      ),
      _createQ(
        '¿Qué forma de gobierno tiene Costa Rica?',
        ['República democrática', 'Monarquía', 'Dictadura', 'Teocracia'],
        0,
        'Costa Rica es una república democrática.',
        'Cívica',
      ),
      _createQ(
        '¿Qué es el IDH?',
        [
          'Índice de Desarrollo Humano',
          'Impuesto Directo Hipotecario',
          'Indicador de Deuda Histórica',
          'Índice de Densidad Habitacional',
        ],
        0,
        'Mide desarrollo en salud, educación e ingresos.',
        'Economía',
      ),
      _createQ(
        '¿Qué evento marcó la independencia centroamericana?',
        [
          'Grito de Dolores 1810',
          'Batalla de Riva Palacio',
          'Tratado de Basel',
          'Revolución',
        ],
        0,
        'El Grito de Dolores inició la independencia de México.',
        'Historia',
      ),
      _createQ(
        '¿Qué es la migración?',
        [
          'Movimiento de personas entre países',
          'Movimiento de mercancías',
          'Viaje de negocios',
          'Turismo',
        ],
        0,
        'La migración incluye emigrantes e inmigrantes.',
        'Geografía',
      ),
      _createQ(
        '¿Qué es el federalismo?',
        [
          'Sistema de gobierno con divisiones territoriales',
          'Gobierno centralizado',
          'Monarquía federal',
          'Confederación',
        ],
        0,
        'El poder se comparte entre gobierno central y estados.',
        'Cívica',
      ),
      _createQ(
        '¿Qué es el comercio justo?',
        [
          'Comercio equitativo y ético',
          'Comercio libre',
          'Comercio internacional',
          'Bolsa de valores',
        ],
        0,
        'Busca condiciones justas para productores.',
        'Economía',
      ),
      _createQ(
        '¿Qué son las AFP?',
        [
          'Administradoras de Fondos de Pensiones',
          'Agencias Financieras Públicas',
          'Asociación de Fútbol Profesional',
          'Autoridad Fiscal Penal',
        ],
        0,
        'Gestionan los fondos de pensiones.',
        'Economía',
      ),
      _createQ(
        '¿Qué es la educación cívica?',
        [
          'Estudio de derechos y deberes ciudadanos',
          'Matemáticas',
          'Historia universal',
          'Geografía física',
        ],
        0,
        'Prepara para ejercer la ciudadanía.',
        'Cívica',
      ),
      _createQ(
        '¿Qué es el mercado laboral?',
        [
          'Oferta y demanda de trabajo',
          'Mercado de valores',
          'Tienda de empleo',
          'Bolsa de trabajo',
        ],
        0,
        'Donde trabajadores y empleadores se encuentran.',
        'Economía',
      ),
      _createQ(
        '¿Qué es el sufragio?',
        [
          'Derecho a votar',
          'Deber militar',
          'Obligación tributaria',
          'Libertad de expresión',
        ],
        0,
        'El sufragio es el derecho al voto.',
        'Cívica',
      ),
      _createQ(
        '¿Qué fue la Guerra Fría?',
        [
          'Conflicto EE.UU. vs URSS 1947-1991',
          'Primera Guerra Mundial',
          'Guerra de Corea',
          'Conflicto árabe-israelí',
        ],
        0,
        'Rivalidad entre capitalismo y comunismo.',
        'Historia',
      ),
      _createQ(
        '¿Qué es el Banco Central?',
        [
          'Emisor de moneda nacional',
          'Banco comercial',
          'Caja rural',
          'Cooperativa',
        ],
        0,
        'Controla la política monetaria.',
        'Economía',
      ),
      _createQ(
        '¿Qué es la soberanía?',
        ['Poder supremo del Estado', 'Dependencia', 'Colonia', 'Territorio'],
        0,
        'Es la autoridad máxima e independiente.',
        'Cívica',
      ),
      _createQ(
        '¿Qué mar está al este de Costa Rica?',
        ['Mar Caribe', 'Océano Pacífico', 'Mar Mediterráneo', 'Mar Rojo'],
        0,
        'Costa Rica tiene costa en el Caribe.',
        'Geografía',
      ),
      _createQ(
        '¿Qué es la deuda pública?',
        [
          'Dinero que debe el gobierno',
          'Impuestos',
          'Ingresos del Estado',
          'Exportaciones',
        ],
        0,
        'Es la acumulación de déficits presupuestarios.',
        'Economía',
      ),
      _createQ(
        '¿Qué es la participación ciudadana?',
        [
          'Involucramiento en decisiones públicas',
          'Votar únicamente',
          'Pagar impuestos',
          'Ser funcionario',
        ],
        0,
        'Incluye voting, audiencias, presupuestos participativos.',
        'Cívica',
      ),
      _createQ(
        '¿Qué bioma predomina en Costa Rica?',
        ['Bosque tropical', 'Desierto', 'Tundra', 'Sabana'],
        0,
        'Costa Rica tiene bosque tropical húmedo y seco.',
        'Geografía',
      ),
      _createQ(
        '¿Qué es el proteccionismo?',
        [
          'Restricción de importaciones',
          'Libre comercio total',
          'Subsidios',
          'Zonas francas',
        ],
        0,
        'Busca proteger la industria nacional.',
        'Economía',
      ),
      _createQ(
        '¿Qué derechos tiene un ciudadano?',
        [
          'Elección de gobernantes, libre expresión, educación',
          'Solo trabajar',
          'Solo pagar impuestos',
          'Ninguno',
        ],
        0,
        'Los derechos ciudadanos incluyen civiles, políticos y sociales.',
        'Cívica',
      ),
      _createQ(
        '¿Qué evento fue la Campaña Nacional 1856?',
        [
          'Defensa contra filibusteros',
          'Independencia',
          'Guerra civil',
          'Invasión española',
        ],
        0,
        'Costa Rica derrotó a William Walker.',
        'Historia de Costa Rica',
      ),
      _createQ(
        '¿Qué es el multiculturalismo?',
        [
          'Convivencia de diversas culturas',
          'Dominancia de una cultura',
          'Eliminación cultural',
          'Aislamiento',
        ],
        0,
        'Reconoce y valora la diversidad cultural.',
        'Cívica',
      ),
      _createQ(
        '¿Qué es una zona econômica exclusiva?',
        [
          '200 millas náuticas de explotación',
          'Zona libre de impuestos',
          'Parque nacional marino',
          'Reserva indígena',
        ],
        0,
        'Costa Rica tiene derechos sobre sus recursos marinos.',
        'Geografía',
      ),
      _createQ(
        '¿Qué es el bipartidismo?',
        [
          'Dos partidos principales',
          'Muchos partidos',
          'Un solo partido',
          'Sin partidos',
        ],
        0,
        'Sistema con dos fuerzas políticas principales.',
        'Cívica',
      ),
      _createQ(
        '¿Qué recursos turísticos tiene Costa Rica?',
        [
          'Playas, volcanes, biodiversidad',
          'Desiertos',
          'Montañas nevadas',
          'Ciudades antiguas',
        ],
        0,
        'Costa Rica es famosa por ecoturismo.',
        'Geografía',
      ),
    ];
  }

  static List<Question> _createSpanishQuestions() {
    return [
      _createQ(
        '¿Qué es un sustantivo?',
        [
          'Palabra que indica acción',
          'Palabra que nombra seres, lugares o cosas',
          'Palabra que califica',
          'Palabra que conecta',
        ],
        1,
        'El sustantivo nombra seres, lugares, objetos o ideas.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es la metáfora?',
        [
          'Comparación usando "como"',
          'Recurso que da características humanas a objetos',
          'Exageración',
          'Repetición de sonidos',
        ],
        1,
        'La metáfora asigna cualidades de un elemento a otro sin usar "como".',
        'Literatura',
      ),
      _createQ(
        '¿Qué es el sujeto en una oración?',
        [
          'Lo que se dice del sujeto',
          'Quien realiza la acción o es descrito',
          'El verbo de la oración',
          'El complemento',
        ],
        1,
        'El sujeto realiza la acción o es descrito.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es el modernismo literario?',
        [
          'Movimiento de finales del siglo XIX',
          'Literatura medieval',
          'Poesía romántica',
          'Narrativa realista',
        ],
        0,
        'El modernismo se caracterizó por renovación formal y temática.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es la Lingüística?',
        [
          'Ciencia que estudia el lenguaje',
          'Estudio de matemáticas',
          'Historia de la literatura',
          'Geografía cultural',
        ],
        0,
        'La lingüística estudia el lenguaje humano.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es un verbo?',
        [
          'Palabra que nombra',
          'Palabra que indica acción o estado',
          'Palabra que califica',
          'Palabra que une',
        ],
        1,
        'El verbo expresa acciones o estados.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es una comparación (símil)?',
        [
          'Metáfora directa',
          'Uso de "como" para comparar',
          'Personificación',
          'Hipérbole',
        ],
        1,
        'El símil usa "como" o "parecido a".',
        'Literatura',
      ),
      _createQ(
        '¿Qué es el predicado?',
        [
          'Lo que se dice del sujeto',
          'El que realiza la acción',
          'El complemento directo',
          'El circunstancial',
        ],
        0,
        'El predicado es todo lo que se dice del sujeto.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es la hipérbole?',
        ['Exageración', 'Comparación', 'Metáfora', 'Onomatopeya'],
        0,
        'La hipérbole es una exageración intencional.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es un adverbio?',
        [
          'Palabra que nombra',
          'Palabra que indica acción',
          'Palabra que modifica al verbo, adjetivo u otro adverbio',
          'Palabra que conecta',
        ],
        2,
        'El adverbio modifica verbos, adjetivos u otros adverbios.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es la personificación?',
        [
          'Dar características humanas a animales u objetos',
          'Comparar con humanos',
          'Hablar de dioses',
          'Describir paisajes',
        ],
        0,
        'La personificación da cualidades humanas a seres no humanos.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es un adjetivo?',
        [
          'Palabra que nombra',
          'Palabra que indica acción',
          'Palabra que califica o determina al sustantivo',
          'Palabra que une',
        ],
        2,
        'El adjetivo califica o determina al sustantivo.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es el Realismo?',
        [
          'Corriente que representa la vida cotidiana',
          'Exageración de la realidad',
          'Escapar de la realidad',
          'Narrativa fantástica',
        ],
        0,
        'El Realismo representa la vida tal como es.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es una preposición?',
        [
          'Palabra que indica acción',
          'Palabra que une',
          'Palabra que introduce complementos',
          'Palabra que califica',
        ],
        2,
        'Las preposiciones unen palabras formando frases.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es una onomatopeya?',
        ['Palabra que imita sonidos', 'Exclamación', 'Pregunta', 'Respuesta'],
        0,
        'La onomatopeya imita sonidos de la realidad.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es una conjunción?',
        [
          'Palabra que une oraciones o palabras',
          'Palabra que indica lugar',
          'Palabra que indica tiempo',
          'Palabra que indica cantidad',
        ],
        0,
        'Las conjunciones unen palabras u oraciones.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es el Romanticismo?',
        [
          'Movimiento artístico del siglo XIX',
          'Arte contemporáneo',
          'Literatura medieval',
          'Neoclasicismo',
        ],
        0,
        'El Romanticismo valora sentimientos y naturaleza.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es el complemento directo?',
        [
          'Objeto sobre el cual recae la acción',
          'Sujeto de la oración',
          'Circunstancia de lugar',
          'Verbo auxiliar',
        ],
        0,
        'El CD responde a "¿qué?" o "¿a quién?".',
        'Gramática',
      ),
      _createQ(
        '¿Qué es una sílabas?',
        [
          'Unidad mínima de pronunciación',
          'Palabra completa',
          'Oración',
          'Puntuación',
        ],
        0,
        'Una sílaba es cada golpe de voz.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es el Barroco?',
        [
          'Movimiento artístico con ornamento excesivo',
          'Arte minimalista',
          'Renacimiento',
          'Impresionismo',
        ],
        0,
        'El Barroco se caracteriza por lo ornamentado y dramático.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es la prosodia?',
        [
          'Estudio de la pronunciación y acentuación',
          'Estudio de la gramática',
          'Estudio de la literatura',
          'Estudio de la escritura',
        ],
        0,
        'La prosodia estudia entonación, acento y pausas.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es un oxímoron?',
        [
          'Contradicción de términos',
          'Repetición de sonidos',
          'Comparación',
          'Metáfora',
        ],
        0,
        'El oxímoron une palabras contradictorias.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es la diptongo?',
        [
          'Combinación de dos vocales en una sílaba',
          'Separación de vocales',
          'Acentuación',
          'Puntuación',
        ],
        0,
        'Un diptongo tiene dos vocales en una sílaba.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es el Surrealismo?',
        [
          'Movimiento que explora el subconsciente',
          'Realismo mágico',
          'Arte clásico',
          'Minimalismo',
        ],
        0,
        'El Surrealismo explora los sueños y el inconsciente.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es una oración compuesta?',
        [
          'Dos o más oraciones unidas',
          'Una sola oración',
          'Oración simple',
          'Frase nominal',
        ],
        0,
        'La oración compuesta tiene varias oraciones.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es la ironía?',
        [
          'Decir lo contrario de lo que se piensa',
          'Exagerar',
          'Comparar',
          'Metonimia',
        ],
        0,
        'La ironía dice algo diferente a lo que significa.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es el hiato?',
        [
          'Separación de dos vocales',
          'Combinación de vocales',
          'Acentuación',
          'Puntuación',
        ],
        0,
        'El hiato separa dos vocales en sílabas distintas.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es el Existencialismo?',
        [
          'Filosofía sobre la libertad y responsabilidad',
          'Materialismo',
          'Idealismo',
          'Pragmatismo',
        ],
        0,
        'El existencialismo explora el sentido de la vida.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es una oración subordinada?',
        [
          'Dependiente de otra oración',
          'Oración principal',
          'Oración independiente',
          'Exclamación',
        ],
        0,
        'La oración subordinada depende de la principal.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es la sinécdoque?',
        [
          'Designar el todo por la parte o viceversa',
          'Comparación directa',
          'Metáfora simple',
          'Hipérbole',
        ],
        0,
        'Sinécdoque: "todos los brazos" por "todas las personas".',
        'Literatura',
      ),
      _createQ(
        '¿Qué es el complemento indirecto?',
        [
          'Destinatario de la acción',
          'Agente de la acción',
          'Circunstancia',
          'Verbo',
        ],
        0,
        'El CI responde a "a quién" o "para quién".',
        'Gramática',
      ),
      _createQ(
        '¿Qué es el Realismo mágico?',
        [
          'Magia en un contexto realista',
          'Realismo puro',
          'Fantasía',
          'Ciencia ficción',
        ],
        0,
        'Mezcla elementos fantásticos con lo cotidiano.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es una interjección?',
        ['Expresión de emoción', 'Pregunta', 'Afirmación', 'Negación'],
        0,
        'La interjección expresa emociones: ¡Ay!, ¡Oh!',
        'Gramática',
      ),
      _createQ(
        '¿Qué es el Modernismo?',
        [
          'Movimiento literario de 1880-1920',
          'Actualidad',
          'Siglo XVIII',
          'Posmodernismo',
        ],
        0,
        'El Modernismo valoraba la belleza y el ritmo.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es el triptongo?',
        ['Tres vocales en una sílaba', 'Dos vocales', 'Una vocal', 'Ninguna'],
        0,
        'Un triptongo tiene tres vocales seguidas en una sílaba.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es la alegoría?',
        [
          'Representación de ideas abstractas con figuras',
          'Metáfora simple',
          'Comparación',
          'Símbolo',
        ],
        0,
        'La alegoría representa conceptos abstractos.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es el complemento circunstancial?',
        [
          'Circunstancias de lugar, tiempo, modo',
          'Sujeto oculto',
          'Verbo compuesto',
          'Artículo',
        ],
        0,
        'El CC indica cómo, dónde, cuándo ocurre la acción.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es el Boom latinoamericano?',
        [
          'Explosión literaria latinoamericana 1960-1970',
          'Movimiento anterior',
          'Literatura europea',
          'Poesía',
        ],
        0,
        'El Boom incluyó a García Márquez, Vargas Llosa, Cortázar.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es la sílaba tónica?',
        [
          'Sílaba con acento',
          'Sílaba sin acento',
          'Primera sílaba',
          'Última sílaba',
        ],
        0,
        'La sílaba tónica lleva el acento.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es el costumbrismo?',
        [
          'Representación de costumbres de un pueblo',
          'Arte sofisticado',
          'Poesía épica',
          'Teatro',
        ],
        0,
        'El costumbrismo muestra la vida cotidiana.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es un artículo?',
        [
          'Palabra que precede al sustantivo',
          'Verbo',
          'Adjetivo',
          'Conjunción',
        ],
        0,
        'Los artículos pueden ser definidos o indefinidos.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es la antítesis?',
        ['Contraposición de ideas', 'Repetición', 'Comparación', 'Metáfora'],
        0,
        'La antítesis juxtapone ideas opuestas.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es un pronombre?',
        [
          'Palabra que sustituye al sustantivo',
          'El nombre',
          'El verbo',
          'El adjetivo',
        ],
        0,
        'Los pronombres evitan repetir sustantivos.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es el vanguardismo?',
        [
          'Movimientos artísticos de principios del siglo XX',
          'Arte tradicional',
          'Clasicismo',
          'Barroco',
        ],
        0,
        'Las vanguardias buscaban innovar y experimentar.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es un demostrativo?',
        [
          'Palabra que indica cercanía o lejanía',
          'Verbo',
          'Sustantivo',
          'Adverbio',
        ],
        0,
        'Demostrativos: este, ese, aquel y sus formas.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es la elipsis?',
        [
          'Omisión de palabras sobrentendidas',
          'Repetición',
          'Exageración',
          'Comparación',
        ],
        0,
        'La elipsis omite palabras que se sobrentienden.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es un posesivo?',
        [
          'Indica pertenencia',
          'Indica cantidad',
          'Indica acción',
          'Indica tiempo',
        ],
        0,
        'Posesivos: mi, tu, su, nuestro, etc.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es el Neoclasicismo?',
        [
          'Movimiento que imita a griegos y romanos',
          'Barroco tardío',
          'Romanticismo',
          'Impresionismo',
        ],
        0,
        'El Neoclasicismo seguía modelos clásicos.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es un numeral?',
        ['Indica cantidad u orden', 'Verbo', 'Adjetivo', 'Sustantivo'],
        0,
        'Numrales: uno, dos, primero, segundo.',
        'Gramática',
      ),
      _createQ(
        '¿Qué es la eufonía?',
        ['Sonoridad agradable', 'Sonido discordante', 'Silencio', 'Ruido'],
        0,
        'La eufonía busca sonidos agradables.',
        'Literatura',
      ),
      _createQ(
        '¿Qué es un infinitivo?',
        [
          'Forma verbal terminada en -ar, -er, -ir',
          'Verbo conjugado',
          'Sustantivo',
          'Adjetivo',
        ],
        0,
        'El infinitivo es la forma base del verbo.',
        'Gramática',
      ),
    ];
  }

  static final Map<int, List<Question>> _mathQuestions = {
    0: _createMathQuestions(),
    1: _createMathQuestions(),
    2: _createMathQuestions(),
  };

  static final Map<int, List<Question>> _scienceQuestions = {
    0: _createScienceQuestions(),
    1: _createScienceQuestions(),
    2: _createScienceQuestions(),
  };

  static final Map<int, List<Question>> _socialStudiesQuestions = {
    0: _createSocialStudiesQuestions(),
    1: _createSocialStudiesQuestions(),
    2: _createSocialStudiesQuestions(),
  };

  static final Map<int, List<Question>> _spanishQuestions = {
    0: _createSpanishQuestions(),
    1: _createSpanishQuestions(),
    2: _createSpanishQuestions(),
  };

  static Question _createQ(
    String question,
    List<String> options,
    int correctIndex,
    String explanation,
    String topic,
  ) {
    return Question.create(
      odId: DateTime.now().microsecondsSinceEpoch.toString(),
      question: question,
      options: options,
      correctAnswerIndex: correctIndex,
      explanation: explanation,
      categoryIndex: 0,
      levelIndex: 0,
      topic: topic,
    );
  }
}

class _ReviewMistakesPage extends StatefulWidget {
  final List<Question> questions;
  final List<int> userAnswers;
  final String subjectName;

  const _ReviewMistakesPage({
    required this.questions,
    required this.userAnswers,
    required this.subjectName,
  });

  @override
  State<_ReviewMistakesPage> createState() => _ReviewMistakesPageState();
}

class _ReviewMistakesPageState extends State<_ReviewMistakesPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];
    final userAnswer = widget.userAnswers[_currentIndex];
    final letters = ['A', 'B', 'C', 'D'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Revisar: ${widget.subjectName}'),
        backgroundColor: AppTheme.cardColor,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Error ${_currentIndex + 1} de ${widget.questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    question.topic,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.questions.length,
            backgroundColor: AppTheme.surfaceColor,
            valueColor: const AlwaysStoppedAnimation(Colors.red),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withValues(alpha: 0.2),
                          Colors.orange.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Tu respuesta incorrecta',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question.question,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${letters[userAnswer]}) ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[300],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  question.options[userAnswer],
                                  style: TextStyle(color: Colors.red[300]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withValues(alpha: 0.2),
                          Colors.teal.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Respuesta correcta',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${letters[question.correctAnswerIndex]}) ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  question.correctAnswer,
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Explicación',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                question.explanation,
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _currentIndex--),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Anterior'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentIndex < widget.questions.length - 1
                        ? () => setState(() => _currentIndex++)
                        : () => Navigator.pop(context),
                    icon: Icon(
                      _currentIndex < widget.questions.length - 1
                          ? Icons.arrow_forward
                          : Icons.check,
                    ),
                    label: Text(
                      _currentIndex < widget.questions.length - 1
                          ? 'Siguiente'
                          : 'Terminar',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
