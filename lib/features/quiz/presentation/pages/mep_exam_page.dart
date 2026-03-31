import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import 'quiz_session_page.dart';

class MEPExamPage extends StatefulWidget {
  final int levelIndex;

  const MEPExamPage({super.key, required this.levelIndex});

  @override
  State<MEPExamPage> createState() => _MEPExamPageState();
}

class _MEPExamPageState extends State<MEPExamPage> {
  final List<Map<String, dynamic>> _subjects = [
    {
      'name': 'Matemáticas',
      'icon': Icons.calculate,
      'color': Colors.blue,
      'topics': [
        'Conjuntos numéricos',
        'Expresiones algebraicas',
        'Ecuaciones e inecuaciones',
        'Proporcionalidad',
        'Porcentajes',
        'Potencias y raíces',
        'Figuras planas y cuerpos geométricos',
        'Perímetro, área y volumen',
        'Transformaciones en el plano',
        'Congruencia y similitud de triángulos',
        'Razones trigonométricas',
        'Teorema de Pitágoras',
        'Medidas de tendencia central',
        'Probabilidad básica',
        'Relaciones y funciones',
        'Funciones lineales y cuadráticas',
        'Sistemas de ecuaciones',
        'Polinomios y factorización',
      ],
      'questions': 50,
      'minutes': 90,
    },
    {
      'name': 'Ciencias',
      'icon': Icons.science,
      'color': Colors.green,
      'topics': [
        'Célula y organelos',
        'Fotosíntesis y respiración',
        'Genética y herencia',
        'Evolución biológica',
        'Ecosistemas',
        'Materia y energía',
        'Átomo y tabla periódica',
        'Enlace químico',
        'Reacciones químicas',
        'Movimiento y fuerza',
        'Leyes de Newton',
        'Energía y trabajo',
        'Ondas y sonido',
        'Electricidad y magnetismo',
        'Sistema nervioso',
        'Sistema inmunológico',
      ],
      'questions': 50,
      'minutes': 90,
    },
    {
      'name': 'Estudios Sociales',
      'icon': Icons.public,
      'color': Colors.brown,
      'topics': [
        'Independencia de Costa Rica',
        'Formación de la República',
        'Juan Rafael Mora Porras',
        'Juan Santamaría y Campaña Nacional',
        'Constitución Política de 1949',
        'Derechos humanos',
        'Democracia y ciudadanía',
        'Geografía de Costa Rica',
        'Organización política',
        'Economía costarricense',
        'Globalización',
        'Historia de Centroamérica',
        'Culturas prehispánicas',
        'Relaciones internacionales',
      ],
      'questions': 50,
      'minutes': 90,
    },
    {
      'name': 'Español',
      'icon': Icons.menu_book,
      'color': Colors.red,
      'topics': [
        'Sustantivos y adjetivos',
        'Verbo y conjugaciones',
        'Pronombres y artículos',
        'Ortografía y acentuación',
        'Figuras retóricas',
        'Géneros literarios',
        'Narrativa y cuento',
        'Poesía',
        'Texto argumentativo',
        'Comprensión lectora',
        'Análisis de texto',
        'Redacción',
      ],
      'questions': 50,
      'minutes': 90,
    },
  ];

  String _getLevelName() {
    return '12° Año (3° Bachillerato)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Examen $_levelName')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSubjectSelection(),
          ],
        ),
      ),
    );
  }

  String get _levelName => _getLevelName();

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getLevelColor().withValues(alpha: 0.3),
            _getLevelColor().withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getLevelColor(),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.timer, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _levelName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Examen Estandarizado MEP Costa Rica',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('⏱️', '90 min', 'Tiempo'),
                _buildStat('📝', '50 preg', 'Por materia'),
                _buildStat('✅', '60%', 'Para aprobar'),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Color _getLevelColor() {
    return Colors.orange;
  }

  Widget _buildStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  Widget _buildSubjectSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📚 Selecciona una Materia',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'El examen incluirá temas de toda la materia',
          style: TextStyle(color: Colors.grey[500]),
        ),
        const SizedBox(height: 16),
        ...List.generate(_subjects.length, (index) {
          final subject = _subjects[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSubjectCard(subject, index),
          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
        }),
      ],
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, int index) {
    return InkWell(
      onTap: () => _startExam(subject),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (subject['color'] as Color).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subject['questions']} preguntas • ${subject['minutes']} minutos',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_circle_fill,
                  color: subject['color'] as Color,
                  size: 40,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (subject['topics'] as List<String>).map((topic) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (subject['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    topic,
                    style: TextStyle(
                      fontSize: 12,
                      color: subject['color'] as Color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _startExam(Map<String, dynamic> subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizSessionPage(
          levelIndex: 0,
          subjectName: subject['name'] as String,
          subjectIndex: _subjects.indexOf(subject),
          questionCount: subject['questions'] as int,
          durationMinutes: subject['minutes'] as int,
          topics: subject['topics'] as List<String>,
        ),
      ),
    );
  }
}
