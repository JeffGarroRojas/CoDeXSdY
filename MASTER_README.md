# CoDeXSdY - Resumen de Implementación

Este documento sirve como registro para el usuario y guía de contexto para otros agentes de IA.

---

## Estado Actual (Abril 2026)

### Modo: 100% Local
- **Sin Firebase** - Todos los datos se guardan localmente con Hive
- **Sin OTA Updates** - Actualizaciones manuales
- **Autenticación local** con PIN de 4 dígitos

### Base de Datos Local
- **Motor**: Hive
- **Servicio**: `lib/core/services/database_service.dart`
- **Modelos**: Document, Flashcard, QuizResult, UserProfile, ChatSession

### IA
- **Groq #1**: Generación de preguntas MEP (lotes de 10 × 5 = 50 preguntas)
- **Groq #2**: Fallback cuando Groq #1 falla
- **Gemini**: Último fallback cuando Groq no está disponible
- **Cliente Principal**: `ai_client.dart` (wrapper unificado con fallback automático)

### Funcionalidades Implementadas
- Simulacros MEP con 50 preguntas por materia
- Diagnóstico post-examen con análisis de DeX
- Sistema de flashcards con algoritmo SM-2
- Exportación a PDF
- Chat con IA (DeX)
- Escaneo de imágenes y reconocimiento de voz
- Modo invitado (datos se borran después de 5 días)

---

## Servicios Activos (9)

1. `database_service.dart` - Persistencia Hive
2. `ai_client.dart` - Wrapper de IA con fallback
3. `groq_client.dart` - API Groq (#1 y #2)
4. `gemini_client.dart` - API Gemini
5. `sm2_algorithm.dart` - Repetición espaciada
6. `pdf_export_service.dart` - Exportar PDF
7. `notification_service.dart` - Notificaciones locales
8. `logging_service.dart` - Logs
9. `pdf_service.dart` - Manejo de PDFs

---

## Dependencias Principales

- flutter_riverpod (estado)
- hive_flutter (persistencia local)
- dio (HTTP requests)
- google_generative_ai (Gemini)
- syncfusion_flutter_pdf (PDF)
- speech_to_text (voz)
- image_picker (cámara)

---

## Autenticación Local

- **PIN de 4 dígitos**: Simple y local
- **Modo Invitado**: Acceso sin registro, datos se borran en 5 días
- **Sin cuenta en la nube**: Todos los datos en el dispositivo

---

## Configuración de APIs

Crear archivo `.env` con las siguientes variables:

```env
# Groq API Keys (Obtén en https://console.groq.com)
GROQ_API_KEY_1=tu_groq_api_key_1
GROQ_API_KEY_2=tu_groq_api_key_2

# Gemini API Key (Obtén en https://aistudio.google.com)
GEMINI_API_KEY=tu_gemini_api_key
```

---

## Versión Actual: 1.4.0 (Local Mode)
