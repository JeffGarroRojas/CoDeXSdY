# CoDeXSdY - Documentación para Agentes IA

## Resumen del Proyecto

CoDeXSdY es una aplicación Flutter de estudio potenciada por IA para estudiantes costarricenses de 12.° Año, enfocada en prepararlos para las pruebas nacionales del MEP.

---

## Estructura del Proyecto

```
lib/
├── core/
│   ├── providers/          # Riverpod providers
│   ├── services/          # Servicios (AI, DB, PDF, etc.)
│   ├── theme/             # AppTheme con colores oscuros
│   └── utils/             # Utilidades
├── features/
│   ├── ai_assistant/       # Chatbot CoDy
│   ├── documents/          # Home, Perfil, Biblioteca
│   ├── flashcards/         # Sistema de tarjetas SM-2
│   └── quiz/               # Exámenes MEP (50 preguntas)
```

---

## Servicios de IA

### GroqClient (`lib/core/services/groq_client.dart`)

**Prompt MEP JSON para 12.° Año:**

```dart
static const String PROMPT_MEP_JSON = '''ROL DEL SISTEMA
Actúa como un generador de ítems de evaluación educativa...
FORMATO: Array JSON puro, sin markdown
ESQUEMA: [{"question": "...", "options": [...], "correctIndex": 0, ...}]
''';
```

**Método clave:**
```dart
Future<String> generateMEPLote({
  required String subject,
  required List<String> topics,
  required int loteNumber,
  int count = 10,
})
```

### AIClient (`lib/core/services/ai_client.dart`)

- Wrapper con fallback: Groq #1 → Groq #2 → Gemini
- Métodos: `chat()`, `generateFlashcards()`, `generateSummary()`, `generateMEPLote()`

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

### Parser JSON Estricto

```dart
List<Question> _parseJSONQuestions(String response) {
  final jsonStart = response.indexOf('[');
  final jsonEnd = response.lastIndexOf(']') + 1;
  final jsonStr = response.substring(jsonStart, jsonEnd);
  final data = json.decode(jsonStr) as List;
  // ... mapear a Question
}
```

---

## Navegación (Bottom Nav)

```dart
final List<Widget> _pages = [
  const _HomeContent(),      // Dashboard limpio
  const QuizHomePage(),      // Exámenes MEP
  const _LibraryContent(),   // Biblioteca PDFs
  const _ProfileContent(),   // Stats y progreso
];
```

### CoDy FAB

- Gradiente azul/violeta
- Animación pulsante
- Modal con 4 opciones:
  - Escaneo Rápido
  - Duda por Voz
  - Resumir PDF
  - Chat IA

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

## Variables de Entorno

```env
GROQ_API_KEY=gsk_...  # En groq_client.dart (hardcoded)
```

---

## Comandos Útiles

```bash
# Build release
flutter build apk --release

# Analizar código
flutter analyze

# Actualizar Shorebird
shorebird patch android
```

---

## Notas Importantes

1. **No usar markdown en respuestas JSON** - El parser extrae solo el array
2. **Timer proporcional** - 1.8 min por pregunta
3. **Fallback de IA** - Si Groq falla, usa Gemini
4. **Estética oscura** - Usar `Color(0xFF0f111a)` como fondo

---

## Changelog Reciente

### v1.3.3
- Rediseño completo del Home como "War Room"
- Nueva navegación: Inicio, Exámenes, Temas, Perfil
- CoDy FAB con gradiente y animaciones
- Generación de exámenes MEP en 5 lotes de 10
- Parser JSON estricto para respuestas de IA
- Timer proporcional (1.8 min/pregunta)
