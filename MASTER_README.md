# CoDeXSdY - Resumen de Implementación

Este documento sirve como registro para el usuario y guía de contexto para otros agentes de IA.

---

## Estado Actual (Marzo 2026)

### Base de Datos Local
- **Motor**: Hive (NO Isar)
- **Servicio**: `lib/core/services/database_service.dart`
- **Modelos**: Document, Flashcard, QuizResult, UserProfile, ChatSession

### IA
- **Groq**: Generación de preguntas MEP (lotes de 10 × 5 = 50 preguntas)
- **Gemini**: Fallback cuando Groq no está disponible
- **Cliente Principal**: `ai_client.dart` (wrapper unificado)

### Funcionalidades Implementadas
- Simulacros MEP con 50 preguntas por materia
- Diagnóstico post-examen con análisis de DeX
- Sistema de flashcards con algoritmo SM-2
- Exportación a PDF
- Chat con IA (DeX)
- Escaneo de imágenes y reconocimiento de voz

---

## Limpieza Reciente (Marzo 2026)
- Eliminados 10 servicios no utilizados
- Unificado flujo de selección de materias
- Eliminado código muerto y datos hardcodeados

---

## Servicos Activos (10)
1. `database_service.dart` - Persistencia Hive
2. `ai_client.dart` - Wrapper de IA
3. `groq_client.dart` - API Groq
4. `gemini_client.dart` - API Gemini
5. `sm2_algorithm.dart` - Repetición espaciada
6. `pdf_export_service.dart` - Exportar PDF
7. `notification_service.dart` - Notificaciones
8. `logging_service.dart` - Logs
9. `pdf_service.dart` - Manejo de PDFs
10. `update_service.dart` - Actualizaciones

---

## Dependencias Principales
- flutter_riverpod (estado)
- hive_flutter (persistencia)
- google_generative_ai (Gemini)
- firebase (auth, remote config)
- syncfusion_flutter_pdf (PDF)
- speech_to_text (voz)
- image_picker (cámara)
