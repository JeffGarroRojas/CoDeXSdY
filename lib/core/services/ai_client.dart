import 'package:flutter/foundation.dart';
import 'gemini_client.dart';
import 'groq_client.dart';

class AIClient {
  late final GeminiClient _geminiClient;
  late final GroqClient _groqClient;

  AIClient() {
    _geminiClient = GeminiClient();
    _groqClient = GroqClient();
  }

  Future<String> chat({
    String? model,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    // 1. Intentar Groq primero (más rápido y sin límites)
    try {
      return await _groqClient.chat(
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
        keyIndex: 0,
      );
    } on GroqException {
      // 2. Fallback a Groq #2
      try {
        return await _groqClient.chat(
          messages: messages,
          temperature: temperature,
          maxTokens: maxTokens,
          keyIndex: 1,
        );
      } on GroqException {
        // 3. Último recurso: Gemini
        try {
          return await _geminiClient.chat(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
          );
        } on GeminiException catch (e) {
          throw Exception('Error: ${e.message}');
        }
      }
    }
  }

  Future<String> generateSummary({
    String? model,
    required String content,
    int maxTokens = 1500,
  }) async {
    try {
      return await _groqClient.generateSummary(
        content: content,
        maxTokens: maxTokens,
      );
    } catch (e) {
      debugPrint('AIClient Groq generateSummary failed: $e');
      try {
        return await _groqClient.generateSummary(
          content: content,
          maxTokens: maxTokens,
        );
      } catch (e2) {
        debugPrint('AIClient Groq #2 generateSummary failed: $e2');
        try {
          return await _geminiClient.generateSummary(
            model: model,
            content: content,
            maxTokens: maxTokens,
          );
        } catch (e3) {
          debugPrint('AIClient Gemini generateSummary failed: $e3');
          throw Exception('Error de conexión: $e3');
        }
      }
    }
  }

  Future<String> generateFlashcards({
    required String topic,
    int count = 5,
  }) async {
    // Intentar Groq #1
    try {
      return await _groqClient.generateFlashcards(topic: topic, count: count);
    } catch (e) {
      debugPrint('AIClient Groq #1 failed: $e');

      // Intentar Groq #2
      try {
        return await _groqClient.generateFlashcards(topic: topic, count: count);
      } catch (e2) {
        debugPrint('AIClient Groq #2 failed: $e2');

        // Último recurso: Gemini
        try {
          return await _geminiClient.generateFlashcards(
            topic: topic,
            count: count,
          );
        } catch (e3) {
          debugPrint('AIClient Gemini failed: $e3');
          throw Exception('Error de conexión: $e3');
        }
      }
    }
  }

  Future<String> generateQuiz({
    required String content,
    int numQuestions = 5,
  }) async {
    try {
      return await _groqClient.generateQuiz(
        content: content,
        numQuestions: numQuestions,
      );
    } catch (e) {
      debugPrint('AIClient Groq generateQuiz failed: $e');
      try {
        return await _groqClient.generateQuiz(
          content: content,
          numQuestions: numQuestions,
        );
      } catch (e2) {
        debugPrint('AIClient Groq #2 generateQuiz failed: $e2');
        try {
          return await _geminiClient.generateQuiz(
            content: content,
            numQuestions: numQuestions,
          );
        } catch (e3) {
          debugPrint('AIClient Gemini generateQuiz failed: $e3');
          throw Exception('Error de conexión: $e3');
        }
      }
    }
  }

  Future<String> generateNewQuestions({
    required String subject,
    required int level,
    required int count,
    required List<String> topics,
  }) async {
    // 1. Intentar Groq #1
    try {
      return await _groqClient.generateNewQuestions(
        subject: subject,
        level: level,
        count: count,
        topics: topics,
      );
    } on GroqException {
      // 2. Fallback a Groq #2
      try {
        return await _groqClient.generateNewQuestions(
          subject: subject,
          level: level,
          count: count,
          topics: topics,
        );
      } on GroqException {
        // 3. Último recurso: Gemini
        try {
          return await _geminiClient.generateNewQuestions(
            subject: subject,
            level: level,
            count: count,
            topics: topics,
          );
        } on GeminiException catch (e) {
          throw Exception('Error: ${e.message}');
        }
      }
    }
  }

  Future<String> analyzeQuizResults({
    required List<Map<String, dynamic>> questions,
    required List<int> userAnswers,
    required String subject,
    required int level,
  }) async {
    try {
      return await _groqClient.analyzeQuizResults(
        questions: questions,
        userAnswers: userAnswers,
        subject: subject,
        level: level,
      );
    } catch (e) {
      debugPrint('AIClient Groq analyzeQuizResults failed: $e');
      try {
        return await _groqClient.analyzeQuizResults(
          questions: questions,
          userAnswers: userAnswers,
          subject: subject,
          level: level,
        );
      } catch (e2) {
        debugPrint('AIClient Groq #2 analyzeQuizResults failed: $e2');
        try {
          return await _geminiClient.analyzeQuizResults(
            questions: questions,
            userAnswers: userAnswers,
            subject: subject,
            level: level,
          );
        } catch (e3) {
          debugPrint('AIClient Gemini analyzeQuizResults failed: $e3');
          throw Exception('Error de conexión: $e3');
        }
      }
    }
  }

  Future<String> generateMEPLote({
    required String subject,
    required List<String> topics,
    required int loteNumber,
    int count = 10,
  }) async {
    try {
      return await _groqClient.generateMEPLote(
        subject: subject,
        topics: topics,
        loteNumber: loteNumber,
        count: count,
      );
    } on GroqException {
      try {
        return await _groqClient.generateMEPLote(
          subject: subject,
          topics: topics,
          loteNumber: loteNumber,
          count: count,
        );
      } on GroqException catch (e) {
        throw Exception('Error de conexión: ${e.message}');
      }
    }
  }

  Future<String> analyzeImage({
    required String imageBase64,
    required String prompt,
  }) async {
    return await _geminiClient.analyzeImage(
      imageBase64: imageBase64,
      prompt: prompt,
    );
  }

  bool containsBlockedContent(String text) {
    return _geminiClient.containsBlockedContent(text);
  }

  String getSafeResponse(String originalMessage) {
    return _geminiClient.getSafeResponse(originalMessage);
  }
}
