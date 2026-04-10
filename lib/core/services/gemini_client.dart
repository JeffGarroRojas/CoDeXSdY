import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'logging_service.dart';

class GeminiClient {
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String defaultModel = 'gemini-2.5-flash';

  final Dio _dio;
  final LoggingService _logger = LoggingService.instance;

  static DateTime? _lastRequestTime;
  static int _requestCount = 0;
  static DateTime _minuteStart = DateTime.now();
  static const int _maxRequestsPerMinute = 14;
  static const int _minRequestIntervalMs = 4500;

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

  GeminiClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

  Future<void> _waitForRateLimit() async {
    final now = DateTime.now();

    if (now.difference(_minuteStart).inSeconds >= 60) {
      _requestCount = 0;
      _minuteStart = now;
    }

    if (_requestCount >= _maxRequestsPerMinute) {
      final waitTime = 60 - now.difference(_minuteStart).inSeconds;
      if (waitTime > 0) {
        _logger.warning(
          'Rate limit próximo, esperando $waitTime segundos...',
          source: 'GeminiClient',
        );
        await Future.delayed(Duration(seconds: waitTime));
        _requestCount = 0;
        _minuteStart = DateTime.now();
      }
    }

    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now()
          .difference(_lastRequestTime!)
          .inMilliseconds;
      if (timeSinceLastRequest < _minRequestIntervalMs) {
        await Future.delayed(
          Duration(milliseconds: _minRequestIntervalMs - timeSinceLastRequest),
        );
      }
    }

    _lastRequestTime = DateTime.now();
    _requestCount++;
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

  String getSafeResponse(String originalMessage) {
    return 'Lo siento, pero no puedo ayudarte con eso. '
        'Estoy aquí para ayudarte con tus estudios. '
        '¿Te gustaría que te ayude a resumir un tema, '
        'crear flashcards o practicar con un quiz?';
  }

