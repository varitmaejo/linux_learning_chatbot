import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/firebase_constants.dart';
import 'firebase_service.dart';

class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();

  AnalyticsService._();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;
  bool _isInitialized = false;
  bool _analyticsEnabled = true;
  String? _userId;
  Map<String, dynamic>? _deviceInfo;
  PackageInfo? _packageInfo;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get analyticsEnabled => _analyticsEnabled;
  FirebaseAnalyticsObserver? get observer => _observer;
  String? get userId => _userId;

  /// Initialize analytics service
  Future<void> initialize({String? userId, bool enabled = true}) async {
    try {
      if (_isInitialized) return;

      _analyticsEnabled = enabled;
      _userId = userId;

      if (_analyticsEnabled) {
        _analytics = FirebaseAnalytics.instance;
        _observer = FirebaseAnalyticsObserver(analytics: _analytics!);

        // Set analytics collection enabled
        await _analytics!.setAnalyticsCollectionEnabled(true);

        // Set user ID if provided
        if (_userId != null) {
          await _analytics!.setUserId(id: _userId);
        }

        // Collect device and app info
        await _collectDeviceInfo();
        await _collectAppInfo();

        // Set default user properties
        await _setDefaultUserProperties();
      }

      _isInitialized = true;
      print('Analytics service initialized successfully');

    } catch (e) {
      print('Error initializing analytics service: $e');
    }
  }

  /// Collect device information
  Future<void> _collectDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceInfo = {
          'platform': 'Android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'manufacturer': androidInfo.manufacturer,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceInfo = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'identifierForVendor': iosInfo.identifierForVendor,
        };
      } else if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        _deviceInfo = {
          'platform': 'Web',
          'browserName': webInfo.browserName.name,
          'appName': webInfo.appName,
          'appVersion': webInfo.appVersion,
          'userAgent': webInfo.userAgent,
        };
      }

      // Set device properties
      if (_deviceInfo != null && _analytics != null) {
        for (final entry in _deviceInfo!.entries) {
          await _analytics!.setUserProperty(
            name: 'device_${entry.key}',
            value: entry.value?.toString(),
          );
        }
      }

    } catch (e) {
      print('Error collecting device info: $e');
    }
  }

  /// Collect app information
  Future<void> _collectAppInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();

      if (_packageInfo != null && _analytics != null) {
        await _analytics!.setUserProperty(
          name: 'app_version',
          value: _packageInfo!.version,
        );
        await _analytics!.setUserProperty(
          name: 'app_build',
          value: _packageInfo!.buildNumber,
        );
      }

    } catch (e) {
      print('Error collecting app info: $e');
    }
  }

  /// Set default user properties
  Future<void> _setDefaultUserProperties() async {
    if (_analytics == null) return;

    try {
      await _analytics!.setUserProperty(
        name: 'app_name',
        value: 'Linux Learning Chat',
      );
      await _analytics!.setUserProperty(
        name: 'first_open_time',
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );

    } catch (e) {
      print('Error setting default user properties: $e');
    }
  }

  /// Set user ID
  Future<void> setUserId(String userId) async {
    _userId = userId;
    if (_analytics != null && _analyticsEnabled) {
      await _analytics!.setUserId(id: userId);
    }
  }

  /// Set user properties
  Future<void> setUserProperty(String name, String? value) async {
    if (_analytics != null && _analyticsEnabled) {
      await _analytics!.setUserProperty(name: name, value: value);
    }
  }

  /// Set multiple user properties
  Future<void> setUserProperties(Map<String, String?> properties) async {
    if (_analytics != null && _analyticsEnabled) {
      for (final entry in properties.entries) {
        await _analytics!.setUserProperty(
          name: entry.key,
          value: entry.value,
        );
      }
    }
  }

  /// Log custom event
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (_analytics != null && _analyticsEnabled) {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
    }
  }

  /// Log app open
  Future<void> logAppOpen() async {
    await logEvent('app_open');
  }

  /// Log screen view
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    if (_analytics != null && _analyticsEnabled) {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    }
  }

  /// Log user login
  Future<void> logLogin(String method) async {
    await logEvent('login', parameters: {'login_method': method});
  }

  /// Log user signup
  Future<void> logSignUp(String method) async {
    await logEvent('sign_up', parameters: {'sign_up_method': method});
  }

  /// Log learning session start
  Future<void> logLearningSessionStart({
    required String commandId,
    required String commandName,
    required String difficulty,
    required String mode,
  }) async {
    await logEvent('learning_session_start', parameters: {
      'command_id': commandId,
      'command_name': commandName,
      'difficulty': difficulty,
      'learning_mode': mode,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log learning session complete
  Future<void> logLearningSessionComplete({
    required String commandId,
    required String commandName,
    required int timeSpentSeconds,
    required int score,
    required bool successful,
  }) async {
    await logEvent('learning_session_complete', parameters: {
      'command_id': commandId,
      'command_name': commandName,
      'time_spent_seconds': timeSpentSeconds,
      'score': score,
      'successful': successful,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log quiz start
  Future<void> logQuizStart({
    required String topic,
    required String difficulty,
    required int questionCount,
  }) async {
    await logEvent('quiz_start', parameters: {
      'quiz_topic': topic,
      'quiz_difficulty': difficulty,
      'question_count': questionCount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log quiz complete
  Future<void> logQuizComplete({
    required String topic,
    required String difficulty,
    required int score,
    required int maxScore,
    required int timeSpentSeconds,
    required List<bool> answers,
  }) async {
    final correctAnswers = answers.where((answer) => answer).length;
    final accuracy = (correctAnswers / answers.length) * 100;

    await logEvent('quiz_complete', parameters: {
      'quiz_topic': topic,
      'quiz_difficulty': difficulty,
      'score': score,
      'max_score': maxScore,
      'accuracy_percentage': accuracy.round(),
      'time_spent_seconds': timeSpentSeconds,
      'question_count': answers.length,
      'correct_answers': correctAnswers,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log achievement unlock
  Future<void> logAchievementUnlock({
    required String achievementId,
    required String achievementName,
    required String achievementType,
    required int points,
  }) async {
    await logEvent('achievement_unlock', parameters: {
      'achievement_id': achievementId,
      'achievement_name': achievementName,
      'achievement_type': achievementType,
      'points_earned': points,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log command execution
  Future<void> logCommandExecution({
    required String command,
    required String category,
    required bool successful,
    required String source, // 'chat', 'terminal', 'tutorial'
  }) async {
    await logEvent('command_execution', parameters: {
      'command_name': command,
      'command_category': category,
      'execution_successful': successful,
      'execution_source': source,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log voice interaction
  Future<void> logVoiceInteraction({
    required String action, // 'start_listening', 'speech_recognized', 'tts_start'
    required String language,
    double? confidence,
    int? durationMs,
  }) async {
    await logEvent('voice_interaction', parameters: {
      'voice_action': action,
      'language': language,
      'confidence': confidence,
      'duration_ms': durationMs,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log search activity
  Future<void> logSearch({
    required String searchTerm,
    required String searchType, // 'command', 'help', 'general'
    int? resultCount,
  }) async {
    await logEvent('search', parameters: {
      'search_term': searchTerm,
      'search_type': searchType,
      'result_count': resultCount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log error
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    String? context,
  }) async {
    await logEvent('app_error', parameters: {
      'error_type': errorType,
      'error_message': errorMessage,
      'error_context': context,
      'has_stack_trace': stackTrace != null,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log user engagement
  Future<void> logEngagement({
    required String engagementType, // 'session_start', 'session_end', 'feature_used'
    required int durationSeconds,
    String? feature,
  }) async {
    await logEvent('user_engagement', parameters: {
      'engagement_type': engagementType,
      'duration_seconds': durationSeconds,
      'feature': feature,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log level up
  Future<void> logLevelUp({
    required int newLevel,
    required int xpEarned,
    required int totalXp,
  }) async {
    await logEvent('level_up', parameters: {
      'new_level': newLevel,
      'xp_earned': xpEarned,
      'total_xp': totalXp,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Log feature usage
  Future<void> logFeatureUsage({
    required String featureName,
    String? featureCategory,
    Map<String, dynamic>? additionalData,
  }) async {
    final parameters = <String, Object>{
      'feature_name': featureName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    if (featureCategory != null) {
      parameters['feature_category'] = featureCategory;
    }

    if (additionalData != null) {
      parameters.addAll(additionalData.cast<String, Object>());
    }

    await logEvent('feature_usage', parameters: parameters);
  }

  /// Log tutorial progress
  Future<void> logTutorialProgress({
    required String tutorialName,
    required String action, // 'start', 'step_complete', 'complete', 'skip'
    int? stepNumber,
    int? totalSteps,
  }) async {
    await logEvent('tutorial_progress', parameters: {
      'tutorial_name': tutorialName,
      'tutorial_action': action,
      'step_number': stepNumber,
      'total_steps': totalSteps,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Save analytics data to Firestore for advanced analysis
  Future<void> saveAnalyticsToFirestore({
    required String eventName,
    required Map<String, dynamic> eventData,
  }) async {
    if (_userId == null) return;

    try {
      final analyticsData = {
        'userId': _userId,
        'eventName': eventName,
        'eventData': eventData,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': _deviceInfo,
        'appInfo': _packageInfo?.toJson(),
        'sessionId': _generateSessionId(),
      };

      await FirebaseService.instance.saveAnalyticsData(_userId!, analyticsData);

    } catch (e) {
      print('Error saving analytics to Firestore: $e');
    }
  }

  /// Generate session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Enable/disable analytics
  Future<void> setAnalyticsEnabled(bool enabled) async {
    _analyticsEnabled = enabled;
    if (_analytics != null) {
      await _analytics!.setAnalyticsCollectionEnabled(enabled);
    }
  }

  /// Reset analytics data (GDPR compliance)
  Future<void> resetAnalyticsData() async {
    if (_analytics != null) {
      await _analytics!.resetAnalyticsData();
    }
  }

  /// Get analytics data for user dashboard
  Future<Map<String, dynamic>> getUserAnalyticsSummary() async {
    if (_userId == null) {
      return {};
    }

    try {
      return await FirebaseService.instance.getAnalyticsData(_userId!) ?? {};
    } catch (e) {
      print('Error getting analytics summary: $e');
      return {};
    }
  }

  /// Clean up resources
  void dispose() {
    // Analytics doesn't need explicit disposal
  }
}

// Extension for PackageInfo
extension PackageInfoExtension on PackageInfo {
  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'packageName': packageName,
      'version': version,
      'buildNumber': buildNumber,
      'buildSignature': buildSignature,
    };
  }
}