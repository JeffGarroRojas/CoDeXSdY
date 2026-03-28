# CoDeXSdY 📚

> Asistente de estudio inteligente con IA y repetición espaciada

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

## 🎯 Características

- **🤖 Asistente IA CoDy** - Chatea con IA para aprender, resumir y generar contenido
- **📝 Flashcards con SM-2** - Repetición espaciada para memorización eficiente
- **📄 Generación de contenido** - Resúmenes, quizzes y tarjetas automáticas
- **📱 Multiplataforma** - Funciona en Android, iOS y Web
- **🔒 Autenticación** - Sistema de usuarios con cuenta admin
- **💾 Local-first** - Datos guardados localmente con Hive

## 🚀 Empezar

### Prerrequisitos

- Flutter SDK 3.x
- Git
- Cuenta en [Groq API](https://console.groq.com/) (opcional para IA)

### Instalación

```bash
# Clonar el repositorio
git clone https://github.com/JeffGarro/CoDeXSdY.git
cd CoDeXSdY

# Instalar dependencias
flutter pub get

# Ejecutar
flutter run --dart-define=GROQ_API_KEY=tu_api_key
```

### Credenciales Demo

```
Email: admin@admin
Contraseña: admin
```

## 📁 Estructura del Proyecto

```
lib/
├── core/
│   ├── providers/     # Estado con Riverpod
│   ├── services/      # Hive, Groq, PDF
│   └── theme/         # Tema oscuro Material 3
├── features/
│   ├── auth/          # Login y registro
│   ├── documents/     # Documentos y perfiles
│   ├── flashcards/     # Tarjetas de estudio
│   └── ai_assistant/  # Chatbot CoDy
└── main.dart
```

## 🛠️ Tecnologías

| Categoría | Herramienta |
|----------|-------------|
| UI | Flutter, Material 3 |
| Estado | Riverpod |
| Base de datos | Hive |
| IA | Groq API (Llama) |
| Animaciones | flutter_animate |

## 📄 Licencia

MIT License - Creado por Jeff

## 👨‍💻 Autor

**Jeff** - Desarrollador

---

⭐ Si te gusta, dale una estrella al proyecto!
