class ValidationService {
  static ValidationService? _instance;
  static ValidationService get instance => _instance ??= ValidationService._();
  ValidationService._();

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }

    final email = value.trim();

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Ingresa un email válido';
    }

    if (email.length > 254) {
      return 'El email es muy largo';
    }

    final atIndex = email.indexOf('@');
    final localPart = email.substring(0, atIndex);
    final domainPart = email.substring(atIndex + 1);

    if (localPart.length > 64) {
      return 'La parte local del email es muy larga';
    }

    if (domainPart.split('.').any((part) => part.isEmpty)) {
      return 'El dominio del email no es válido';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    if (value.length > 128) {
      return 'La contraseña es muy larga';
    }

    return null;
  }

  String? validatePasswordStrength(String? value) {
    final basicValidation = validatePassword(value);
    if (basicValidation != null) {
      return basicValidation;
    }

    final password = value!;

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int strength = 0;
    if (hasUppercase) strength++;
    if (hasLowercase) strength++;
    if (hasDigit) strength++;
    if (hasSpecialChar) strength++;

    if (password.length >= 12) strength++;
    if (password.length >= 16) strength++;

    if (strength < 3) {
      return 'Usa mayúsculas, minúsculas, números y símbolos';
    }

    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }

    final name = value.trim();

    if (name.length < 2) {
      return 'El nombre es muy corto';
    }

    if (name.length > 50) {
      return 'El nombre es muy largo';
    }

    if (!RegExp(r'^[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ\s]+$').hasMatch(name)) {
      return 'El nombre solo debe contener letras';
    }

    return null;
  }

  String? validateFlashcardFront(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La pregunta es requerida';
    }

    if (value.trim().length < 3) {
      return 'La pregunta es muy corta';
    }

    if (value.trim().length > 500) {
      return 'La pregunta es muy larga (máx. 500 caracteres)';
    }

    return null;
  }

  String? validateFlashcardBack(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La respuesta es requerida';
    }

    if (value.trim().length < 1) {
      return 'La respuesta es muy corta';
    }

    if (value.trim().length > 1000) {
      return 'La respuesta es muy larga (máx. 1000 caracteres)';
    }

    return null;
  }

  String? validateTopic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El tema es requerido';
    }

    if (value.trim().length < 2) {
      return 'El tema es muy corto';
    }

    if (value.trim().length > 100) {
      return 'El tema es muy largo';
    }

    return null;
  }

  String? validateDocumentTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El título es requerido';
    }

    if (value.trim().length < 2) {
      return 'El título es muy corto';
    }

    if (value.trim().length > 200) {
      return 'El título es muy largo';
    }

    return null;
  }

  static String getPasswordStrengthLabel(int strength) {
    if (strength < 3) return 'Débil';
    if (strength < 5) return 'Media';
    if (strength < 7) return 'Fuerte';
    return 'Muy fuerte';
  }

  static int calculatePasswordStrength(String password) {
    int strength = 0;

    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (password.length >= 16) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    return strength;
  }
}
