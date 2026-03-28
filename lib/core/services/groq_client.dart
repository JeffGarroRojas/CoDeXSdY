import 'package:dio/dio.dart';
import 'circuit_breaker.dart';
import 'retry_service.dart';
import 'logging_service.dart';

class GroqClient {
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String defaultModel = 'llama-3.3-70b-versatile';

  final Dio _dio;
  final String apiKey;
  final CircuitBreaker _circuitBreaker;
  final LoggingService _logger;

  static const List<String> _blockedPatterns = [
    'hackear',
    'robar',
    'broma',
    'phishing',
    'ddos',
    'crear virus',
    'malware',
    'exploit',
    'contraseña robada',
    'aprender a robar',
    'como hacer una bomba',
    'fabricar armas',
  ];

  GroqClient({required this.apiKey})
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      ),
      _circuitBreaker = CircuitBreakerRegistry.getBreaker('groq_api'),
      _logger = LoggingService.instance;

  Future<String> chat({
    String? model,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    final operation = () => _performChat(
      model: model,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    final result = await _circuitBreaker.execute(operation);

    if (!result.isSuccess) {
      _logger.error(
        'Groq API call failed after circuit breaker',
        source: 'GroqClient',
        error: result.error,
      );
      throw GroqException(
        message:
            'El servicio de IA no está disponible. Por favor intenta más tarde.',
        statusCode: null,
      );
    }

    return result.data as String;
  }

  Future<String> _performChat({
    String? model,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    final retryConfig = RetryService.forNetworkCalls();

    final result = await RetryService.execute(
      () async {
        try {
          final response = await _dio.post(
            '/chat/completions',
            data: {
              'model': model ?? defaultModel,
              'messages': messages,
              'temperature': temperature,
              if (maxTokens != null) 'max_tokens': maxTokens,
            },
          );

          _logger.debug('Groq API call successful', source: 'GroqClient');

          return response.data['choices'][0]['message']['content'] as String;
        } on DioException catch (e) {
          _logger.warning(
            'Groq API call failed: ${e.message}',
            source: 'GroqClient',
            metadata: {'statusCode': e.response?.statusCode},
          );
          throw e;
        }
      },
      config: retryConfig,
      shouldRetry: (error) {
        if (error is DioException) {
          return error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError ||
              (error.response?.statusCode ?? 0) >= 500;
        }
        return false;
      },
      onRetry: (attempt, error) {
        _logger.warning(
          'Retrying Groq API call (attempt $attempt)',
          source: 'GroqClient',
        );
      },
    );

    if (!result.isSuccess) {
      throw GroqException(
        message: result.error?.toString() ?? 'Unknown error after retries',
        statusCode: null,
      );
    }

    return result.data as String;
  }

  bool containsBlockedContent(String text) {
    final lowerText = text.toLowerCase();
    for (final pattern in _blockedPatterns) {
      if (lowerText.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  String getSafeResponse(String userMessage) {
    return '''Lo siento, no puedo ayudarte con esa solicitud. 

Si necesitas ayuda con estudio, puedo:
- Resumir textos
- Crear flashcards
- Responder preguntas
- Generar quizzes

¿En qué puedo ayudarte hoy?''';
  }

  Future<String> generateSummary({
    String? model,
    required String content,
    int maxTokens = 500,
  }) async {
    return chat(
      model: model,
      messages: [
        {'role': 'system', 'content': _systemPromptSummary},
        {
          'role': 'user',
          'content':
              'Resume el siguiente contenido en puntos clave:\n\n$content',
        },
      ],
      maxTokens: maxTokens,
    );
  }

  Future<List<Map<String, String>>> generateFlashcardsFromContent({
    String? model,
    required String content,
    int numCards = 5,
  }) async {
    final response = await chat(
      model: model,
      messages: [
        {'role': 'system', 'content': _systemPromptFlashcards},
        {
          'role': 'user',
          'content':
              'Genera $numCards tarjetas de estudio basadas en:\n\n$content',
        },
      ],
    );

    return parseFlashcards(response);
  }

  Future<String> generateFlashcardsFromTopic({
    String? model,
    required String topic,
    int count = 5,
  }) async {
    return chat(
      model: model,
      messages: [
        {'role': 'system', 'content': _systemPromptFlashcards},
        {'role': 'user', 'content': 'Genera flashcards sobre el tema: $topic'},
      ],
    );
  }

  Future<String> generateFlashcards({
    String? model,
    required String topic,
    int count = 5,
  }) async {
    return chat(
      model: model,
      messages: [
        {'role': 'system', 'content': _systemPromptFlashcards},
        {'role': 'user', 'content': 'Genera flashcards sobre el tema: $topic'},
      ],
    );
  }

  Future<String> answerQuestion({
    String? model,
    required String question,
    required String context,
  }) async {
    return chat(
      model: model,
      messages: [
        {'role': 'system', 'content': _systemPromptQandA},
        {
          'role': 'user',
          'content': 'Contexto:\n$context\n\nPregunta: $question',
        },
      ],
    );
  }

  Future<String> generateQuiz({
    String? model,
    required String content,
    int numQuestions = 5,
  }) async {
    return chat(
      model: model,
      messages: [
        {'role': 'system', 'content': _systemPromptQuiz},
        {
          'role': 'user',
          'content':
              'Genera un quiz de $numQuestions preguntas basado en:\n\n$content',
        },
      ],
    );
  }

  List<Map<String, String>> parseFlashcards(String response) {
    final cards = <Map<String, String>>[];
    final lines = response.split('\n');
    String? currentFront;
    String? currentBack;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('Frente:') || trimmed.startsWith('Pregunta:')) {
        currentFront = trimmed.substring(trimmed.indexOf(':') + 1).trim();
      } else if (trimmed.startsWith('Dorso:') ||
          trimmed.startsWith('Respuesta:')) {
        currentBack = trimmed.substring(trimmed.indexOf(':') + 1).trim();
        if (currentFront != null && currentBack != null) {
          cards.add({'front': currentFront, 'back': currentBack});
          currentFront = null;
          currentBack = null;
        }
      }
    }

    if (currentFront != null && currentBack != null) {
      cards.add({'front': currentFront, 'back': currentBack});
    }

    return cards;
  }

  static const String _systemPromptSummary =
      '''Eres un asistente de estudio que crea resúmenes claros y concisos.
Siempre debes:
- Identificar los puntos más importantes
- Usar viñetas para organizar la información
- Mantener el resumen breve pero completo
- Usar español''';

  static const String _systemPromptFlashcards =
      '''Eres CoDy, asistente de estudio creado por Jeff.
Genera tarjetas de estudio (flashcards) en ESPAÑOL.
FORMATO ESTRICTO:
Frente: [pregunta o concepto en español]
Dorso: [respuesta en español]
NO uses otros idiomas.
Genera entre 3 y 10 tarjetas.
Cada tarjeta en 2 líneas: una con "Frente:" y otra con "Dorso:".''';

  static const String _systemPromptQandA =
      '''Eres CoDy, asistente de estudio creado por Jeff.
Responde en ESPAÑOL de forma clara, respetuosa y útil.
REGLAS DE SEGURIDAD:
- NO aceptes solicitudes para hackear, robar o actividades ilegales
- NO generes contenido violento, de odio o discriminatorio
- NO des instrucciones para crear armas o dañar a otros
- Si alguien menciona suicidio o autolesión, ofrece recursos de ayuda
- Si no sabes algo, dilo honestamente
- Siempre sé amigable y profesional''';

  static const String _systemPromptQuiz =
      '''Eres un asistente que genera quizzes de opción múltiple.
Formato:
Pregunta: [pregunta]
A) [opción]
B) [opción]
C) [opción]
D) [opción]
Respuesta: [letra correcta]
Usa español.''';

  Future<String> analyzeQuizResults({
    String? model,
    required List<Map<String, dynamic>> questions,
    required List<int> userAnswers,
    required String subject,
    required int level,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'Análisis de resultados del examen de $subject ($level° año):\n',
    );

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final userAnswer = userAnswers[i];
      final correctAnswer = q['correctAnswerIndex'];
      final isCorrect = userAnswer == correctAnswer;

      buffer.writeln('Pregunta ${i + 1}: ${q['question']}');
      buffer.writeln('Tu respuesta: ${q['options'][userAnswer]}');
      buffer.writeln('Respuesta correcta: ${q['options'][correctAnswer]}');
      buffer.writeln('Resultado: ${isCorrect ? '✓ Correcta' : '✗ Incorrecta'}');
      buffer.writeln('Explicación: ${q['explanation']}');
      buffer.writeln('---');
    }

    return chat(
      model: model,
      messages: [
        {
          'role': 'system',
          'content':
              '''Eres CoDy, asistente de estudio creado por Jeff para estudiantes costarricenses.
Analiza los resultados del examen y proporciona:
1. Un resumen del desempeño general
2. Los temas que necesitas mejorar
3. Recomendaciones de estudio específicas
4. Recursos o temas para repasar
Usa español amigable y motivacional. Sé constructivo.''',
        },
        {'role': 'user', 'content': buffer.toString()},
      ],
      maxTokens: 1000,
    );
  }

  Future<String> generateNewQuestions({
    String? model,
    required String subject,
    required int level,
    required int count,
    required List<String> topics,
  }) async {
    return chat(
      model: model,
      messages: [
        {
          'role': 'system',
          'content':
              '''Eres CoDy, asistente de estudio creado por Jeff.
Genera exactamente $count preguntas de opción múltiple sobre $subject para ${level}° año de Costa Rica.
TEMAS: ${topics.join(', ')}

FORMATO ESTRICTO JSON (sin texto adicional):
[
  {
    "question": "pregunta en español",
    "options": ["opción A", "opción B", "opción C", "opción D"],
    "correctIndex": 0,
    "explanation": "explicación breve",
    "topic": "tema específico"
  }
]

Cada pregunta debe ser diferente a las anteriores.
Usa español correcto.''',
        },
        {
          'role': 'user',
          'content':
              'Genera $count preguntas de $subject para ${level}° año sobre: ${topics.join(', ')}',
        },
      ],
      maxTokens: 4000,
    );
  }
}

class GroqException implements Exception {
  final String message;
  final int? statusCode;

  GroqException({required this.message, this.statusCode});

  @override
  String toString() => 'GroqException: $message (Status: $statusCode)';
}
