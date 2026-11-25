import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _flutterTts = FlutterTts();

  bool _initialized = false;
  bool _isSpeaking = false;

  // ============================================================
  // CONFIGURACIÓN ACTUAL
  // ============================================================

  static const double defaultSpeechRate = 0.36;
  static const double minSpeechRate = 0.15;
  static const double maxSpeechRate = 1.0;

  static const double defaultPitch = 1.0;
  static const double defaultVolume = 1.0;

  double _speechRate = defaultSpeechRate;
  double _pitch = defaultPitch;
  double _volume = defaultVolume;

  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;

  bool get isSpeaking => _isSpeaking;

  // ============================================================
  // INICIALIZACIÓN
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _flutterTts.setLanguage('ko-KR');
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setErrorHandler(
          (message) {
        _isSpeaking = false;
      },
    );

    _initialized = true;
  }

  // ============================================================
  // HABLAR COREANO
  // ============================================================

  Future<void> speakKorean(
      String text,
      ) async {
    final value = text.trim();

    if (value.isEmpty) {
      return;
    }

    await initialize();

    if (_isSpeaking) {
      await stop();
    }

    await _flutterTts.setLanguage('ko-KR');
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setVolume(_volume);

    await _flutterTts.speak(value);
  }

  // ============================================================
  // DETENER
  // ============================================================

  Future<void> stop() async {
    await _flutterTts.stop();

    _isSpeaking = false;
  }

  // ============================================================
  // PAUSAR
  // ============================================================

  Future<void> pause() async {
    await _flutterTts.pause();
  }

  // ============================================================
  // VELOCIDAD
  // ============================================================

  Future<void> setSpeechRate(
      double rate,
      ) async {
    _speechRate = rate.clamp(minSpeechRate, maxSpeechRate);

    await initialize();

    await _flutterTts.setSpeechRate(_speechRate);
  }

  // ============================================================
  // VOLUMEN
  // ============================================================

  Future<void> setVolume(
      double volume,
      ) async {
    _volume = volume.clamp(0.0, 1.0);

    await initialize();

    await _flutterTts.setVolume(_volume);
  }

  // ============================================================
  // TONO
  // ============================================================

  Future<void> setPitch(
      double pitch,
      ) async {
    _pitch = pitch.clamp(0.5, 2.0);

    await initialize();

    await _flutterTts.setPitch(_pitch);
  }

  // ============================================================
  // COMPROBAR SI EXISTE COREANO
  // ============================================================

  Future<bool> isKoreanAvailable() async {
    try {
      await initialize();

      final languages = await _flutterTts.getLanguages;

      if (languages == null) {
        return false;
      }

      for (final language in languages) {
        final value = language.toString().toLowerCase();

        if (value == 'ko-kr' ||
            value == 'ko_kr' ||
            value == 'ko') {
          return true;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // OBTENER IDIOMAS DISPONIBLES
  // ============================================================

  Future<List<String>> getAvailableLanguages() async {
    try {
      await initialize();

      final languages = await _flutterTts.getLanguages;

      if (languages == null) {
        return [];
      }

      return languages
          .map((language) => language.toString())
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // LIBERAR RECURSOS
  // ============================================================

  Future<void> dispose() async {
    await stop();

    _initialized = false;
  }
}