import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

enum VoiceServiceState {
  idle,
  listening,
  processing,
  speaking,
  error
}

enum VoiceRecognitionLanguage {
  thai,
  english
}

class VoiceService extends ChangeNotifier {
  static VoiceService? _instance;
  static VoiceService get instance => _instance ??= VoiceService._();

  VoiceService._();

  // Speech to Text
  late stt.SpeechToText _speechToText;

  // Text to Speech
  late FlutterTts _flutterTts;

  // State management
  VoiceServiceState _state = VoiceServiceState.idle;
  bool _isInitialized = false;
  String _lastWords = '';
  double _confidence = 0.0;
  VoiceRecognitionLanguage _currentLanguage = VoiceRecognitionLanguage.thai;

  // Settings
  double _speechRate = 1.0;
  double _pitch = 1.0;
  double _volume = 1.0;
  String _ttsLanguage = 'th-TH';
  String _sttLanguage = 'th-TH';

  // Stream controllers
  final StreamController<String> _onSpeechResult = StreamController<String>.broadcast();
  final StreamController<VoiceServiceState> _onStateChanged = StreamController<VoiceServiceState>.broadcast();
  final StreamController<String> _onError = StreamController<String>.broadcast();

  // Getters
  VoiceServiceState get state => _state;
  bool get isInitialized => _isInitialized;
  bool get isListening => _state == VoiceServiceState.listening;
  bool get isSpeaking => _state == VoiceServiceState.speaking;
  String get lastWords => _lastWords;
  double get confidence => _confidence;
  VoiceRecognitionLanguage get currentLanguage => _currentLanguage;

  // Settings getters
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  String get ttsLanguage => _ttsLanguage;
  String get sttLanguage => _sttLanguage;

  // Streams
  Stream<String> get onSpeechResult => _onSpeechResult.stream;
  Stream<VoiceServiceState> get onStateChanged => _onStateChanged.stream;
  Stream<String> get onError => _onError.stream;

  /// Initialize voice service
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Initialize Speech to Text
      _speechToText = stt.SpeechToText();
      await _initializeSpeechToText();

      // Initialize Text to Speech
      _flutterTts = FlutterTts();
      await _initializeTextToSpeech();

