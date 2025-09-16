import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

class SharedPrefsDatasource {
  late SharedPreferences _prefs;

  // Singleton pattern
  static final SharedPrefsDatasource _instance = SharedPrefsDatasource._internal();
  factory SharedPrefsDatasource() => _instance;
  SharedPrefsDatasource._internal();

  // Initialize SharedPreferences
  static Future<void> initialize() async {
    final instance = SharedPrefsDatasource._instance;
    instance._prefs = await SharedPreferences.getInstance();
  }

  // User Preferences Management
  Future<bool> setUserPreference<T>(String key, T value) async {
    try {
      switch (T) {
        case String:
          return await _prefs.setString(key, value as String);
        case int:
          return await _prefs.setInt(key, value as int);
        case double:
          return await _prefs.setDouble(key, value as double);
        case bool:
          return await _prefs.setBool(key, value as bool);
        case const (List<String>):
          return await _prefs.setStringList(key, value as List<String>);
        default:
        // For complex objects, serialize to JSON
          final jsonString = jsonEncode(value);
          return await _prefs.setString(key, jsonString);
      }
    } catch (error) {
      throw Exception('Failed to save preference: $error');
    }
  }

  T? getUserPreference<T>(String key, {T? defaultValue}) {
    try {
      switch (T) {
        case String:
          return _prefs.getString(key) as T? ?? defaultValue;
        case int:
          return _prefs.getInt(key) as T? ?? defaultValue;
        case double:
          return _prefs.getDouble(key) as T? ?? defaultValue;
        case bool:
          return _prefs.getBool(key) as T? ?? defaultValue;
        case const (List<String>):
          return _prefs.getStringList(key) as T? ?? defaultValue;
        default:
        // For complex objects, deserialize from JSON
          final jsonString = _prefs.getString(key);
          if (jsonString != null) {
            try {
              return jsonDecode(jsonString) as T?;
            } catch (e) {
              return defaultValue;
            }
          }
          return defaultValue;
      }
    } catch (error) {
      return defaultValue;
    }
  }

  Future<bool> removeUserPreference(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (error) {
      throw Exception('Failed to remove preference: $error');
    }
  }

  // App Settings Management
  Future<bool> setDarkMode(bool isDark) async {
    return await setUserPreference(AppConstants.isDarkModeKey, isDark);
  }

  bool getDarkMode() {
    return getUserPreference<bool>(AppConstants.isDarkModeKey, defaultValue: false) ?? false;
  }

  Future<bool> setLanguage(String languageCode) async {
    return await setUserPreference(AppConstants.languageKey, languageCode);
  }

  String getLanguage() {
    return getUserPreference<String>(AppConstants.languageKey, defaultValue: 'th') ?? 'th';
  }

  Future<bool> setTextSize(String textSize) async {
    return await setUserPreference(AppConstants.textSizeKey, textSize);
  }

  String getTextSize() {
    return getUserPreference<String>(AppConstants.textSizeKey, defaultValue: 'medium') ?? 'medium';
  }

  Future<bool> setVoiceEnabled(bool enabled) async {
    return await setUserPreference(AppConstants.voiceEnabledKey, enabled);
  }

  bool getVoiceEnabled() {
    return getUserPreference<bool>(AppConstants.voiceEnabledKey, defaultValue: false) ?? false;
  }

  Future<bool> setSoundEnabled(bool enabled) async {
    return await setUserPreference(AppConstants.soundEnabledKey, enabled);
  }

  bool getSoundEnabled() {
    return getUserPreference<bool>(AppConstants.soundEnabledKey, defaultValue: true) ?? true;
  }

  // First Time Setup
  Future<bool> setFirstTimeUser(bool isFirstTime) async {
    return await setUserPreference('is_first_time_user', isFirstTime);
  }

  bool isFirstTimeUser() {
    return getUserPreference<bool>('is_first_time_user', defaultValue: true) ?? true;
  }

  Future<bool> setOnboardingCompleted(bool completed) async {
    return await setUserPreference('onboarding_completed', completed);
  }

