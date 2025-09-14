import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static VoiceService? _instance;
  static VoiceService get instance => _instance ??= VoiceService._();
  VoiceService._();

  // TTS and STT instances
  FlutterTts? _flutterTts;
  SpeechToText? _speechToText;

  // State variables
  bool _isTtsInitialized = false;
  bool _isSttInitialized = false;
  bool _isSpeaking = false;
  bool _isListening = false;
  String _lastSpokenText = '';
  String _lastRecognizedText = '';

  // Settings
  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;
  String _language = 'th-TH';
  String _engine = '';

  // Getters
  bool get isTtsInitialized => _isTtsInitialized;
  bool get isSttInitialized => _isSttInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  String get lastSpokenText => _lastSpokenText;
  String get lastRecognizedText => _lastRecognizedText;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  String get language => _language;

  // Initialize TTS
  Future<bool> initializeTts() async {
    if (_isTtsInitialized) return true;

    try {
      _flutterTts = FlutterTts();

      // Set up TTS handlers
      await _flutterTts!.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('TTS: Started speaking');
      });

      await _flutterTts!.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('TTS: Completed speaking');
      });

      await _flutterTts!.setCancelHandler(() {
        _isSpeaking = false;
        debugPrint('TTS: Cancelled speaking');
      });

      await _flutterTts!.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });

      // Configure TTS settings
      await _flutterTts!.setLanguage(_language);
      await _flutterTts!.setSpeechRate(_speechRate);
      await _flutterTts!.setVolume(_volume);
      await _flutterTts!.setPitch(_pitch);

      // Check available engines
      final engines = await _flutterTts!.getEngines;
      if (engines != null && engines.isNotEmpty) {
        _engine = engines.first['name'];
        await _flutterTts!.setEngine(_engine);
      }

      _isTtsInitialized = true;
      debugPrint('TTS initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      return false;
    }
  }

  // Initialize STT
  Future<bool> initializeStt() async {
    if (_isSttInitialized) return true;

    try {
      _speechToText = SpeechToText();

      // Request microphone permission
      final permissionStatus = await Permission.microphone.request();
      if (permissionStatus != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      final available = await _speechToText!.initialize(
        onError: (error) {
          debugPrint('STT Error: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint('STT Status: $status');
          _isListening = status == 'listening';
        },
      );

      if (available) {
        _isSttInitialized = true;
        debugPrint('STT initialized successfully');
        return true;
      } else {
        debugPrint('STT not available on this device');
        return false;
      }
    } catch (e) {
      debugPrint('Error initializing STT: $e');
      return false;
    }
  }

  // Speak text
  Future<bool> speak(String text) async {
    if (!_isTtsInitialized) {
      final initialized = await initializeTts();
      if (!initialized) return false;
    }

    try {
      if (_isSpeaking) {
        await stop();
      }

      _lastSpokenText = text;
      await _flutterTts!.speak(text);
      return true;
    } catch (e) {
      debugPrint('Error speaking text: $e');
      return false;
    }
  }

  // Stop speaking
  Future<bool> stop() async {
    if (!_isTtsInitialized || _flutterTts == null) return false;

    try {
      await _flutterTts!.stop();
      _isSpeaking = false;
      return true;
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
      return false;
    }
  }

  // Pause speaking
  Future<bool> pause() async {
    if (!_isTtsInitialized || _flutterTts == null) return false;

    try {
      await _flutterTts!.pause();
      return true;
    } catch (e) {
      debugPrint('Error pausing TTS: $e');
      return false;
    }
  }

  // Start listening for speech
  Future<bool> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    Function(String)? onError,
    Duration? listenFor,
  }) async {
    if (!_isSttInitialized) {
      final initialized = await initializeStt();
      if (!initialized) return false;
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      final locales = await _speechToText!.locales();
      final locale = locales.firstWhere(
            (l) => l.localeId.startsWith(_language.substring(0, 2)),
        orElse: () => locales.first,
      );

      await _speechToText!.listen(
        onResult: (result) {
          final recognizedWords = result.recognizedWords;
          if (result.finalResult) {
            _lastRecognizedText = recognizedWords;
            _isListening = false;
            onResult(recognizedWords);
          } else if (onPartialResult != null) {
            onPartialResult(recognizedWords);
          }
        },
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: onPartialResult != null,
        onSoundLevelChange: (level) {
          // Handle sound level changes if needed
        },
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        localeId: locale.localeId,
      );

      _isListening = true;
      return true;
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      if (onError != null) {
        onError('การรับรู้เสียงล้มเหลว: $e');
      }
      return false;
    }
  }

  // Stop listening
  Future<bool> stopListening() async {
    if (!_isSttInitialized || _speechToText == null) return false;

    try {
      await _speechToText!.stop();
      _isListening = false;
      return true;
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
      return false;
    }
  }

  // Cancel listening
  Future<bool> cancelListening() async {
    if (!_isSttInitialized || _speechToText == null) return false;

    try {
      await _speechToText!.cancel();
      _isListening = false;
      return true;
    } catch (e) {
      debugPrint('Error cancelling speech recognition: $e');
      return false;
    }
  }

  // Get available languages
  Future<List<LocaleName>> getAvailableLanguages() async {
    if (!_isSttInitialized) {
      await initializeStt();
    }

    try {
      if (_speechToText != null) {
        return await _speechToText!.locales();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting available languages: $e');
      return [];
    }
  }

  // Get available TTS voices
  Future<List<Map<String, String>>> getAvailableVoices() async {
    if (!_isTtsInitialized) {
      await initializeTts();
    }

    try {
      if (_flutterTts != null) {
        final voices = await _flutterTts!.getVoices;
        return List<Map<String, String>>.from(voices ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Error getting available voices: $e');
      return [];
    }
  }

  // Set TTS settings
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    if (_isTtsInitialized && _flutterTts != null) {
      await _flutterTts!.setSpeechRate(_speechRate);
    }
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    if (_isTtsInitialized && _flutterTts != null) {
      await _flutterTts!.setVolume(_volume);
    }
  }

  Future<void> setPitch(double pitchValue) async {
    _pitch = pitchValue.clamp(0.5, 2.0);
    if (_isTtsInitialized && _flutterTts != null) {
      await _flutterTts!.setPitch(_pitch);
    }
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    if (_isTtsInitialized && _flutterTts != null) {
      await _flutterTts!.setLanguage(_language);
    }
  }

  // Utility methods for Linux learning
  Future<void> speakCommandExplanation(String command, String explanation) async {
    final text = 'คำสั่ง $command: $explanation';
    await speak(text);
  }

  Future<void> speakQuizQuestion(String question, List<String> options) async {
    final optionsText = options.asMap().entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join(', ');
    final text = '$question ตัวเลือก: $optionsText';
    await speak(text);
  }

  Future<void> speakAchievement(String achievementName) async {
    final text = 'ยินดีด้วย! คุณได้รับความสำเร็จ: $achievementName';
    await speak(text);
  }

  Future<void> speakWelcomeMessage() async {
    const text = 'สวัสดีครับ ยินดีต้อนรับสู่ Linux Learning Chatbot คุณสามารถใช้เสียงในการสนทนากับผมได้';
    await speak(text);
  }

  Future<void> speakErrorMessage(String error) async {
    final text = 'เกิดข้อผิดพลาด: $error';
    await speak(text);
  }

  // Check permissions
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status == PermissionStatus.granted;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  // Cleanup resources
  void dispose() {
    _flutterTts?.stop();
    _speechToText?.stop();
    _isTtsInitialized = false;
    _isSttInitialized = false;
    _isSpeaking = false;
    _isListening = false;
  }

  // Test TTS
  Future<bool> testTts() async {
    return await speak('ทดสอบการพูด Text-to-Speech');
  }

  // Test STT
  Future<bool> testStt() async {
    return await startListening(
      onResult: (result) {
        debugPrint('STT Test Result: $result');
      },
      onError: (error) {
        debugPrint('STT Test Error: $error');
      },
      listenFor: const Duration(seconds: 5),
    );
  }
}