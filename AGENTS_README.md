# CoDeXSdY - Documentación para Agentes IA

## Resumen del Proyecto

CoDeXSdY es una aplicación Flutter de estudio potenciada por IA para estudiantes costarricenses de 12.° Año, enfocada en prepararlos para las pruebas nacionales del MEP.

**Modo: 100% Local** - Sin Firebase, sin nube.

---

## Estructura del Proyecto

```
lib/
├── core/
│   ├── providers/          # Riverpod providers
│   ├── services/           # Servicios (AI, DB, PDF, etc.)
│   ├── theme/             # AppTheme con colores oscuros
│   └── utils/             # Utilidades
├── features/
│   ├── ai_assistant/       # Chatbot DeX
│   ├── auth/              # Login local con PIN
│   ├── documents/         # Home, Perfil
│   ├── flashcards/        # Sistema de tarjetas SM-2
│   └── quiz/              # Exámenes MEP (50 preguntas)
```

---

## Sistema de IA - Arquitectura

### Fallback en Cascada
```
Groq #1 → Groq #2 → Gemini
```

**Orden de prioridad:**
1. **Groq #1** - Principal para generación de preguntas
2. **Groq #2** - Fallback cuando #1 falla (rate limit)
3. **Gemini** - Último recurso cuando Groq falla completamente

### Flujo de Análisis de Imágenes (Optimizado)

```
📷 Cámara → 🖼️ Imagen → 🤖 Gemini (extrae texto) → 📝 Texto → ⚡ Groq (genera respuesta)
```

### Servicios

| Servicio | Archivo | Función |
|----------|---------|---------|
| **GeminiClient** | `gemini_client.dart` | Extracción de texto de imágenes |
| **GroqClient** | `groq_client.dart` | Generación de respuestas y exámenes |
| **AIClient** | `ai_client.dart` | Wrapper unificado con fallback automático |

### AIClient (`lib/core/services/ai_client.dart`)

```dart
// Métodos disponibles
Future<String> chat()
Future<String> generateSummary()
Future<String> generateFlashcards()
Future<String> generateQuiz()
Future<String> generateNewQuestions()
Future<String> analyzeQuizResults()
Future<String> generateMEPLote()

// Análisis de imágenes
Future<String> extractTextAndAnalyze({
  required String imageBase64,
  String subject = 'general',
})
```

---

## Autenticación Local

- **PIN de 4 dígitos** - Simple y local
- **Modo Invitado** - Acceso sin registro, datos se borran en 5 días
- **Sin cuenta en la nube** - Todos los datos en el dispositivo

---

## Sistema de Exámenes MEP

### Generación por Lotes (5 lotes × 10 preguntas = 50)

```dart
const totalLotes = 5;
const preguntasPorLote = 10;

for (int lote = 1; lote <= totalLotes; lote++) {
  final response = await aiClient.generateMEPLote(
    subject: widget.subjectName,
    topics: widget.topics,
    loteNumber: lote,
  );
  final loteQuestions = _parseJSONQuestions(response);
  allQuestions.addAll(loteQuestions);
}
```

### Timer Proporcional

```dart
final timePerQuestion = 1.8; // minutos
_remainingSeconds = (widget.questionCount * timePerQuestion * 60).round();
// 50 preguntas = 90 minutos
```

---

## Variables de Entorno (.env)

```env
GROQ_API_KEY_1=gsk_...  # Clave Groq #1
GROQ_API_KEY_2=gsk_...  # Clave Groq #2 (backup)
GEMINI_API_KEY=...      # Clave Gemini
```

**Importante:** El archivo `.env` está en `.gitignore`. Nunca hacer commit con las keys reales.

---

## Comandos Útiles

```bash
# Build release
flutter build apk --release

# Analizar código
flutter analyze

# Instalar en dispositivo
flutter install
```

---

## Notas Importantes

1. **Flujo optimizado de imágenes** - Gemini extrae, Groq responde
2. **No usar markdown en respuestas JSON** - El parser extrae solo el array
3. **Timer proporcional** - 1.8 min por pregunta
4. **Fallback de IA** - Groq #1 → Groq #2 → Gemini
5. **Estética oscura** - Usar `Color(0xFF0f111a)` como fondo
6. **100% Local** - Sin Firebase, sin nube

---

## Changelog

### v1.4.0 (Local Mode)
- **Eliminado Firebase** - 100% datos locales
- **Eliminado Shorebird** - Sin OTA updates
- **Autenticación local** con PIN de 4 dígitos
- **Modo Invitado** - Sin registro

### v1.3.4
- Flujo optimizado de análisis de imágenes
- Gemini solo extrae texto, Groq genera respuesta
- API keys movidas a .env
- Prompts de DeX actualizados

### v1.3.3
- Rediseño completo del Home como "War Room"
- DeX FAB con gradiente y animaciones
- Generación de exámenes MEP en 5 lotes de 10
- Parser JSON estricto para respuestas de IA
- Timer proporcional (1.8 min/pregunta)
