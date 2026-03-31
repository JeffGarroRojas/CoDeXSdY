import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/user_preferences.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onComplete;

  const OnboardingPage({
    super.key,
    required this.userId,
    required this.onComplete,
  });

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _preferences = <String, dynamic>{};
  final _nameController = TextEditingController();

  final _onboardingQuestions = [
    {
      'title': '¡Hola! Soy DeX',
      'subtitle':
          'Vamos a conocerte para personalizar tu experiencia de estudio.',
      'icon': Icons.waving_hand,
    },
    {
      'title': '¿Cómo te llamas?',
      'subtitle': 'Me gusta saber a quién estoy ayudando.',
      'field': 'name',
      'hint': 'Tu nombre',
    },
    {
      'title': '¿Cuál es tu nivel de estudios?',
      'subtitle': 'Así puedo adaptar el contenido a ti.',
      'field': 'studyLevel',
      'options': [
        {'value': 'Primaria', 'icon': Icons.school},
        {'value': 'Secundaria', 'icon': Icons.school},
        {'value': 'Preparatoria', 'icon': Icons.school_outlined},
        {'value': 'Universidad', 'icon': Icons.school},
        {'value': 'Posgrado', 'icon': Icons.school},
        {'value': 'Autodidacta', 'icon': Icons.self_improvement},
      ],
    },
    {
      'title': '¿Qué materias estudias?',
      'subtitle': 'Selecciona las que te interesen.',
      'field': 'subjects',
      'multiSelect': true,
      'options': [
        {'value': 'Matemáticas', 'icon': Icons.calculate},
        {'value': 'Ciencias', 'icon': Icons.science},
        {'value': 'Historia', 'icon': Icons.history_edu},
        {'value': 'Literatura', 'icon': Icons.menu_book},
        {'value': 'Idiomas', 'icon': Icons.translate},
        {'value': 'Programación', 'icon': Icons.computer},
        {'value': 'Arte', 'icon': Icons.palette},
        {'value': 'Música', 'icon': Icons.music_note},
        {'value': 'Economía', 'icon': Icons.attach_money},
        {'value': 'Psicología', 'icon': Icons.psychology},
      ],
    },
    {
      'title': '¿Cuál es tu objetivo principal?',
      'subtitle': 'Esto me ayuda a guiarte mejor.',
      'field': 'studyGoal',
      'options': [
        {'value': 'Aprobar exámenes', 'icon': Icons.check_circle},
        {'value': 'Aprender algo nuevo', 'icon': Icons.lightbulb},
        {'value': 'Repasar temas', 'icon': Icons.refresh},
        {'value': 'Prepararme para oposiciones', 'icon': Icons.fitness_center},
        {'value': 'Desarrollo profesional', 'icon': Icons.trending_up},
      ],
    },
    {
      'title': '¿Cuánto tiempo puedes estudiar al día?',
      'subtitle': 'Planificaré tu revisión espaciada accordingly.',
      'field': 'dailyStudyMinutes',
      'options': [
        {'value': '15 min', 'icon': Icons.timer},
        {'value': '30 min', 'icon': Icons.timer},
        {'value': '45 min', 'icon': Icons.timer},
        {'value': '1 hora', 'icon': Icons.timer},
        {'value': '2+ horas', 'icon': Icons.timer},
      ],
    },
    {
      'title': '¿Cómo prefieres aprender?',
      'subtitle': 'Adaptaré mis respuestas a tu estilo.',
      'field': 'learningStyle',
      'options': [
        {'value': 'Con ejemplos prácticos', 'icon': Icons.build},
        {'value': 'Con explicaciones teóricas', 'icon': Icons.book},
        {'value': 'Con preguntas y respuestas', 'icon': Icons.help},
        {'value': 'Con resúmenes', 'icon': Icons.summarize},
        {'value': 'Con flashcards', 'icon': Icons.style},
      ],
    },
    {
      'title': '¡Listo!',
      'subtitle': 'He guardado tu información. ¡Vamos a estudiar!',
      'icon': Icons.celebration,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _onboardingQuestions.length,
                itemBuilder: (context, index) => _buildPage(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'DeX',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_currentPage + 1) / _onboardingQuestions.length,
            backgroundColor: AppTheme.cardColor,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentPage + 1} de ${_onboardingQuestions.length}',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    final question = _onboardingQuestions[index];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          if (question['icon'] != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                question['icon'] as IconData,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ).animate().fadeIn().scale(),
          ],
          const SizedBox(height: 32),
          Text(
            question['title'] as String,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          Text(
            question['subtitle'] as String,
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 40),
          _buildQuestionContent(question),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(Map<String, dynamic> question) {
    final field = question['field'] as String?;

    if (field == null) {
      return _buildNextButton();
    }

    if (question['multiSelect'] == true) {
      return _buildMultiSelectOptions(question);
    }

    if (question['options'] != null) {
      return _buildOptions(question);
    }

    return _buildTextField(question);
  }

  Widget _buildTextField(Map<String, dynamic> question) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: question['hint'] ?? '',
            filled: true,
            fillColor: AppTheme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(fontSize: 18),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        _buildNextButton(),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildOptions(Map<String, dynamic> question) {
    final options = question['options'] as List;
    final field = question['field'] as String;

    return Column(
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value as Map<String, dynamic>;
                final isSelected = _preferences[field] == option['value'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() => _preferences[field] = option['value']);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.2)
                            : AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            option['icon'] ?? Icons.circle,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey[400],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              option['value'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey[200],
                              ),
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
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 300 + (index * 50)),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildMultiSelectOptions(Map<String, dynamic> question) {
    final options = question['options'] as List;
    final field = question['field'] as String;
    final selectedSubjects = _preferences[field] as List<String>? ?? [];

    return Column(
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value as Map<String, dynamic>;
                final isSelected = selectedSubjects.contains(option['value']);

                return FilterChip(
                  selected: isSelected,
                  label: Text(option['value'] as String),
                  avatar: Icon(
                    option['icon'] as IconData? ?? Icons.circle,
                    size: 18,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedSubjects.add(option['value'] as String);
                      } else {
                        selectedSubjects.remove(option['value']);
                      }
                      _preferences[field] = selectedSubjects;
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                  checkmarkColor: AppTheme.primaryColor,
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 300 + (index * 30)),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildNextButton(
          enabled: selectedSubjects.isNotEmpty,
          label: selectedSubjects.isEmpty
              ? 'Selecciona al menos una'
              : 'Continuar',
        ),
      ],
    );
  }

  Widget _buildNextButton({bool enabled = true, String? label}) {
    final isLastPage = _currentPage == _onboardingQuestions.length - 1;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? _handleNext : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label ?? (isLastPage ? 'Comenzar' : 'Continuar'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(isLastPage ? Icons.celebration : Icons.arrow_forward),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  void _handleNext() async {
    final question = _onboardingQuestions[_currentPage];
    final field = question['field'] as String?;

    if (field != null) {
      if (field == 'name') {
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor ingresa tu nombre')),
          );
          return;
        }
        _preferences[field] = _nameController.text.trim();
      }

      if (_preferences[field] == null ||
          (_preferences[field] is List &&
              (_preferences[field] as List).isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona una opción')),
        );
        return;
      }
    }

    if (_currentPage == _onboardingQuestions.length - 1) {
      await _savePreferences();
      widget.onComplete();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage++);
  }

  Future<void> _savePreferences() async {
    final prefs = UserPreferences.create(
      odId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.userId,
      name: _preferences['name'],
      studyLevel: _preferences['studyLevel'],
      subjects: _preferences['subjects'] as List<String>? ?? [],
      studyGoal: _preferences['studyGoal'],
      dailyStudyMinutes: _parseMinutes(_preferences['dailyStudyMinutes']),
      learningStyle: _preferences['learningStyle'],
      onboardingCompleted: true,
    );

    await ref.read(databaseServiceProvider).updateUserPreferences(prefs);
  }

  int? _parseMinutes(String? value) {
    if (value == null) return null;
    if (value.contains('min'))
      return int.tryParse(value.replaceAll(' min', ''));
    if (value.contains('hora')) {
      final hours = int.tryParse(
        value.replaceAll(' hora', '').replaceAll('+', ''),
      );
      return hours != null ? hours * 60 : null;
    }
    return null;
  }
}
