import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/sm2_algorithm.dart';

void main() {
  group('SM2Algorithm', () {
    late SM2Algorithm sm2;

    setUp(() {
      sm2 = SM2Algorithm();
    });

    test('should initialize with default ease factor', () {
      expect(SM2Algorithm.defaultEaseFactor, 2.5);
      expect(SM2Algorithm.minEaseFactor, 1.3);
    });

    group('First successful review (repetitions = 0)', () {
      test('should set interval to 1 day on first successful review', () {
        final result = sm2.calculate(
          quality: 4,
          easeFactor: 2.5,
          interval: 0,
          repetitions: 0,
        );

        expect(result.interval, 1);
        expect(result.repetitions, 1);
      });
    });

    group('Second successful review (repetitions = 1)', () {
      test('should set interval to 6 days on second successful review', () {
        final result = sm2.calculate(
          quality: 4,
          easeFactor: 2.5,
          interval: 1,
          repetitions: 1,
        );

        expect(result.interval, 6);
        expect(result.repetitions, 2);
      });
    });

    group('Third+ successful review (repetitions >= 2)', () {
      test('should multiply interval by ease factor', () {
        final result = sm2.calculate(
          quality: 4,
          easeFactor: 2.5,
          interval: 6,
          repetitions: 2,
        );

        expect(result.interval, 15); // 6 * 2.5 = 15
        expect(result.repetitions, 3);
      });

      test('should compound intervals over multiple reviews', () {
        var result = sm2.calculate(
          quality: 4,
          easeFactor: 2.5,
          interval: 6,
          repetitions: 2,
        );
        expect(result.interval, 15);

        result = sm2.calculate(
          quality: 4,
          easeFactor: result.easeFactor,
          interval: result.interval,
          repetitions: result.repetitions,
        );
        expect(
          result.interval,
          greaterThanOrEqualTo(37),
        ); // 15 * 2.5 = 37.5 -> 38
      });
    });

    group('Failed review (quality < 3)', () {
      test('should reset repetitions to 0 on failed review', () {
        final result = sm2.calculate(
          quality: 2,
          easeFactor: 2.5,
          interval: 10,
          repetitions: 5,
        );

        expect(result.repetitions, 0);
        expect(result.interval, 1);
      });

      test('should set interval to 1 day on any failed review', () {
        final result = sm2.calculate(
          quality: 0,
          easeFactor: 2.5,
          interval: 30,
          repetitions: 10,
        );

        expect(result.interval, 1);
        expect(result.repetitions, 0);
      });
    });

    group('Ease factor adjustments', () {
      test('should decrease ease factor on poor quality', () {
        final result = sm2.calculate(
          quality: 0,
          easeFactor: 2.5,
          interval: 0,
          repetitions: 0,
        );

        expect(result.easeFactor, lessThan(2.5));
        expect(result.easeFactor, greaterThanOrEqualTo(1.3));
      });

      test('should increase ease factor on excellent quality', () {
        final result = sm2.calculate(
          quality: 5,
          easeFactor: 2.5,
          interval: 0,
          repetitions: 0,
        );

        expect(result.easeFactor, greaterThan(2.5));
      });

      test('should never go below minimum ease factor', () {
        var result = sm2.calculate(
          quality: 0,
          easeFactor: 1.4,
          interval: 0,
          repetitions: 0,
        );
        expect(result.easeFactor, 1.3);

        for (int i = 0; i < 10; i++) {
          result = sm2.calculate(
            quality: 0,
            easeFactor: result.easeFactor,
            interval: result.interval,
            repetitions: result.repetitions,
          );
        }
        expect(result.easeFactor, 1.3);
      });
    });

    group('Quality bounds', () {
      test('should throw ArgumentError for quality < 0', () {
        expect(
          () => sm2.calculate(
            quality: -1,
            easeFactor: 2.5,
            interval: 0,
            repetitions: 0,
          ),
          throwsArgumentError,
        );
      });

      test('should throw ArgumentError for quality > 5', () {
        expect(
          () => sm2.calculate(
            quality: 6,
            easeFactor: 2.5,
            interval: 0,
            repetitions: 0,
          ),
          throwsArgumentError,
        );
      });
    });

    group('Quality labels', () {
      test('should return correct labels for all quality levels', () {
        expect(SM2Algorithm.qualityLabel(0), 'Sin respuesta');
        expect(SM2Algorithm.qualityLabel(1), 'Muy difícil');
        expect(SM2Algorithm.qualityLabel(2), 'Difícil');
        expect(SM2Algorithm.qualityLabel(3), 'Con esfuerzo');
        expect(SM2Algorithm.qualityLabel(4), 'Fácil');
        expect(SM2Algorithm.qualityLabel(5), 'Muy fácil');
        expect(SM2Algorithm.qualityLabel(6), 'Desconocido');
        expect(SM2Algorithm.qualityLabel(-1), 'Desconocido');
      });
    });

    group('Next review date', () {
      test('should set next review date based on interval', () {
        final before = DateTime.now();
        final result = sm2.calculate(
          quality: 4,
          easeFactor: 2.5,
          interval: 5,
          repetitions: 2,
        );
        final after = DateTime.now();

        expect(
          result.nextReview.isAfter(before.add(const Duration(days: 12))),
          isTrue,
        );
        expect(
          result.nextReview.isBefore(after.add(const Duration(days: 14))),
          isTrue,
        );
      });
    });
  });
}
