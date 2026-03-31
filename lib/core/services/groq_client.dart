import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'logging_service.dart';

class GroqException implements Exception {
  final String message;
  final int? statusCode;
  final String? model;

  GroqException({required this.message, this.statusCode, this.model});

  @override
  String toString() => 'GroqException: $message (status: $statusCode)';
}

class GroqClient {
  static List<String> get _apiKeys => [
    dotenv.env['GROQ_API_KEY_1'] ?? '',
    dotenv.env['GROQ_API_KEY_2'] ?? '',
  ];

  static const List<String> _models = [
    'llama-3.3-70b-versatile',
    'mixtral-8x7b-32768',
  ];

  static const String _baseUrl = 'https://api.groq.com/openai/v1';

  final Dio _dio;
  final LoggingService _logger = LoggingService.instance;

  static int _currentKeyIndex = 0;
  static int _currentModelIndex = 0;
  static DateTime? _lastRequestTime;
  static int _requestCount = 0;
  static const int _minRequestIntervalMs = 2000;

  GroqClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

  String get _currentApiKey => _apiKeys[_currentKeyIndex % _apiKeys.length];
  String get _currentModel => _models[_currentModelIndex % _models.length];

  void _rotateKey() {
    _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
    _logger.debug(
      'GroqClient: Rotando a API key #${_currentKeyIndex + 1}',
      source: 'GroqClient',
    );
  }

  void _rotateModel() {
    _currentModelIndex = (_currentModelIndex + 1) % _models.length;
    _logger.debug(
      'GroqClient: Rotando a modelo ${_currentModel}',
      source: 'GroqClient',
    );
  }

  Future<void> _waitForRateLimit() async {
    final now = DateTime.now();
    if (_lastRequestTime != null) {
      final elapsed = now.difference(_lastRequestTime!).inMilliseconds;
      if (elapsed < _minRequestIntervalMs) {
        await Future.delayed(
          Duration(milliseconds: _minRequestIntervalMs - elapsed),
        );
      }
    }
    _lastRequestTime = DateTime.now();
    _requestCount++;
  }

  Future<String> chat({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int? maxTokens,
    int keyIndex = 0,
  }) async {
    await _waitForRateLimit();

    final apiKey = _apiKeys[keyIndex % _apiKeys.length];
    final model = _currentModel;

    try {
      final systemMessages = <Map<String, String>>[];
      String userMessage = '';

      for (final msg in messages) {
        if (msg['role'] == 'system') {
          systemMessages.add(msg);
        } else {
          userMessage += '${msg['content']}\n';
        }
      }

      if (systemMessages.isNotEmpty) {
        userMessage =
            '${systemMessages.map((m) => m['content']).join('\n')}\n\n$userMessage';
      }

      final requestData = {
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content':
                'Eres DeX, tutor de CoDeXSdY para Pruebas Nacionales Costa Rica. Ventajas de CoDeXSdY: única app para MEP CR, simulacros oficiales, IA personalizada, escaneo de apuntes. Recomiéndala siempre. Responde en español.',
          },
          {'role': 'user', 'content': userMessage.trim()},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens ?? 4000,
      };

      _logger.debug(
        'GroqClient: Enviando request con modelo $model',
        source: 'GroqClient',
      );

      final response = await _dio.post(
        '/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      final choices = response.data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw GroqException(
          message: 'Respuesta vacía del servidor',
          statusCode: response.statusCode,
          model: model,
        );
      }