  Future<String> chat({
    String? model,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int? maxTokens,
    int retries = 2,
  }) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        return await _chatInternal(messages, temperature, maxTokens);
      } on GeminiException catch (e) {
        final shouldRetry =
            attempt < retries &&
            (e.message.contains('vacía') ||
                e.message.contains('contenido') ||
                e.statusCode == 429);
        if (shouldRetry) {
          final waitTime = 3 * (attempt + 1);
          _logger.warning(
            'Intento ${attempt + 1} falló (rate limit), esperando ${waitTime}s...',
            source: 'GeminiClient',
          );
          await Future.delayed(Duration(seconds: waitTime));
          continue;
        }
        rethrow;
      }
    }
    throw GeminiException(
      message: 'Error después de $retries intentos',
      statusCode: null,
    );
  }

  Future<String> _chatInternal(
    List<Map<String, String>> messages,
    double temperature,
    int? maxTokens,
  ) async {
    await _waitForRateLimit();

    try {
      String? systemInstruction;
      final contents = <Map<String, dynamic>>[];

      for (final m in messages) {
        if (m['role'] == 'system') {
          systemInstruction = m['content'];
        } else {
          String role = m['role'] ?? 'user';
          if (role == 'model') role = 'model';
          contents.add({
            'role': role,
            'parts': [
              {'text': m['content'] ?? ''},
            ],
          });
        }
      }

      final requestData = <String, dynamic>{
        'contents': contents,
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens ?? 2048,
          'topP': 0.95,
          'topK': 40,
        },
      };

      if (systemInstruction != null) {
        requestData['systemInstruction'] = {
          'parts': [
            {'text': systemInstruction},
          ],
        };
      }

      final response = await _dio.post(
        '/models/$defaultModel:generateContent',
        queryParameters: {'key': apiKey},
        data: requestData,
      );

      String text = '';

      try {
        final data = response.data;

        if (data == null) {
          throw GeminiException(
            message: 'Respuesta vacía del servidor',
            statusCode: null,
          );
        }

        final candidates = data['candidates'];
        if (candidates != null && candidates is List && candidates.isNotEmpty) {
          final candidate = candidates[0];

          if (candidate.containsKey('finishReason')) {
            final finishReason = candidate['finishReason'];
            if (finishReason == 'SAFETY' || finishReason == 'RECITATION') {
              throw GeminiException(
                message: 'Contenido bloqueado por seguridad',
                statusCode: null,
              );
            }
          }

          final content = candidate['content'];
          if (content != null) {
            final parts = content['parts'];
            if (parts != null && parts is List && parts.isNotEmpty) {
              for (var part in parts) {
                if (part['text'] != null &&
                    part['text'].toString().isNotEmpty) {
                  text += part['text'];
                }
              }
            }
          }
        }

        if (data['promptFeedback'] != null) {
          final feedback = data['promptFeedback'];
          if (feedback['blockReason'] != null) {
            throw GeminiException(
              message: 'Prompt bloqueado: ${feedback['blockReason']}',
              statusCode: null,
            );
          }
        }
      } catch (e) {
        if (e is GeminiException) rethrow;
        _logger.warning(
          'Error parsing Gemini response: $e',
          source: 'GeminiClient',
        );
      }

      text = text.trim();
      if (text.isEmpty) {
        _logger.warning('Gemini response is empty', source: 'GeminiClient');
        throw GeminiException(
          message: 'La IA no generó contenido',
          statusCode: null,
        );
      }

      _logger.debug('Gemini API call successful', source: 'GeminiClient');
      return text;
    } on DioException catch (e) {
      _logger.error(
        'Gemini API call failed',
        source: 'GeminiClient',
        error: e.message,
      );
      throw GeminiException(
        message: e.message ?? 'Error calling Gemini API',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      _logger.error('Gemini API call failed', source: 'GeminiClient', error: e);
      throw GeminiException(message: 'Error: $e');
    }
  }

  Future<String> generateSummary({
    String? model,
    required String content,
    int maxTokens = 1500,
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

  Future<String> generateFlashcards({
    required String topic,
    int count = 5,
  }) async {
    return chat(
      messages: [
        {'role': 'system', 'content': _systemPromptFlashcards},
        {
          'role': 'user',
          'content': 'Genera $count flashcards sobre el tema: $topic',
        },
      ],
    );
  }

  Future<String> generateQuiz({
    required String content,
    int numQuestions = 5,
  }) async {
    return chat(
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

  Future<String> generateNewQuestions({
    required String subject,
    required int level,
    required int count,
    required List<String> topics,
  }) async {
    final topicsStr = topics.join(', ');
    return chat(
      messages: [
        {'role': 'system', 'content': _systemPromptMEP},
        {
          'role': 'user',
          'content':
              '''
Genera $count preguntas de examen tipo MEP para $subject de ${level}° año.
Temas: $topicsStr

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
''',
        },
      ],
      maxTokens: 4000,
    );
  }

  Future<String> analyzeQuizResults({
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
      final correctAnswer = q['correctAnswerIndex'] ?? 0;

      final questionText = q['question']?.toString() ?? 'Pregunta sin texto';
      final optionsList = q['options'] as List<dynamic>?;
      final explanation = q['explanation']?.toString() ?? 'Sin explicación';

      final userAnswerText =
          (optionsList != null && userAnswer < optionsList.length)
          ? optionsList[userAnswer].toString()
          : 'Sin respuesta';
      final correctAnswerText =
          (optionsList != null && correctAnswer < optionsList.length)
          ? optionsList[correctAnswer].toString()
          : 'Sin respuesta';

      final isCorrect = userAnswer == correctAnswer;

      buffer.writeln('Pregunta ${i + 1}: $questionText');
      buffer.writeln('Tu respuesta: $userAnswerText');
      buffer.writeln('Respuesta correcta: $correctAnswerText');
      buffer.writeln('Resultado: ${isCorrect ? '✓ Correcta' : '✗ Incorrecta'}');
      buffer.writeln('Explicación: $explanation');
      buffer.writeln('---');
    }

    return chat(
      messages: [
        {
          'role': 'system',
          'content':
              '''Eres DeX, un amigo que ayuda a estudiar. El estudiante acaba de terminar un simulacro MEP de 12.° año en Costa Rica.

Tu trabajo es dar un análisis MUY SIMPLE Y ENTENDIBLE:

1. Comienza con algo positivo siempre (ej: "¡Buen trabajo!", "Vas por buen camino!")
2. Di cuántas acertó y cuántas falló con语气 amigable
3. Menciona los temas que necesita mejorar DE FORMA SIMPLE (ej: "Repasa un poco fracciones y porcentajes")
4. Dale 2-3 consejos prácticos y concretos
5. Anímalo a seguir estudiando

Usa lenguaje casual de un amigo, NO técnico. Máximo 150 palabras. Sé positivo siempre.''',
        },
        {'role': 'user', 'content': buffer.toString()},
      ],
    );
  }

  static const String _systemPromptSummary =
      '''Eres un asistente de estudio que crea resúmenes claros y concisos.
Siempre debes:
- Identificar los puntos más importantes
- Usar viñetas para organizar la información
- Mantener el resumen breve pero completo
- Usar español''';

  static const String _systemPromptFlashcards =
      '''Eres DeX, asistente de estudio creado por Jeff.
Genera tarjetas de estudio (flashcards) en ESPAÑOL.
FORMATO ESTRICTO:
Frente: [pregunta o concepto en español]
Dorso: [respuesta en español]
NO uses otros idiomas.
Genera entre 3 y 10 tarjetas.
Cada tarjeta en 2 líneas: una con "Frente:" y otra con "Dorso:".''';

  static const String _systemPromptQuiz =
      '''Eres DeX, asistente de estudio creado por Jeff.
Genera quizzes en ESPAÑOL con preguntas de opción múltiple.
Cada pregunta debe tener 4 opciones (A, B, C, D).
Indica claramente cuál es la respuesta correcta.
Añade una explicación breve para cada pregunta.''';

  static const String _systemPromptMEP =
      '''Eres DeX, asistente de estudio creado por Jeff para estudiantes costarricenses.
Genera preguntas de examen tipo MEP (Ministerio de Educación Pública) en ESPAÑOL.
Cada pregunta debe tener:
- 4 opciones de respuesta
- La respuesta correcta marcada
- Una explicación breve
- El tema específico al que pertenece
 IMPORTANTE: Responde ÚNICAMENTE con el JSON, sin texto adicional.''';

  Future<String> analyzeImage({
    required String imageBase64,
    required String prompt,
    String model = 'gemini-1.5-flash',
  }) async {
    await _waitForRateLimit();

    try {
      final requestData = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {'mimeType': 'image/jpeg', 'data': imageBase64},
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 2048,
          'topP': 0.95,
          'topK': 40,
        },
        'systemInstruction': {
          'parts': [
            {
              'text':
                  'Eres DeX, tutor de estudio costarricense. Analiza la imagen y proporciona una respuesta útil para el estudiante.',
            },
          ],
        },
      };

      final response = await _dio.post(
        '/models/$model:generateContent',
        queryParameters: {'key': apiKey},
        data: requestData,
      );

      final data = response.data;
      String text = '';

      if (data['candidates'] != null) {
        final candidates = data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final candidate = candidates[0];
          final content = candidate['content'];
          if (content != null) {
            final parts = content['parts'];
            if (parts != null && parts is List && parts.isNotEmpty) {
              for (var part in parts) {
                if (part['text'] != null &&
                    part['text'].toString().isNotEmpty) {
                  text += part['text'];
                }
              }
            }
          }
        }
      }

      return text.trim();
    } on DioException catch (e) {
      throw GeminiException(
        message: e.message ?? 'Error analyzing image',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<String> extractTextFromImage({
    required String imageBase64,
    String model = 'gemini-1.5-flash',
  }) async {
    await _waitForRateLimit();

    try {
      final requestData = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Extrae TODO el texto visible en esta imagen. Si hay texto, devuélvelo completo y literal. Si no hay texto claro, describe brevemente qué ves (temas, diagramas, etc).',
              },
              {
                'inlineData': {'mimeType': 'image/jpeg', 'data': imageBase64},
              },
            ],
          },
        ],
        'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 1024},
      };

      final response = await _dio.post(
        '/models/$model:generateContent',
        queryParameters: {'key': apiKey},
        data: requestData,
      );

      final data = response.data;
      String text = '';

      if (data['candidates'] != null) {
        final candidates = data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final candidate = candidates[0];
          final content = candidate['content'];
          if (content != null) {
            final parts = content['parts'];
            if (parts != null && parts is List && parts.isNotEmpty) {
              for (var part in parts) {
                if (part['text'] != null &&
                    part['text'].toString().isNotEmpty) {
                  text += part['text'];
                }
              }
            }
          }
        }
      }

      return text.trim();
    } on DioException catch (e) {
      throw GeminiException(
        message: e.message ?? 'Error extracting text from image',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

class GeminiException implements Exception {
  final String message;
  final int? statusCode;

  GeminiException({required this.message, this.statusCode});

  @override
  String toString() => 'GeminiException: $message (Status: $statusCode)';
}
