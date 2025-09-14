import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import '../constants/firebase_constants.dart';

class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _isEnabled = true;
  bool _isInitialized = false;

  FirebaseAnalytics? get analytics => _analytics;
  bool get isEnabled => _isEnabled;
  bool get isInitialized => _isInitialized;

  // Initialize Firebase Analytics
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
      _isInitialized = true;

      // Set default event parameters
      await _setDefaultEventParameters();

      debugPrint('Analytics service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Analytics service: $e');
    }
  }

  // Set default event parameters
  Future<void> _setDefaultEventParameters() async {
    if (!_isEnabled || _analytics == null) return;

    try {
      await _analytics!.setDefaultEventParameters({
        'app_version': '1.0.0',
        'platform': defaultTargetPlatform.name,
        'language': 'th',
      });
    } catch (e) {
      debugPrint('Error setting default event parameters: $e');
    }
  }

  // Enable/disable analytics
  Future<void> setAnalyticsEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (_analytics != null) {
      await _analytics!.setAnalyticsCollectionEnabled(enabled);
    }
  }

  // Set user ID
  Future<void> setUserId(String? userId) async {
    if (!_isEnabled || _analytics == null) return;

    try {
      await _analytics!.setUserId(id: userId);
    } catch (e) {
      debugPrint('Error setting user ID: $e');
    }
  }

  // Set user properties
  Future<void> setUserProperty(String name, String? value) async {
    if (!_isEnabled || _analytics == null) return;

    try {
      await _analytics!.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Error setting user property: $e');
    }
  }

  // Set multiple user properties
  Future<void> setUserProperties(Map<String, String?> properties) async {
    for (final entry in properties.entries) {
      await setUserProperty(entry.key, entry.value);
    }
  }

  // Log custom event
  Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    if (!_isEnabled || _analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );

      if (kDebugMode) {
        debugPrint('Analytics Event: $name with parameters: $parameters');
      }
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  // Screen tracking
  Future<void> logScreenView(String screenName, [String? screenClass]) async {
    if (!_isEnabled || _analytics == null) return;

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  // User authentication events
  Future<void> logSignUp(String method) async {
    await logEvent(AnalyticsEvent.signUp, {
      'method': method,
    });
  }

  Future<void> logSignIn(String method) async {
    await logEvent(AnalyticsEvent.login, {
      'method': method,
    });
  }

  Future<void> logSignOut() async {
    await logEvent('sign_out');
  }

  // Learning events
  Future<void> logLessonStarted({
    required String lessonId,
    required String category,
    required String difficulty,
  }) async {
    await logEvent(FirebaseConstants.eventLessonStarted, {
      'lesson_id': lessonId,
      'category': category,
      'difficulty': difficulty,
    });
  }

  Future<void> logLessonCompleted({
    required String lessonId,
    required String category,
    required String difficulty,
    required int completionTime,
    required double accuracy,
    required int xpEarned,
  }) async {
    await logEvent(FirebaseConstants.eventLessonCompleted, {
      'lesson_id': lessonId,
      'category': category,
      'difficulty': difficulty,
      'completion_time': completionTime,
      'accuracy': accuracy,
      'xp_earned': xpEarned,
    });
  }

  // Quiz events
  Future<void> logQuizStarted({
    required String quizId,
    required String category,
    required String difficulty,
  }) async {
    await logEvent(FirebaseConstants.eventQuizTaken, {
      'quiz_id': quizId,
      'category': category,
      'difficulty': difficulty,
      'action': 'started',
    });
  }

  Future<void> logQuizCompleted({
    required String quizId,
    required String category,
    required String difficulty,
    required int score,
    required int totalQuestions,
    required int completionTime,
  }) async {
    await logEvent(FirebaseConstants.eventQuizTaken, {
      'quiz_id': quizId,
      'category': category,
      'difficulty': difficulty,
      'action': 'completed',
      'score': score,
      'total_questions': totalQuestions,
      'completion_time': completionTime,
      'accuracy': score / totalQuestions,
    });
  }

  // Command events
  Future<void> logCommandExecuted({
    required String commandName,
    required String category,
    bool isSuccessful = true,
    String? errorType,
  }) async {
    await logEvent(FirebaseConstants.eventCommandExecuted, {
      'command_name': commandName,
      'category': category,
      'is_successful': isSuccessful,
      'error_type': errorType,
    });
  }

  Future<void> logCommandLearned({
    required String commandName,
    required String category,
    required String difficulty,
  }) async {
    await logEvent('command_learned', {
      'command_name': commandName,
      'category': category,
      'difficulty': difficulty,
    });
  }

  // Achievement events
  Future<void> logAchievementUnlocked({
    required String achievementId,
    required String achievementName,
    required String category,
    required int xpReward,
  }) async {
    await logEvent(FirebaseConstants.eventAchievementUnlocked, {
      'achievement_id': achievementId,
      'achievement_name': achievementName,
      'category': category,
      'xp_reward': xpReward,
    });
  }

  // Chat events
  Future<void> logChatMessageSent({
    required String messageType,
    required int messageLength,
    String? intent,
  }) async {
    await logEvent(FirebaseConstants.eventChatMessageSent, {
      'message_type': messageType,
      'message_length': messageLength,
      'intent': intent,
    });
  }

  Future<void> logVoiceInteraction({
    required String action, // 'started', 'completed', 'failed'
    int? duration,
    String? errorType,
  }) async {
    await logEvent(FirebaseConstants.eventVoiceUsed, {
      'action': action,
      'duration': duration,
      'error_type': errorType,
    });
  }

  // Terminal events
  Future<void> logTerminalUsed({
    required String commandType,
    required int sessionDuration,
    required int commandsExecuted,
  }) async {
    await logEvent(FirebaseConstants.eventTerminalUsed, {
      'command_type': commandType,
      'session_duration': sessionDuration,
      'commands_executed': commandsExecuted,
    });
  }

  // Learning path events
  Future<void> logLearningPathChanged({
    required String fromDifficulty,
    required String toDifficulty,
    required String reason,
  }) async {
    await logEvent(FirebaseConstants.eventLearningPathChanged, {
      'from_difficulty': fromDifficulty,
      'to_difficulty': toDifficulty,
      'reason': reason,
    });
  }

  // Progress events
  Future<void> logLevelUp({
    required int newLevel,
    required int totalXP,
    required String category,
  }) async {
    await logEvent('level_up', {
      'new_level': newLevel,
      'total_xp': totalXP,
      'category': category,
    });
  }

  Future<void> logStreakAchieved({
    required int streakDays,
    required String streakType,
  }) async {
    await logEvent('streak_achieved', {
      'streak_days': streakDays,
      'streak_type': streakType,
    });
  }

  // Feature usage events
  Future<void> logFeatureUsed({
    required String featureName,
    Map<String, dynamic>? additionalData,
  }) async {
    await logEvent('feature_used', {
      'feature_name': featureName,
      ...?additionalData,
    });
  }

  // Error events
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screen,
    String? action,
  }) async {
    await logEvent('app_error', {
      'error_type': errorType,
      'error_message': errorMessage,
      'screen': screen,
      'action': action,
    });
  }

  // Performance events
  Future<void> logPerformance({
    required String action,
    required int duration,
    Map<String, dynamic>? additionalData,
  }) async {
    await logEvent('performance', {
      'action': action,
      'duration': duration,
      ...?additionalData,
    });
  }

  // User engagement events
  Future<void> logSessionStart() async {
    await logEvent('session_start', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logSessionEnd({
    required int sessionDuration,
    required int screensViewed,
    required int actionsPerformed,
  }) async {
    await logEvent('session_end', {
      'session_duration': sessionDuration,
      'screens_viewed': screensViewed,
      'actions_performed': actionsPerformed,
    });
  }

  // Search events
  Future<void> logSearch({
    required String searchTerm,
    required String searchType,
    int? resultsCount,
  }) async {
    await logEvent(AnalyticsEvent.search, {
      'search_term': searchTerm,
      'search_type': searchType,
      'results_count': resultsCount,
    });
  }

  // Share events
  Future<void> logShare({
    required String contentType,
    required String contentId,
    required String method,
  }) async {
    await logEvent(AnalyticsEvent.share, {
      'content_type': contentType,
      'item_id': contentId,
      'method': method,
    });
  }

  // Purchase events (if premium features are added)
  Future<void> logPurchase({
    required String itemId,
    required String itemName,
    required double value,
    required String currency,
  }) async {
    await logEvent(AnalyticsEvent.purchase, {
      'item_id': itemId,
      'item_name': itemName,
      'value': value,
      'currency': currency,
    });
  }

  // Custom conversion events
  Future<void> logConversion({
    required String conversionType,
    required String conversionValue,
    Map<String, dynamic>? additionalData,
  }) async {
    await logEvent('conversion', {
      'conversion_type': conversionType,
      'conversion_value': conversionValue,
      ...?additionalData,
    });
  }
}

// Analytics event constants
class AnalyticsEvent {
  static const String signUp = 'sign_up';
  static const String login = 'login';
  static const String search = 'search';
  static const String share = 'share';
  static const String purchase = 'purchase';
  static const String selectContent = 'select_content';
  static const String viewItem = 'view_item';
  static const String addToCart = 'add_to_cart';
  static const String beginCheckout = 'begin_checkout';
}