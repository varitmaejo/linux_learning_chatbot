import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/services/voice_service.dart';
import '../../data/models/user_model.dart';

class VoiceProvider extends ChangeNotifier {
  final VoiceService _voiceService = VoiceService.instance;

  // State
  UserModel? _currentUser;
  StreamSubscription<String>? _speechSubscription;
  StreamSubscription<VoiceServiceState>? _stateSubscription;
  StreamSubscription<String>? _errorSubscription;

  // Settings
  bool _voiceInputEnabled = true;
  bool _voiceOutputEnabled = true;
  bool _autoListen = false;
  bool _continuousListening = false;
  VoiceRecognitionLanguage _recognitionLanguage = VoiceRecognitionLanguage.thai;

  // Callbacks
  Function(String)? _onSpeechResult;
  Function(String)? _onSpeechError;
  Function(VoiceServiceState)? _onStateChanged;

  // Getters
  VoiceService get voiceService => _voiceService;
  UserModel? get currentUser => _currentUser;
  bool get isInitialized => _voiceService.isInitialized;
  bool get isListening => _voiceService.isListening;
  bool get isSpeaking => _voiceService.isSpeaking;
  VoiceServiceState get state => _voiceService.state;
  String get lastWords => _voiceService.lastWords;
  double get confidence => _voiceService.confidence;

  // Settings getters
  bool get voiceInputEnabled => _voiceInputEnabled;
  bool get voiceOutputEnabled => _voiceOutputEnabled;
  bool get autoListen => _autoListen;
  bool get continuousListening => _continuousListening;
  VoiceRecognitionLanguage get recognitionLanguage => _recognitionLanguage;
  double get speechRate => _voiceService.speechRate;
  double get pitch => _voiceService.pitch;
  double get volume => _voiceService.volume;

  /// Initialize provider
  Future<void> initialize() async {
    try {
      await _voiceService.initialize();
      _setupListeners();
    } catch (e) {
      print('Error initializing voice provider: $e');
    }
  }

  /// Update current user and apply preferences
  void updateUser(UserModel? user) {
    _currentUser = user;
    if (user != null) {
      _applyUserPreferences(user.preferences);
    }
    notifyListeners();
  }

  /// Apply user preferences
  void _applyUserPreferences(UserPreferences preferences) {
    _voiceInputEnabled = preferences.enableVoiceInput;
    _voiceOutputEnabled = preferences.enableVoiceOutput;

    // Apply voice settings
    _voiceService.setSpeechRate(preferences.voiceSpeed);
    _voiceService.setTTSLanguage(preferences.voiceLanguage);

    // Set recognition language based on user preference
    final lang = preferences.language == 'en'
        ? VoiceRecognitionLanguage.english
        : VoiceRecognitionLanguage.thai;
    setRecognitionLanguage(lang);

    notifyListeners();
  }

  /// Setup event listeners
  void _setupListeners() {
    _speechSubscription = _voiceService.onSpeechResult.listen((result) {
      _onSpeechResult?.call(result);

      // Handle continuous listening
      if (_continuousListening && _voiceInputEnabled) {
        _restartListeningDelayed();
      }
    });

    _stateSubscription = _voiceService.onStateChanged.listen((state) {
      _onStateChanged?.call(state);
      notifyListeners();
    });

    _errorSubscription = _voiceService.onError.listen((error) {
      _onSpeechError?.call(error);
    });
  }

  /// Set callbacks
  void setSpeechResultCallback(Function(String) callback) {
    _onSpeechResult = callback;
  }

  void setSpeechErrorCallback(Function(String) callback) {
    _onSpeechError = callback;
  }

  void setStateChangedCallback(Function(VoiceServiceState) callback) {
    _onStateChanged = callback;
  }

