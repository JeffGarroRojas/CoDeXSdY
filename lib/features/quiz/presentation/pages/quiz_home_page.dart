import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import 'quiz_session_page.dart';
import 'quiz_history_page.dart';

class QuizHomePage extends StatefulWidget {
  const QuizHomePage({super.key});

  @override
  State<QuizHomePage> createState() => _QuizHomePageState();
}

class _QuizHomePageState extends State<QuizHomePage> {
  final List<Map<String, dynamic>> _subjects = [
    {
      'name': 'Matemáticas',
      'icon': Icons.calculate,
      'color': Colors.blue,
      'questions': 50,
      'minutes': 90,
      'topics': [
        'Conjuntos numéricos',
        'Expresiones algebraicas',
        'Ecuaciones',
        'Proporcionalidad',
        'Porcentajes',
        'Figuras planas',
        'Perímetro y área',
        'Trigonometría',
        'Probabilidad',
        'Funciones',
      ],
    },
    {
      'name': 'Ciencias',
      'icon': Icons.science,
      'color': Colors.green,
      'questions': 50,
      'minutes': 90,
      'topics': [
        'Célula',
        'Fotosíntesis',
        'Genética',
        'Evolución',
        'Ecosistemas',
        'Materia',
        'Átomo',
        'Reacciones químicas',
        'Movimiento',
        'Electricidad',
      ],
    },
    {
      'name': 'Estudios Sociales',
      'icon': Icons.public,
      'color': Colors.brown,
      'questions': 50,
      'minutes': 90,
      'topics': [
        'Independencia CR',
        'Formación República',
        'Constitución 1949',
        'Derechos humanos',
        'Democracia',
        'Geografía CR',
        'Economía',
        'Globalización',
      ],
    },
    {
      'name': 'Español',
      'icon': Icons.menu_book,
      'color': Colors.red,
      'questions': 50,
      'minutes': 90,
      'topics': [
        'Gramática',
        'Ortografía',
        'Literatura',
        'Narrativa',
        'Poesía',
        'Texto argumentativo',
        'Comprensión lectora',
        'Redacción',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulacros MEP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuizHistoryPage()),
              );
            },
            tooltip: 'Ver historial',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMepExams(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.3),
            AppTheme.secondaryColor.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exámenes MEP Costa Rica',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prepárate para tus pruebas nacionales',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildMepExams(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 Simulacros MEP',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '50 preguntas por materia - Generadas con IA',
          style: TextStyle(color: Colors.grey[500]),
        ),
        const SizedBox(height: 16),
        ...List.generate(_subjects.length, (index) {
          final subject = _subjects[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSubjectCard(context, subject, index),
          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
        }),
      ],
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    Map<String, dynamic> subject,
    int index,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizSessionPage(
              levelIndex: 0,
              subjectName: subject['name'] as String,
              subjectIndex: index,
              questionCount: subject['questions'] as int,
              durationMinutes: subject['minutes'] as int,
              topics: subject['topics'] as List<String>,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (subject['color'] as Color).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (subject['color'] as Color).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                subject['icon'] as IconData,
                color: subject['color'] as Color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject['name'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '50 preguntas • 90 minutos',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_fill,
              color: subject['color'] as Color,
              size: 36,
            ),
          ],
        ),
      ),
    );
  }
}
