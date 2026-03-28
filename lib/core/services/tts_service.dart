import 'package:flutter_tts/flutter_tts.dart';

class VoiceOption {
  final String id;
  final String name;
  final String description;
  final double rate;
  final double pitch;
  final double volume;
  final String? language;
  final String? engine;

  const VoiceOption({
    required this.id,
    required this.name,
    required this.description,
    required this.rate,
    required this.pitch,
    required this.volume,
    this.language,
    this.engine,
  });
}

class TTSService {
  static TTSService? _instance;
  static TTSService get instance => _instance ??= TTSService._();
  TTSService._();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isPlaying = false;
  String _currentText = '';
  VoiceOption _currentVoice = const VoiceOption(
    id: 'default',
    name: 'Por Defecto',
    description: 'Voz estándar del sistema',
    rate: 0.5,
    pitch: 1.0,
    volume: 0.9,
    language: 'es-ES',
  );

  static const List<VoiceOption> availableVoices = [
    VoiceOption(
      id: 'default',
      name: 'Por Defecto',
      description: 'Voz estándar del sistema',
      rate: 0.5,
      pitch: 1.0,
      volume: 0.9,
      language: 'es-ES',
    ),
    VoiceOption(
      id: 'friendly',
      name: 'Amigable',
      description: 'Voz más cálida y amigable',
      rate: 0.55,
      pitch: 1.15,
      volume: 0.95,
      language: 'es-ES',
    ),
    VoiceOption(
      id: 'calm',
      name: 'Tranquila',
      description: 'Voz más pausada y calmada',
      rate: 0.45,
      pitch: 0.95,
      volume: 0.85,
      language: 'es-ES',
    ),
    VoiceOption(
      id: 'professional',
      name: 'Profesional',
      description: 'Voz clara y profesional',
      rate: 0.5,
      pitch: 1.0,
      volume: 1.0,
      language: 'es-ES',
    ),
  ];

  bool get isPlaying => _isPlaying;
  String get currentText => _currentText;
  VoiceOption get currentVoice => _currentVoice;
  List<VoiceOption> get voices => availableVoices;

  Future<void> init() async {
    if (_isInitialized) return;

    await _flutterTts.setSharedInstance(true);

    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setSpeechRate(_currentVoice.rate);
    await _flutterTts.setVolume(_currentVoice.volume);
    await _flutterTts.setPitch(_currentVoice.pitch);

    await _flutterTts
        .setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ], IosTextToSpeechAudioMode.voicePrompt);

    _flutterTts.setStartHandler(() {
      _isPlaying = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      _currentText = '';
    });

    _flutterTts.setCancelHandler(() {
      _isPlaying = false;
      _currentText = '';
    });

    _flutterTts.setErrorHandler((msg) {
      _isPlaying = false;
      _currentText = '';
    });

    _isInitialized = true;
  }

  Future<void> setVoice(VoiceOption voice) async {
    _currentVoice = voice;
    await _flutterTts.setSpeechRate(voice.rate);
    await _flutterTts.setVolume(voice.volume);
    await _flutterTts.setPitch(voice.pitch);
    if (voice.language != null) {
      await _flutterTts.setLanguage(voice.language!);
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await init();

    if (_isPlaying) {
      await stop();
    }

    _currentText = text;
    _isPlaying = true;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    _isPlaying = false;
    _currentText = '';
    await _flutterTts.stop();
  }

  Future<void> speakFront(String text) async {
    final frontText = 'Pregunta: $text';
    await speak(frontText);
  }

  Future<void> speakBack(String text) async {
    final backText = 'Respuesta: $text';
    await speak(backText);
  }

  void dispose() {
    _flutterTts.stop();
  }
}