      _isInitialized = true;
      print('Voice service initialized successfully');

    } catch (e) {
      _setState(VoiceServiceState.error);
      _onError.add('Failed to initialize voice service: $e');
      print('Error initializing voice service: $e');
    }
  }

  /// Initialize Speech to Text
  Future<void> _initializeSpeechToText() async {
    final available = await _speechToText.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );

    if (!available) {
      throw Exception('Speech recognition not available');
    }

    print('Speech to Text initialized');
  }

  /// Initialize Text to Speech
  Future<void> _initializeTextToSpeech() async {
    // Configure TTS
    await _flutterTts.setLanguage(_ttsLanguage);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.setVolume(_volume);

    // Set up callbacks
    _flutterTts.setStartHandler(() {
      _setState(VoiceServiceState.speaking);
    });

    _flutterTts.setCompletionHandler(() {
      _setState(VoiceServiceState.idle);
    });

    _flutterTts.setErrorHandler((message) {
      _setState(VoiceServiceState.error);
      _onError.add('TTS Error: $message');
    });

    print('Text to Speech initialized');
  }

  /// Check and request microphone permission
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    } else {
      return false;
    }
  }

  /// Start listening for speech
  Future<void> startListening({
    VoiceRecognitionLanguage? language,
    Duration? timeout,
  }) async {
    if (!_isInitialized) {
      throw Exception('Voice service not initialized');
    }

    if (_state == VoiceServiceState.listening) {
      return;
    }

    // Check microphone permission
    final hasPermission = await checkMicrophonePermission();
    if (!hasPermission) {
      _onError.add('Microphone permission denied');
      return;
    }

    // Set language if provided
    if (language != null) {
      await setRecognitionLanguage(language);
    }

    try {
      _setState(VoiceServiceState.listening);

      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: _sttLanguage,
        cancelOnError: false,
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
        listenFor: timeout ?? const Duration(seconds: 30),
      );

    } catch (e) {
      _setState(VoiceServiceState.error);
      _onError.add('Failed to start listening: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    _setState(VoiceServiceState.idle);
  }

  /// Speak text
  Future<void> speak(String text, {
    String? language,
    double? rate,
    double? pitch,
    double? volume,
  }) async {
    if (!_isInitialized) {
      throw Exception('Voice service not initialized');
    }

    if (_state == VoiceServiceState.speaking) {
      await _flutterTts.stop();
    }

    try {
      // Set temporary parameters if provided
      if (language != null) {
        await _flutterTts.setLanguage(language);
      }
      if (rate != null) {
        await _flutterTts.setSpeechRate(rate);
      }
      if (pitch != null) {
        await _flutterTts.setPitch(pitch);
      }
      if (volume != null) {
        await _flutterTts.setVolume(volume);
      }

      _setState(VoiceServiceState.speaking);
      await _flutterTts.speak(text);

      // Reset to default parameters
      if (language != null) {
        await _flutterTts.setLanguage(_ttsLanguage);
      }
      if (rate != null) {
        await _flutterTts.setSpeechRate(_speechRate);
      }
      if (pitch != null) {
        await _flutterTts.setPitch(_pitch);
      }
      if (volume != null) {
        await _flutterTts.setVolume(_volume);
      }

    } catch (e) {
      _setState(VoiceServiceState.error);
      _onError.add('Failed to speak: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (_state == VoiceServiceState.speaking) {
      await _flutterTts.stop();
      _setState(VoiceServiceState.idle);
    }
  }

  /// Set recognition language
  Future<void> setRecognitionLanguage(VoiceRecognitionLanguage language) async {
    _currentLanguage = language;

    switch (language) {
      case VoiceRecognitionLanguage.thai:
        _sttLanguage = 'th-TH';
        break;
      case VoiceRecognitionLanguage.english:
        _sttLanguage = 'en-US';
        break;
    }

    notifyListeners();
  }

  /// Set TTS language
  Future<void> setTTSLanguage(String language) async {
    _ttsLanguage = language;
    if (_isInitialized) {
      await _flutterTts.setLanguage(language);
    }
    notifyListeners();
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    if (_isInitialized) {
      await _flutterTts.setSpeechRate(_speechRate);
    }
    notifyListeners();
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    if (_isInitialized) {
      await _flutterTts.setPitch(_pitch);
    }
    notifyListeners();
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_isInitialized) {
      await _flutterTts.setVolume(_volume);
    }
    notifyListeners();
  }

  /// Get available languages
  Future<List<dynamic>> getAvailableLanguages() async {
    if (!_isInitialized) return [];
    return await _flutterTts.getLanguages;
  }

  /// Get available speech recognition locales
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) return [];
    return await _speechToText.locales();
  }

  /// Check if language is available for TTS
  Future<bool> isLanguageAvailable(String language) async {
    final languages = await getAvailableLanguages();
    return languages.contains(language);
  }

  // Event handlers
  void _onSpeechResult(stt.SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    _confidence = result.confidence;

    if (result.finalResult) {
      _setState(VoiceServiceState.processing);
      _onSpeechResult.add(_lastWords);

      // Auto return to idle after processing
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_state == VoiceServiceState.processing) {
          _setState(VoiceServiceState.idle);
        }
      });
    }

    notifyListeners();
  }

  void _onSpeechStatus(String status) {
    print('Speech status: $status');

    if (status == 'notListening' && _state == VoiceServiceState.listening) {
      _setState(VoiceServiceState.idle);
    }
  }

  void _onSpeechError(stt.SpeechRecognitionError error) {
    _setState(VoiceServiceState.error);
    _onError.add('Speech recognition error: ${error.errorMsg}');
    print('Speech error: ${error.errorMsg}');
  }

  void _setState(VoiceServiceState newState) {
    if (_state != newState) {
      _state = newState;
      _onStateChanged.add(newState);
      notifyListeners();
    }
  }

  /// Utility methods
  String getStateDisplayText() {
    switch (_state) {
      case VoiceServiceState.idle:
        return 'พร้อมใช้งาน';
      case VoiceServiceState.listening:
        return 'กำลังฟัง...';
      case VoiceServiceState.processing:
        return 'กำลังประมวลผล...';
      case VoiceServiceState.speaking:
        return 'กำลังพูด...';
      case VoiceServiceState.error:
        return 'เกิดข้อผิดพลาด';
    }
  }

  String getLanguageDisplayText(VoiceRecognitionLanguage language) {
    switch (language) {
      case VoiceRecognitionLanguage.thai:
        return 'ภาษาไทย';
      case VoiceRecognitionLanguage.english:
        return 'English';
    }
  }

  /// Clean up resources
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
    _onSpeechResult.close();
    _onStateChanged.close();
    _onError.close();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!kIsWeb && Platform.isAndroid || Platform.isIOS) {
      super.notifyListeners();
    }
  }
}

// Voice command processor
class VoiceCommandProcessor {
  static final Map<String, List<String>> _commandPatterns = {
    'navigation': [
      'ไปที่',
      'เปิด',
      'แสดง',
      'นำทาง',
    ],
    'commands': [
      'คำสั่ง',
      'รัน',
      'เรียกใช้',
      'ทำ',
    ],
    'help': [
      'ช่วย',
      'ความช่วยเหลือ',
      'ไม่เข้าใจ',
      'อธิบาย',
    ],
    'quiz': [
      'แบบทดสอบ',
      'ทดสอบ',
      'สอบ',
      'ควิซ',
    ],
  };

  static VoiceCommandResult processCommand(String spokenText) {
    final lowercaseText = spokenText.toLowerCase();

    for (final category in _commandPatterns.entries) {
      for (final pattern in category.value) {
        if (lowercaseText.contains(pattern.toLowerCase())) {
          return VoiceCommandResult(
            category: category.key,
            command: _extractCommand(spokenText, pattern),
            confidence: 0.8,
            originalText: spokenText,
          );
        }
      }
    }

    return VoiceCommandResult(
      category: 'unknown',
      command: spokenText,
      confidence: 0.3,
      originalText: spokenText,
    );
  }

  static String _extractCommand(String text, String pattern) {
    final index = text.toLowerCase().indexOf(pattern.toLowerCase());
    if (index != -1) {
      return text.substring(index + pattern.length).trim();
    }
    return text;
  }
}

class VoiceCommandResult {
  final String category;
  final String command;
  final double confidence;
  final String originalText;

  const VoiceCommandResult({
    required this.category,
    required this.command,
    required this.confidence,
    required this.originalText,
  });

  bool get isHighConfidence => confidence >= 0.7;
  bool get isNavigation => category == 'navigation';
  bool get isCommand => category == 'commands';
  bool get isHelp => category == 'help';
  bool get isQuiz => category == 'quiz';
}