import 'package:flutter/foundation.dart';
import '../services/voice_service.dart';

class VoiceProvider with ChangeNotifier {
  final VoiceService _voiceService;

  // State variables
  bool _isEnabled = true;
  bool _isSpeaking = false;
  bool _isListening = false;
  bool _isInitialized = false;
  String _lastRecognizedText = '';
  String _lastSpokenText = '';
  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;
  String _language = 'th-TH';
  String _errorMessage = '';
  bool _hasError = false;

  VoiceProvider(this._voiceService);

  // Getters
  bool get isEnabled => _isEnabled;
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastRecognizedText => _lastRecognizedText;
  String get lastSpokenText => _lastSpokenText;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  String get language => _language;
  String get errorMessage => _errorMessage;
  bool get hasError => _hasError;

  // Initialize voice service
  Future<void> initialize() async {
    try {
      _hasError = false;
      _errorMessage = '';
      notifyListeners();

      final ttsInitialized = await _voiceService.initializeTts();
      final sttInitialized = await _voiceService.initializeStt();

      _isInitialized = ttsInitialized || sttInitialized;

      if (!_isInitialized) {
        _setError('ไม่สามารถเริ่มต้นระบบเสียงได้');
      }

      notifyListeners();
    } catch (e) {
      _setError('เกิดข้อผิดพลาดในการเริ่มต้นระบบเสียง: $e');
    }
  }

