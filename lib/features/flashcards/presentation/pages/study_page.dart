import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/sm2_algorithm.dart';
import '../../../../core/services/tts_service.dart';
import '../../data/models/flashcard.dart';

class StudyPage extends ConsumerWidget {
  const StudyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider) ?? '';
    final flashcardsAsync = ref.watch(flashcardsNotifierProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Estudiar')),
      body: SafeArea(
        child: flashcardsAsync.when(
          data: (flashcards) =>
              _StudyContent(flashcards: flashcards, userId: userId),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFlashcardDialog(context, ref, userId),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddFlashcardDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final frontController = TextEditingController();
    final backController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Tarjeta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: frontController,
              decoration: const InputDecoration(
                labelText: 'Pregunta',
                hintText: 'Frente de la tarjeta',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: backController,
              decoration: const InputDecoration(
                labelText: 'Respuesta',
                hintText: 'Dorso de la tarjeta',
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
            onPressed: () {
              if (frontController.text.isNotEmpty &&
                  backController.text.isNotEmpty) {
                ref
                    .read(flashcardsNotifierProvider(userId).notifier)
                    .addFlashcard(
                      front: frontController.text,
                      back: backController.text,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}

class _StudyContent extends ConsumerStatefulWidget {
  final List<Flashcard> flashcards;
  final String userId;

  const _StudyContent({required this.flashcards, required this.userId});

  @override
  ConsumerState<_StudyContent> createState() => _StudyContentState();
}

class _StudyContentState extends ConsumerState<_StudyContent> {
  bool _isFlipped = false;
  int _currentIndex = 0;
  late List<Flashcard> _dueCards;

  @override
  void initState() {
    super.initState();
    _loadDueCards();
  }

  @override
  void didUpdateWidget(covariant _StudyContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flashcards != widget.flashcards) {
      _loadDueCards();
    }
  }

  void _loadDueCards() {
    setState(() {
      _dueCards = widget.flashcards
          .where(
            (c) =>
                c.nextReview == null || c.nextReview!.isBefore(DateTime.now()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return _buildEmptyState();
    }

    if (_dueCards.isEmpty) {
      return _buildAllStudiedState();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProgress(),
          const SizedBox(height: 24),
          _buildFlashcard(_dueCards[_currentIndex]),
          const SizedBox(height: 16),
          _buildTTSButtons(_dueCards[_currentIndex]),
          const SizedBox(height: 24),
          if (_isFlipped) _buildQualityButtons(_dueCards[_currentIndex]),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No hay tarjetas para estudiar',
            style: TextStyle(fontSize: 18, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tarjetas para comenzar',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildAllStudiedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Todo al día!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'No tienes tarjetas pendientes',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tarjeta ${_currentIndex + 1} de ${_dueCards.length}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_dueCards.length} pendientes',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _dueCards.isEmpty ? 0 : (_currentIndex + 1) / _dueCards.length,
          backgroundColor: AppTheme.cardColor,
          valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildFlashcard(Flashcard card) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isFlipped = !_isFlipped),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Container(
            key: ValueKey(_isFlipped),
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isFlipped
                    ? [
                        AppTheme.secondaryColor.withValues(alpha: 0.3),
                        AppTheme.cardColor,
                      ]
                    : [
                        AppTheme.primaryColor.withValues(alpha: 0.3),
                        AppTheme.cardColor,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isFlipped
                    ? AppTheme.secondaryColor
                    : AppTheme.primaryColor,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isFlipped ? 'RESPUESTA' : 'PREGUNTA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isFlipped
                        ? AppTheme.secondaryColor
                        : AppTheme.primaryColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isFlipped ? card.back : card.front,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  'Toca para ${_isFlipped ? "ver pregunta" : "ver respuesta"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTTSButtons(Flashcard card) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => TTSService.instance.speakFront(card.front),
            icon: const Icon(Icons.volume_up, size: 18),
            label: const Text('Pregunta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => TTSService.instance.speakBack(card.back),
            icon: const Icon(Icons.volume_up, size: 18),
            label: const Text('Respuesta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.secondaryColor,
              side: const BorderSide(color: AppTheme.secondaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQualityButtons(Flashcard card) {
    final sm2 = ref.read(sm2AlgorithmProvider);
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow[700]!,
      Colors.lightGreen,
      Colors.green,
      Colors.green[700]!,
    ];

    return Column(
      children: [
        const Text(
          '¿Qué tan bien la recordaste?',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (quality) {
            return InkWell(
              onTap: () => _rateCard(card, quality, sm2),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colors[quality].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors[quality]),
                ),
                child: Center(
                  child: Text(
                    '${quality + 1}',
                    style: TextStyle(
                      color: colors[quality],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _rateCard(Flashcard card, int quality, SM2Algorithm sm2) async {
    final result = sm2.calculate(
      quality: quality,
      easeFactor: card.easeFactor,
      interval: card.interval,
      repetitions: card.repetitions,
    );

    card.easeFactor = result.easeFactor;
    card.interval = result.interval;
    card.repetitions = result.repetitions;
    card.nextReview = result.nextReview;
    card.lastReviewedAt = DateTime.now();
    card.status = quality >= 4
        ? FlashcardStatus.mastered
        : (quality >= 3 ? FlashcardStatus.review : FlashcardStatus.learning);

    await ref
        .read(flashcardsNotifierProvider(widget.userId).notifier)
        .updateFlashcard(card);

    setState(() {
      _isFlipped = false;
      if (_currentIndex < _dueCards.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
    });
  }
}
