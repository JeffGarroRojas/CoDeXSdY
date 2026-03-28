class SM2Result {
  final double easeFactor;
  final int interval;
  final int repetitions;
  final DateTime nextReview;

  SM2Result({
    required this.easeFactor,
    required this.interval,
    required this.repetitions,
    required this.nextReview,
  });
}

class SM2Algorithm {
  static const double minEaseFactor = 1.3;
  static const double defaultEaseFactor = 2.5;

  SM2Result calculate({
    required int quality,
    required double easeFactor,
    required int interval,
    required int repetitions,
  }) {
    if (quality < 0 || quality > 5) {
      throw ArgumentError('Quality must be between 0 and 5');
    }

    double newEaseFactor = easeFactor;
    int newInterval;
    int newRepetitions;

    if (quality >= 3) {
      if (repetitions == 0) {
        newInterval = 1;
      } else if (repetitions == 1) {
        newInterval = 6;
      } else {
        newInterval = (interval * easeFactor).round();
      }
      newRepetitions = repetitions + 1;
    } else {
      newRepetitions = 0;
      newInterval = 1;
    }

    newEaseFactor =
        easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEaseFactor < minEaseFactor) {
      newEaseFactor = minEaseFactor;
    }

    final nextReview = DateTime.now().add(Duration(days: newInterval));

    return SM2Result(
      easeFactor: newEaseFactor,
      interval: newInterval,
      repetitions: newRepetitions,
      nextReview: nextReview,
    );
  }

  static String qualityLabel(int quality) {
    switch (quality) {
      case 0:
        return 'Sin respuesta';
      case 1:
        return 'Muy difícil';
      case 2:
        return 'Difícil';
      case 3:
        return 'Con esfuerzo';
      case 4:
        return 'Fácil';
      case 5:
        return 'Muy fácil';
      default:
        return 'Desconocido';
    }
  }
}
