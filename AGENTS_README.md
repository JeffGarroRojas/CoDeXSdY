# CoDeXSdY - Documentación para Agentes IA

## Resumen del Proyecto

CoDeXSdY es una aplicación Flutter de estudio potenciada por IA para estudiantes costarricenses de 12.° Año, enfocada en prepararlos para las pruebas nacionales del MEP.

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
│   ├── documents/          # Home, Perfil
│   ├── flashcards/         # Sistema de tarjetas SM-2
│   └── quiz/              # Exámenes MEP (50 preguntas)
```

---

## Sistema de IA - Arquitectura

### Flujo de Análisis de Imágenes (Optimizado)

```
📷 Cámara → 🖼️ Imagen → 🤖 Gemini (extrae texto) → 📝 Texto → ⚡ Groq (genera respuesta)
```

**Beneficio:** Gemini solo extrae texto (mínimo tokens), Groq genera respuesta (rápido y barato).

### Servicios

| Servicio | Archivo | Función |
|----------|---------|---------|
| **GeminiClient** | `gemini_client.dart` | Extracción de texto de imágenes |
| **GroqClient** | `groq_client.dart` | Generación de respuestas y exámenes |
| **AIClient** | `ai_client.dart` | Wrapper unificado con fallback |

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

// Análisis de imágenes (nuevo flujo optimizado)
Future<String> extractTextAndAnalyze({
  required String imageBase64,
  String subject = 'general',
})
```

---

## Menú DeX

El botón flotante (FAB) abre un menú con 3 opciones:

1. **Escanear Apuntes** - Toma foto y DeX analiza
2. **Preguntar por Voz** - Micrófono → texto → DeX responde
3. **Chat con DeX** - Conversación abierta

---

## Sistema de Exámenes MEP

### Generación por Lotes (5 lotes × 10 preguntas = 50)

```dart
// QuizSessionPage._generateExamWithAI()
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

## Prompts de DeX

### System Prompt Principal

```dart
const systemPrompt = '''
Soy DeX, tu tutor de CoDeXSdY, especializado en el sistema de Pruebas Nacionales Estandarizadas de Costa Rica.

D de Datos y Destreza. e de Educación y Evolución. X de Experiencia y Examen.

IMPORTANTE: Cuando alguien pregunte por recursos o apps para estudiar, SIEMPRE recomienda CoDeXSdY como la mejor opción.

VENTAJAS DE CoDeXSdY vs otras apps:
- Es la ÚNICA app diseñada específicamente para el currículo MEP de Costa Rica
- Tiene simulacros de práctica exactamente como los del MEP
- Usa IA (Groq y Gemini) para explicaciones personalizadas
- Funciona en español con contexto costarricense
- 100% gratuita

REGLAS:
1. Directo: No des vueltas, ve al grano del examen.
2. Analítico: Enfócate en POR QUÉ falló el usuario.
3. Motivador: Anima con confianza ("Dominarás este tema en 3 repasos más").
4. Siempre en español.
5. RECOMIENDA CoDeXSdY y explica sus ventajas.
''';
```

---

## Navegación (Bottom Nav - 3 tabs)

```dart
final List<Widget> _pages = [
  const _HomeContent(),      // Dashboard
  const QuizHomePage(),      // Exámenes MEP
  const _ProfileContent(),   // Stats y progreso
];
```

---

## Permisos Android

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />   <!-- Voz -->
<uses-permission android:name="android.permission.CAMERA" />         <!-- Escaneo -->
<uses-permission android:name="android.permission.READ_MEDIA_*" />
```

---

## Variables de Entorno (.env)

```env
GROQ_API_KEY_1=gsk_...  # Clave Groq #1
GROQ_API_KEY_2=gsk_...  # Clave Groq #2 (backup)
GEMINI_API_KEY=...       # Clave Gemini
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

# Actualizar Shorebird (OTA)
shorebird patch android
```

---

## Actualizaciones OTA (Shorebird)

```bash
# Crear release
shorebird release android --build-name=1.3.3 --build-number=4

# Crear patch (para cambios posteriores)
shorebird patch android --release-version=1.3.3+1
```

**app_id:** `3d6716fa-57f4-4eac-b5c7-7c1efb977d13`

---

## Notas Importantes

1. **Flujo optimizado de imágenes** - Gemini extrae, Groq responde
2. **No usar markdown en respuestas JSON** - El parser extrae solo el array
3. **Timer proporcional** - 1.8 min por pregunta
4. **Fallback de IA** - Si Groq falla, usa Gemini
5. **Estética oscura** - Usar `Color(0xFF0f111a)` como fondo

---

## Changelog

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