  bool isOnboardingCompleted() {
    return getUserPreference<bool>('onboarding_completed', defaultValue: false) ?? false;
  }

  // User Session Management
  Future<bool> setCurrentUserId(String userId) async {
    return await setUserPreference('current_user_id', userId);
  }

  String? getCurrentUserId() {
    return getUserPreference<String>('current_user_id');
  }

  Future<bool> setLastLoginTime(DateTime loginTime) async {
    return await setUserPreference('last_login_time', loginTime.toIso8601String());
  }

  DateTime? getLastLoginTime() {
    final timeString = getUserPreference<String>('last_login_time');
    if (timeString != null) {
      try {
        return DateTime.parse(timeString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // App Usage Statistics
  Future<bool> incrementAppOpenCount() async {
    final currentCount = getAppOpenCount();
    return await setUserPreference('app_open_count', currentCount + 1);
  }

  int getAppOpenCount() {
    return getUserPreference<int>('app_open_count', defaultValue: 0) ?? 0;
  }

  Future<bool> setTotalAppUsageTime(Duration duration) async {
    return await setUserPreference('total_app_usage_time', duration.inMinutes);
  }

  Duration getTotalAppUsageTime() {
    final minutes = getUserPreference<int>('total_app_usage_time', defaultValue: 0) ?? 0;
    return Duration(minutes: minutes);
  }

  Future<bool> addSessionTime(Duration sessionDuration) async {
    final currentTotal = getTotalAppUsageTime();
    final newTotal = currentTotal + sessionDuration;
    return await setTotalAppUsageTime(newTotal);
  }

  // Learning Preferences
  Future<bool> setPreferredDifficulty(String difficulty) async {
    return await setUserPreference('preferred_difficulty', difficulty);
  }

  String getPreferredDifficulty() {
    return getUserPreference<String>('preferred_difficulty', defaultValue: 'beginner') ?? 'beginner';
  }

  Future<bool> setPreferredCategories(List<String> categories) async {
    return await setUserPreference('preferred_categories', categories);
  }

  List<String> getPreferredCategories() {
    return getUserPreference<List<String>>('preferred_categories', defaultValue: []) ?? [];
  }

  Future<bool> setDailyGoal(int goal) async {
    return await setUserPreference('daily_goal', goal);
  }

  int getDailyGoal() {
    return getUserPreference<int>('daily_goal', defaultValue: 10) ?? 10;
  }

  // Notification Settings
  Future<bool> setNotificationsEnabled(bool enabled) async {
    return await setUserPreference('notifications_enabled', enabled);
  }

  bool getNotificationsEnabled() {
    return getUserPreference<bool>('notifications_enabled', defaultValue: true) ?? true;
  }

  Future<bool> setDailyReminderTime(String time) async {
    return await setUserPreference('daily_reminder_time', time);
  }

  String getDailyReminderTime() {
    return getUserPreference<String>('daily_reminder_time', defaultValue: '19:00') ?? '19:00';
  }

  Future<bool> setStreakReminderEnabled(bool enabled) async {
    return await setUserPreference('streak_reminder_enabled', enabled);
  }

  bool getStreakReminderEnabled() {
    return getUserPreference<bool>('streak_reminder_enabled', defaultValue: true) ?? true;
  }

  // Achievement Notifications
  Future<bool> setAchievementNotificationsEnabled(bool enabled) async {
    return await setUserPreference('achievement_notifications_enabled', enabled);
  }

  bool getAchievementNotificationsEnabled() {
    return getUserPreference<bool>('achievement_notifications_enabled', defaultValue: true) ?? true;
  }

  // Cache Management
  Future<bool> setCacheExpiryTime(String key, DateTime expiryTime) async {
    return await setUserPreference('cache_expiry_$key', expiryTime.toIso8601String());
  }

  DateTime? getCacheExpiryTime(String key) {
    final timeString = getUserPreference<String>('cache_expiry_$key');
    if (timeString != null) {
      try {
        return DateTime.parse(timeString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  bool isCacheExpired(String key) {
    final expiryTime = getCacheExpiryTime(key);
    if (expiryTime == null) return true;
    return DateTime.now().isAfter(expiryTime);
  }

  Future<bool> clearExpiredCache() async {
    try {
      final keys = _prefs.getKeys().where((key) => key.startsWith('cache_expiry_')).toList();

      for (final key in keys) {
        final cacheKey = key.replaceFirst('cache_expiry_', '');
        if (isCacheExpired(cacheKey)) {
          await _prefs.remove(key);
          await _prefs.remove(cacheKey);
        }
      }
      return true;
    } catch (error) {
      return false;
    }
  }

  // Performance Tracking
  Future<bool> setAverageResponseTime(double responseTime) async {
    return await setUserPreference('average_response_time', responseTime);
  }

  double getAverageResponseTime() {
    return getUserPreference<double>('average_response_time', defaultValue: 0.0) ?? 0.0;
  }

  Future<bool> updateAverageResponseTime(double newResponseTime) async {
    final currentAvg = getAverageResponseTime();
    final sessionCount = getAppOpenCount();

    double updatedAvg;
    if (sessionCount <= 1) {
      updatedAvg = newResponseTime;
    } else {
      updatedAvg = ((currentAvg * (sessionCount - 1)) + newResponseTime) / sessionCount;
    }

    return await setAverageResponseTime(updatedAvg);
  }

  // Error Reporting Settings
  Future<bool> setCrashReportingEnabled(bool enabled) async {
    return await setUserPreference('crash_reporting_enabled', enabled);
  }

  bool getCrashReportingEnabled() {
    return getUserPreference<bool>('crash_reporting_enabled', defaultValue: true) ?? true;
  }

  Future<bool> setAnalyticsEnabled(bool enabled) async {
    return await setUserPreference('analytics_enabled', enabled);
  }

  bool getAnalyticsEnabled() {
    return getUserPreference<bool>('analytics_enabled', defaultValue: true) ?? true;
  }

  // Backup and Sync Settings
  Future<bool> setAutoBackupEnabled(bool enabled) async {
    return await setUserPreference('auto_backup_enabled', enabled);
  }

  bool getAutoBackupEnabled() {
    return getUserPreference<bool>('auto_backup_enabled', defaultValue: false) ?? false;
  }

  Future<bool> setLastBackupTime(DateTime backupTime) async {
    return await setUserPreference('last_backup_time', backupTime.toIso8601String());
  }

  DateTime? getLastBackupTime() {
    final timeString = getUserPreference<String>('last_backup_time');
    if (timeString != null) {
      try {
        return DateTime.parse(timeString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Feature Flags
  Future<bool> setFeatureFlag(String featureName, bool enabled) async {
    return await setUserPreference('feature_$featureName', enabled);
  }

  bool getFeatureFlag(String featureName, {bool defaultValue = false}) {
    return getUserPreference<bool>('feature_$featureName', defaultValue: defaultValue) ?? defaultValue;
  }

  // Tutorial Progress
  Future<bool> setTutorialCompleted(String tutorialName, bool completed) async {
    return await setUserPreference('tutorial_${tutorialName}_completed', completed);
  }

  bool isTutorialCompleted(String tutorialName) {
    return getUserPreference<bool>('tutorial_${tutorialName}_completed', defaultValue: false) ?? false;
  }

  Future<bool> setTutorialStep(String tutorialName, int step) async {
    return await setUserPreference('tutorial_${tutorialName}_step', step);
  }

  int getTutorialStep(String tutorialName) {
    return getUserPreference<int>('tutorial_${tutorialName}_step', defaultValue: 0) ?? 0;
  }

  // App Rating
  Future<bool> setAppRated(bool rated) async {
    return await setUserPreference('app_rated', rated);
  }

  bool isAppRated() {
    return getUserPreference<bool>('app_rated', defaultValue: false) ?? false;
  }

  Future<bool> setRatingPromptShown(bool shown) async {
    return await setUserPreference('rating_prompt_shown', shown);
  }

  bool isRatingPromptShown() {
    return getUserPreference<bool>('rating_prompt_shown', defaultValue: false) ?? false;
  }

  Future<bool> incrementRatingPromptCount() async {
    final currentCount = getRatingPromptCount();
    return await setUserPreference('rating_prompt_count', currentCount + 1);
  }

  int getRatingPromptCount() {
    return getUserPreference<int>('rating_prompt_count', defaultValue: 0) ?? 0;
  }

  // Accessibility Settings
  Future<bool> setHighContrastMode(bool enabled) async {
    return await setUserPreference('high_contrast_mode', enabled);
  }

  bool getHighContrastMode() {
    return getUserPreference<bool>('high_contrast_mode', defaultValue: false) ?? false;
  }

  Future<bool> setScreenReaderEnabled(bool enabled) async {
    return await setUserPreference('screen_reader_enabled', enabled);
  }

  bool getScreenReaderEnabled() {
    return getUserPreferences<bool>('screen_reader_enabled', defaultValue: false) ?? false;
  }

  Future<bool> setReduceAnimations(bool enabled) async {
    return await setUserPreference('reduce_animations', enabled);
  }

  bool getReduceAnimations() {
    return getUserPreference<bool>('reduce_animations', defaultValue: false) ?? false;
  }

  // Utility Methods
  Future<bool> clearAllPreferences() async {
    try {
      return await _prefs.clear();
    } catch (error) {
      throw Exception('Failed to clear all preferences: $error');
    }
  }

  Future<bool> clearUserSpecificData() async {
    try {
      final keys = _prefs.getKeys().where((key) =>
      key.startsWith('current_user_') ||
          key.startsWith('user_') ||
          key.contains('session') ||
          key.contains('cache_')
      ).toList();

      for (final key in keys) {
        await _prefs.remove(key);
      }
      return true;
    } catch (error) {
      return false;
    }
  }

  Map<String, dynamic> getAllPreferences() {
    try {
      final Map<String, dynamic> allPrefs = {};
      final keys = _prefs.getKeys();

      for (final key in keys) {
        final value = _prefs.get(key);
        allPrefs[key] = value;
      }

      return allPrefs;
    } catch (error) {
      return {};
    }
  }

  // Export preferences for backup
  Map<String, dynamic> exportPreferences() {
    final allPrefs = getAllPreferences();
    return {
      'preferences': allPrefs,
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0', // Should get from package info
    };
  }

  // Import preferences from backup
  Future<bool> importPreferences(Map<String, dynamic> backup) async {
    try {
      final preferences = backup['preferences'] as Map<String, dynamic>?;
      if (preferences == null) return false;

      // Clear existing preferences first
      await clearAllPreferences();

      // Import new preferences
      for (final entry in preferences.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is String) {
          await _prefs.setString(key, value);
        } else if (value is int) {
          await _prefs.setInt(key, value);
        } else if (value is double) {
          await _prefs.setDouble(key, value);
        } else if (value is bool) {
          await _prefs.setBool(key, value);
        } else if (value is List<String>) {
          await _prefs.setStringList(key, value);
        }
      }

      return true;
    } catch (error) {
      throw Exception('Failed to import preferences: $error');
    }
  }

  // Get storage usage information
  Map<String, dynamic> getStorageInfo() {
    final allPrefs = getAllPreferences();
    int totalKeys = allPrefs.length;
    int estimatedSize = 0;

    // Estimate storage size (rough calculation)
    for (final entry in allPrefs.entries) {
      estimatedSize += entry.key.length;
      if (entry.value is String) {
        estimatedSize += (entry.value as String).length;
      } else {
        estimatedSize += entry.value.toString().length;
      }
    }

    return {
      'totalKeys': totalKeys,
      'estimatedSizeBytes': estimatedSize,
      'estimatedSizeKB': (estimatedSize / 1024).toStringAsFixed(2),
    };
  }

  // Fix typo in method name
  T? getUserPreferences<T>(String key, {T? defaultValue}) {
    return getUserPreference<T>(key, defaultValue: defaultValue);
  }
}