  // Enable/disable voice features
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stopSpeaking();
      stopListening();
    }
    notifyListeners();
  }

  // Text-to-Speech methods
  Future<void> speak(String text) async {
    if (!_isEnabled || !_isInitialized) return;

    try {
      _hasError = false;
      _errorMessage = '';
      _isSpeaking = true;
      _lastSpokenText = text;
      notifyListeners();

      final success = await _voiceService.speak(text);
      if (!success) {
        _setError('ไม่สามารถพูดข้อความได้');
      }

      // Update speaking state periodically
      _updateSpeakingState();
    } catch (e) {
      _setError('เกิดข้อผิดพลาดในการพูด: $e');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _voiceService.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      _setError('เกิดข้อผิดพลาดในการหยุดพูด: $e');
    }
  }

  Future<void> pauseSpeaking() async {
    try {
      await _voiceService.pause();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      _setError('เกิดข้อผิดพลาดในการพักการพูด: $e');
    }
  }

  // Speech-to-Text methods
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    Duration? listenFor,
  }) async {
    if (!_isEnabled || !_isInitialized) return;

    try {
      _hasError = false;
      _errorMessage = '';
      _isListening = true;
      notifyListeners();

      final success = await _voiceService.startListening(
        onResult: (result) {
          _lastRecognizedText = result;
          _isListening = false;
          notifyListeners();
          onResult(result);
        },
        onPartialResult: onPartialResult,
        onError: (error) {
          _setError(error);
          _isListening = false;
        },
        listenFor: listenFor,
      );

      if (!success) {
        _setError('ไม่สามารถเริ่มการฟังได้');
        _isListening = false;
        notifyListeners();
      }
    } catch (e) {
      _setError('เกิดข้อผิดพลาดในการเริ่มการฟัง: $e');
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _voiceService.stopListening();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      _setError('เกิดข้อผิดพลาดในการหยุดการฟัง: $e');
    }
  }

  Future<void> cancelListening() async {
    try {
      await _voiceService.cancelListening();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      _setError('เกิดข้อผิดพลาดในการยกเลิกการฟัง: $e');
    }
  }

  // Settings methods
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _voiceService.setSpeechRate(_speechRate);
    notifyListeners();
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    await _voiceService.setVolume(_volume);
    notifyListeners();
  }

  Future<void> setPitch(double pitchValue) async {
    _pitch = pitchValue.clamp(0.5, 2.0);
    await _voiceService.setPitch(_pitch);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _voiceService.setLanguage(_language);
    notifyListeners();
  }

  // Utility methods for app-specific use cases
  Future<void> speakWelcomeMessage() async {
    await speak('สวัสดีครับ ยินดีต้อนรับสู่ Linux Learning Chatbot');
  }

  Future<void> speakCommandExplanation(String command, String explanation) async {
    await speak('คำสั่ง $command ใช้สำหรับ $explanation');
  }

  Future<void> speakQuizQuestion(String question, List<String> options) async {
    final optionsText = options.asMap().entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join(', ');
    await speak('$question ตัวเลือกคือ: $optionsText');
  }

  Future<void> speakQuizResult(bool isCorrect, String explanation) async {
    final resultText = isCorrect ? 'ถูกต้อง!' : 'ไม่ถูกต้อง';
    await speak('$resultText $explanation');
  }

  Future<void> speakAchievementUnlocked(String achievementName) async {
    await speak('ยินดีด้วย! คุณได้รับความสำเร็จใหม่: $achievementName');
  }

  Future<void> speakLevelUp(int newLevel) async {
    await speak('ยินดีด้วย! คุณเลื่อนระดับเป็นระดับ $newLevel แล้ว');
  }

  Future<void> speakErrorMessage(String error) async {
    await speak('เกิดข้อผิดพลาด: $error');
  }

  Future<void> speakTerminalOutput(String output) async {
    // Clean up terminal output for better speech
    final cleanOutput = output
        .replaceAll(RegExp(r'\x1B\[[0-9;]*[mK]'), '') // Remove ANSI codes
        .replaceAll('\n', '. ')
        .trim();

    if (cleanOutput.isNotEmpty && cleanOutput.length < 500) {
      await speak('ผลลัพธ์: $cleanOutput');
    } else {
      await speak('คำสั่งทำงานเสร็จสิ้นแล้ว');
    }
  }

  // Voice command recognition for specific app features
  Future<void> startCommandListening() async {
    await startListening(
      onResult: (result) {
        _handleVoiceCommand(result.toLowerCase());
      },
      listenFor: const Duration(seconds: 10),
    );
  }

  void _handleVoiceCommand(String command) {
    // Handle voice commands for navigation and app control
    if (command.contains('ช่วยเหลือ') || command.contains('help')) {
      speak('คุณสามารถพูดคำสั่งต่างๆ เช่น "อธิบายคำสั่ง ls" หรือ "เริ่มทดสอบ"');
    } else if (command.contains('อธิบาย') && command.contains('คำสั่ง')) {
      // Extract command name and explain
      final words = command.split(' ');
      final commandIndex = words.indexOf('คำสั่ง');
      if (commandIndex != -1 && commandIndex < words.length - 1) {
        final linuxCommand = words[commandIndex + 1];
        // This would integrate with the command explanation system
        speak('กำลังค้นหาข้อมูลเกี่ยวกับคำสั่ง $linuxCommand');
      }
    } else if (command.contains('ทดสอบ') || command.contains('quiz')) {
      speak('กำลังเริ่มแบบทดสอบ');
    } else if (command.contains('หยุด') || command.contains('stop')) {
      stopSpeaking();
    } else {
      speak('ขออภัย ฉันไม่เข้าใจคำสั่งนี้ ลองพูด "ช่วยเหลือ" เพื่อดูคำสั่งที่รองรับ');
    }
  }

  // Check permissions
  Future<bool> checkMicrophonePermission() async {
    return await _voiceService.checkMicrophonePermission();
  }

  Future<bool> requestMicrophonePermission() async {
    final granted = await _voiceService.requestMicrophonePermission();
    if (!granted) {
      _setError('จำเป็นต้องได้รับอนุญาตใช้ไมโครโฟนเพื่อใช้งานฟีเจอร์เสียง');
    }
    return granted;
  }

  // Get available options
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      return await _voiceService.getAvailableVoices();
    } catch (e) {
      _setError('ไม่สามารถโหลดรายการเสียงได้: $e');
      return [];
    }
  }

  // Test functions
  Future<void> testTts() async {
    await speak('ทดสอบการพูด Text-to-Speech ภาษาไทย');
  }

  Future<void> testStt() async {
    await startListening(
      onResult: (result) {
        speak('คุณพูดว่า: $result');
      },
      listenFor: const Duration(seconds: 5),
    );
  }

  // Helper methods
  void _updateSpeakingState() {
    // Periodically check if TTS is still speaking
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_voiceService.isSpeaking != _isSpeaking) {
        _isSpeaking = _voiceService.isSpeaking;
        notifyListeners();

        if (_isSpeaking) {
          _updateSpeakingState(); // Continue checking
        }
      }
    });
  }

  void _setError(String error) {
    _hasError = true;
    _errorMessage = error;
    _isSpeaking = false;
    _isListening = false;
    notifyListeners();
    debugPrint('Voice Provider Error: $error');
  }

  // Clear error
  void clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }

  // Reset state
  void reset() {
    _isSpeaking = false;
    _isListening = false;
    _lastRecognizedText = '';
    _lastSpokenText = '';
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}