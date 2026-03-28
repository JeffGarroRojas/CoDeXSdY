import 'package:flutter_test/flutter_test.dart';
import 'package:codex_sdy/core/services/validation_service.dart';

void main() {
  group('ValidationService', () {
    late ValidationService validation;

    setUp(() {
      validation = ValidationService.instance;
    });

    group('validateEmail', () {
      test('should return error for empty email', () {
        expect(validation.validateEmail(null), 'El email es requerido');
        expect(validation.validateEmail(''), 'El email es requerido');
        expect(validation.validateEmail('   '), 'El email es requerido');
      });

      test('should return error for invalid email format', () {
        expect(
          validation.validateEmail('notanemail'),
          'Ingresa un email válido',
        );
        expect(
          validation.validateEmail('missing@domain'),
          'Ingresa un email válido',
        );
        expect(
          validation.validateEmail('@nodomain.com'),
          'Ingresa un email válido',
        );
      });

      test('should accept valid emails', () {
        expect(validation.validateEmail('test@example.com'), isNull);
        expect(validation.validateEmail('user.name@domain.org'), isNull);
      });

      test('should reject overly long email', () {
        final longEmail = '${'a' * 250}@test.com';
        expect(validation.validateEmail(longEmail), 'El email es muy largo');
      });
    });

    group('validatePassword', () {
      test('should return error for empty password', () {
        expect(validation.validatePassword(null), 'La contraseña es requerida');
        expect(validation.validatePassword(''), 'La contraseña es requerida');
      });

      test('should return error for short password', () {
        expect(
          validation.validatePassword('1234567'),
          'La contraseña debe tener al menos 8 caracteres',
        );
        expect(
          validation.validatePassword('abc'),
          'La contraseña debe tener al menos 8 caracteres',
        );
      });

      test('should accept valid password', () {
        expect(validation.validatePassword('12345678'), isNull);
        expect(validation.validatePassword('ValidPassword123'), isNull);
      });
    });

    group('validateName', () {
      test('should return error for empty name', () {
        expect(validation.validateName(null), 'El nombre es requerido');
        expect(validation.validateName(''), 'El nombre es requerido');
      });

      test('should return error for short name', () {
        expect(validation.validateName('A'), 'El nombre es muy corto');
      });

      test('should return error for invalid characters', () {
        expect(
          validation.validateName('John123'),
          'El nombre solo debe contener letras',
        );
      });

      test('should accept valid names', () {
        expect(validation.validateName('Juan'), isNull);
        expect(validation.validateName('María'), isNull);
        expect(validation.validateName('José García'), isNull);
      });
    });

    group('validateFlashcardFront', () {
      test('should return error for empty front', () {
        expect(
          validation.validateFlashcardFront(null),
          'La pregunta es requerida',
        );
        expect(
          validation.validateFlashcardFront(''),
          'La pregunta es requerida',
        );
      });

      test('should return error for short front', () {
        expect(
          validation.validateFlashcardFront('ab'),
          'La pregunta es muy corta',
        );
      });

      test('should accept valid front', () {
        expect(
          validation.validateFlashcardFront('¿Qué es la fotosíntesis?'),
          isNull,
        );
      });
    });

    group('validateTopic', () {
      test('should return error for empty topic', () {
        expect(validation.validateTopic(null), 'El tema es requerido');
        expect(validation.validateTopic(''), 'El tema es requerido');
      });

      test('should accept valid topic', () {
        expect(validation.validateTopic('Matemáticas'), isNull);
      });
    });

    group('calculatePasswordStrength', () {
      test('should return 0 for empty password', () {
        expect(ValidationService.calculatePasswordStrength(''), 0);
      });

      test(
        'should return strength based on password length and complexity',
        () {
          expect(
            ValidationService.calculatePasswordStrength('abcd'),
            greaterThanOrEqualTo(1),
          );
          expect(
            ValidationService.calculatePasswordStrength('abcdefghijkl'),
            greaterThanOrEqualTo(2),
          );
        },
      );

      test('should calculate high strength for complex passwords', () {
        final strong = 'MyStr0ng!Pass';
        final strength = ValidationService.calculatePasswordStrength(strong);
        expect(strength, greaterThanOrEqualTo(5));
      });
    });

    group('getPasswordStrengthLabel', () {
      test('should return correct labels', () {
        expect(ValidationService.getPasswordStrengthLabel(2), 'Débil');
        expect(ValidationService.getPasswordStrengthLabel(3), 'Media');
        expect(ValidationService.getPasswordStrengthLabel(5), 'Fuerte');
        expect(ValidationService.getPasswordStrengthLabel(7), 'Muy fuerte');
      });
    });
  });
}