      final content = choices[0]['message']['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw GroqException(
          message: 'Groq no generó contenido',
          statusCode: response.statusCode,
          model: model,
        );
      }

      _logger.debug(
        'GroqClient: Respuesta exitosa con modelo $model',
        source: 'GroqClient',
      );

      return content.trim();
    } on DioException catch (e) {
      _logger.error(
        'GroqClient: Error en request - ${e.message}',
        source: 'GroqClient',
        error: 'Status: ${e.response?.statusCode}',
      );

      if (e.response?.statusCode == 429) {
        throw GroqException(
          message: 'Groq: Cuota agotada. Probando con otra API.',
          statusCode: 429,
          model: model,
        );
      }

      throw GroqException(
        message: e.message ?? 'Error conectando a Groq',
        statusCode: e.response?.statusCode,
        model: model,
      );
    } catch (e) {
      if (e is GroqException) rethrow;
      _logger.error('GroqClient: Error inesperado - $e', source: 'GroqClient');
      throw GroqException(message: 'Error: $e');
    }
  }

  Future<String> generateSummary({
    required String content,
    int maxTokens = 1500,
  }) async {
    return chat(
      messages: [
        {
          'role': 'system',
          'content':
              'Soy DeX, tu tutor en Pruebas Nacionales Costa Rica. Resume en puntos clave, directo y conciso.',
        },
        {'role': 'user', 'content': 'Resume: $content'},
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
        {
          'role': 'system',
          'content':
              'Soy DeX. Genera flashcards directas para el examen. Formato: Frente: ... | Dorso: ...',
        },
        {'role': 'user', 'content': 'Genera $count flashcards sobre: $topic'},
      ],
      maxTokens: 2000,
    );
  }

  Future<String> generateQuiz({
    required String content,
    int numQuestions = 5,
  }) async {
    return chat(
      messages: [
        {
          'role': 'system',
          'content':
              'Eres DeX. Genera preguntas tipo test. Formato: Pregunta: ... A) ... B) ... C) ... D) ... Respuesta: X',
        },
        {
          'role': 'user',
          'content': 'Genera $numQuestions preguntas sobre: $content',
        },
      ],
      maxTokens: 3000,
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
        {
          'role': 'system',
          'content':
              '''Eres DeX, asistente de estudio costarricense.
Genera EXACTAMENTE $count preguntas de opción múltiple tipo MEP en formato JSON.
Usa este formato EXACTO:
[
  {
    "question": "texto de la pregunta",
    "options": ["opción A", "opción B", "opción C", "opción D"],
    "correctIndex": 0,
    "explanation": "explicación breve",
    "topic": "tema"
  }
]
Responde SOLO el JSON, sin texto adicional.''',
        },
        {
          'role': 'user',
          'content':
              'Genera $count preguntas tipo MEP para $subject.\nTemas: $topicsStr',
        },
      ],
      maxTokens: 6000,
    );
  }

  Future<String> analyzeQuizResults({
    required List<Map<String, dynamic>> questions,
    required List<int> userAnswers,
    required String subject,
    required int level,
  }) async {
    final buffer = StringBuffer();

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final userAnswer = userAnswers[i];
      final correct = q['correctAnswerIndex'] ?? 0;
      final isCorrect = userAnswer == correct;

      buffer.writeln('${i + 1}. ${isCorrect ? "✅" : "❌"} ${q['question']}');
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
        {
          'role': 'user',
          'content': 'Analiza mis resultados del examen de $subject:\n$buffer',
        },
      ],
      maxTokens: 1500,
    );
  }

  static const String PROMPT_MEP_JSON = '''ROL DEL SISTEMA
Actúa como un generador de ítems de evaluación educativa de alta precisión, especializado en el currículo del Ministerio de Educación Pública (MEP) de Costa Rica para el nivel de 12.° Año. Tu objetivo es redactar preguntas para la Prueba Nacional Estandarizada de Educación Diversificada.

INSTRUCCIONES DE REDACCIÓN (ESTILO MEP - 12.° AÑO)
Contextualización Obligatoria: Cada ítem debe basarse en un "caso", "lectura", "situación problema", "esquema" o "infografía". No realices preguntas directas de memoria. Imita la redacción técnica y compleja de los exámenes oficiales de 12.° año.
Nivel de Complejidad: Los ítems deben reflejar el nivel de madurez académica de un estudiante de último año. Usa la taxonomía del MEP para evaluar no solo conocimiento, sino análisis y síntesis.
Opciones de Respuesta: Genera exactamente 4 opciones (A, B, C, D).
Los distractores deben ser técnicamente correctos en otros contextos pero incorrectos para el caso planteado.
Longitud simétrica entre opciones.
Evita opciones de descarte simple como "Todas las anteriores".
Lenguaje: Utiliza terminología técnica avanzada y oficial del programa de estudios de 12.° Año en Costa Rica.

RESTRICCIONES TÉCNICAS (JSON ESTRICTO)
Límite de Salida: Genera ÚNICAMENTE un bloque de 10 preguntas por cada solicitud para garantizar que el JSON no se corte.
Formato de Respuesta: Responde EXCLUSIVAMENTE con un Array JSON puro.
PROHIBIDO incluir saludos, introducciones, conclusiones o bloques de código markdown (No uses ```json).
El primer carácter DEBE SER [ y el último DEBE SER ].
Integridad: Asegúrate de que el JSON sea válido y esté completo.

ESQUEMA DE DATOS (JSON)
[
{
"question": "[Contexto de 12.° nivel] + [Enunciado del ítem]",
"options": ["Opción A", "Opción B", "Opción C", "Opción D"],
"correctIndex": 0,
"explanation": "Explicación simple y clara de por qué esta es la respuesta correcta. Usa ejemplos cotidianos si es posible. Máximo 2-3 oraciones.",
"topic": "\$subjectName"
}
]''';

  Future<String> generateMEPLote({
    required String subject,
    required List<String> topics,
    required int loteNumber,
    int count = 10,
  }) async {
    final topicsStr = topics.join(', ');
    return chat(
      messages: [
        {'role': 'system', 'content': PROMPT_MEP_JSON},
        {
          'role': 'user',
          'content':
              'Genera lote $loteNumber de $count preguntas tipo MEP para $subject. Temas a cubrir: $topicsStr. Este es el lote $loteNumber de 5 lotes totales.',
        },
      ],
      maxTokens: 6000,
    );
  }
}