  /// Start listening
  Future<void> startListening({
    Duration? timeout,
    VoiceRecognitionLanguage? language,
  }) async {
    if (!_voiceInputEnabled || !isInitialized) return;

    try {
      await _voiceService.startListening(
        language: language ?? _recognitionLanguage,
        timeout: timeout,
      );
    } catch (e) {
      _onSpeechError?.call('เกิดข้อผิดพลาดในการฟัง: ${e.toString()}');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _voiceService.stopListening();
  }

  /// Toggle listening
  Future<void> toggleListening() async {
    if (isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  /// Speak text
  Future<void> speak(String text, {
    String? language,
    double? rate,
    double? pitch,
    double? volume,
  }) async {
    if (!_voiceOutputEnabled || !isInitialized) return;

    try {
      await _voiceService.speak(
        text,
        language: language,
        rate: rate,
        pitch: pitch,
        volume: volume,
      );
    } catch (e) {
      print('Error speaking: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _voiceService.stopSpeaking();
  }

  /// Quick speak for bot responses
  Future<void> speakBotResponse(String text) async {
    if (!_voiceOutputEnabled || text.trim().isEmpty) return;

    // Use user's preferred language and settings
    await speak(
      text,
      language: _currentUser?.preferences.voiceLanguage ?? 'th-TH',
      rate: _currentUser?.preferences.voiceSpeed ?? 1.0,
    );
  }

  /// Settings methods
  Future<void> setVoiceInputEnabled(bool enabled) async {
    _voiceInputEnabled = enabled;

    if (!enabled && isListening) {
      await stopListening();
    }

    await _updateUserPreference('enableVoiceInput', enabled);
    notifyListeners();
  }

  Future<void> setVoiceOutputEnabled(bool enabled) async {
    _voiceOutputEnabled = enabled;

    if (!enabled && isSpeaking) {
      await stopSpeaking();
    }

    await _updateUserPreference('enableVoiceOutput', enabled);
    notifyListeners();
  }

  Future<void> setAutoListen(bool enabled) async {
    _autoListen = enabled;
    await _updateUserPreference('autoPlayVoice', enabled);
    notifyListeners();
  }

  Future<void> setContinuousListening(bool enabled) async {
    _continuousListening = enabled;

    if (!enabled && isListening) {
      await stopListening();
    }

    notifyListeners();
  }

  Future<void> setRecognitionLanguage(VoiceRecognitionLanguage language) async {
    _recognitionLanguage = language;
    await _voiceService.setRecognitionLanguage(language);

    // Update user preference
    final langCode = language == VoiceRecognitionLanguage.english ? 'en-US' : 'th-TH';
    await _updateUserPreference('voiceLanguage', langCode);

    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    await _voiceService.setSpeechRate(rate);
    await _updateUserPreference('voiceSpeed', rate);
    notifyListeners();
  }

  Future<void> setPitch(double pitch) async {
    await _voiceService.setPitch(pitch);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    await _voiceService.setVolume(volume);
    notifyListeners();
  }

  Future<void> setTTSLanguage(String language) async {
    await _voiceService.setTTSLanguage(language);
    await _updateUserPreference('voiceLanguage', language);
    notifyListeners();
  }

  /// Update user preference
  Future<void> _updateUserPreference(String key, dynamic value) async {
    if (_currentUser == null) return;

    try {
      // This would typically update through AuthProvider
      // For now, just update locally
      print('Updating user preference: $key = $value');
    } catch (e) {
      print('Error updating user preference: $e');
    }
  }

  /// Restart listening with delay (for continuous mode)
  void _restartListeningDelayed() {
    Timer(const Duration(seconds: 1), () {
      if (_continuousListening && _voiceInputEnabled && !isListening) {
        startListening();
      }
    });
  }

  /// Permission handling
  Future<bool> checkMicrophonePermission() async {
    return await _voiceService.checkMicrophonePermission();
  }

  /// Get available languages
  Future<List<dynamic>> getAvailableLanguages() async {
    return await _voiceService.getAvailableLanguages();
  }

  Future<List<stt.LocaleName>> getAvailableLocales() async {
    return await _voiceService.getAvailableLocales();
  }

  /// Voice command processing
  VoiceCommandResult processVoiceCommand(String spokenText) {
    return VoiceCommandProcessor.processCommand(spokenText);
  }

  /// Utility methods
  String getStateDisplayText() {
    return _voiceService.getStateDisplayText();
  }

  String getLanguageDisplayText() {
    return _voiceService.getLanguageDisplayText(_recognitionLanguage);
  }

  /// Voice feedback for UI interactions
  Future<void> playSuccessSound() async {
    await speak('สำเร็จ', rate: 1.2, pitch: 1.2);
  }

  Future<void> playErrorSound() async {
    await speak('ผิดพลาด', rate: 0.8, pitch: 0.8);
  }