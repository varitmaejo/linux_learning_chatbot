import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/entities/progress.dart';
import '../../models/user_model.dart';
import '../../models/chat_message.dart';
import '../../models/learning_progress.dart';
import '../../models/achievement.dart';

class HiveDatasource {
  static const String _userBoxName = AppConstants.userProfileBox;
  static const String _chatBoxName = AppConstants.chatHistoryBox;
  static const String _progressBoxName = AppConstants.learningProgressBox;
  static const String _settingsBoxName = AppConstants.settingsBox;
  static const String _achievementsBoxName = AppConstants.achievementsBox;

  // Lazy boxes for better performance
  late Box<UserModel> _userBox;
  late Box<List<dynamic>> _chatBox;
  late Box<LearningProgress> _progressBox;
  late Box<dynamic> _settingsBox;
  late Box<Achievement> _achievementsBox;

  // Singleton pattern
  static final HiveDatasource _instance = HiveDatasource._internal();
  factory HiveDatasource() => _instance;
  HiveDatasource._internal();

  // Initialize Hive and register adapters
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register type adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(LearningProgressAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AchievementAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(MessageTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(DifficultyLevelAdapter());
    }

    // Open boxes
    final instance = HiveDatasource._instance;
    await instance._openBoxes();
  }

  Future<void> _openBoxes() async {
    try {
      _userBox = await Hive.openBox<UserModel>(_userBoxName);
      _chatBox = await Hive.openBox<List<dynamic>>(_chatBoxName);
      _progressBox = await Hive.openBox<LearningProgress>(_progressBoxName);
      _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
      _achievementsBox = await Hive.openBox<Achievement>(_achievementsBoxName);
    } catch (error) {
      // Handle box opening errors
      throw Exception('Failed to initialize Hive boxes: $error');
    }
  }

  // User Management
  Future<UserModel?> getUser(String userId) async {
    try {
      return _userBox.get(userId);
    } catch (error) {
      throw Exception('Failed to get user: $error');
    }
  }

  Future<void> saveUser(UserModel user) async {
    try {
      await _userBox.put(user.id, user);
    } catch (error) {
      throw Exception('Failed to save user: $error');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _userBox.delete(userId);
      // Also clean up related data
      await _chatBox.delete(userId);
      await _progressBox.delete(userId);
    } catch (error) {
      throw Exception('Failed to delete user: $error');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      return _userBox.values.toList();
    } catch (error) {
      throw Exception('Failed to get all users: $error');
    }
  }

  // Chat History Management
  Future<List<Message>> getChatHistory(String userId) async {
    try {
      final rawMessages = _chatBox.get(userId, defaultValue: <dynamic>[]);
      if (rawMessages == null || rawMessages.isEmpty) return [];

      return rawMessages
          .cast<ChatMessage>()
          .map((chatMessage) => chatMessage as Message)
          .toList();
    } catch (error) {
      throw Exception('Failed to get chat history: $error');
    }
  }

  Future<void> saveChatHistory(String userId, List<Message> messages) async {
    try {
      final chatMessages = messages
          .map((message) => ChatMessage.fromEntity(message))
          .toList();
      await _chatBox.put(userId, chatMessages);
    } catch (error) {
      throw Exception('Failed to save chat history: $error');
    }
  }

  Future<void> addChatMessage(String userId, Message message) async {
    try {
      final currentHistory = await getChatHistory(userId);
      currentHistory.insert(0, message);

      // Keep only recent messages to avoid storage bloat
      final recentHistory = currentHistory.take(AppConstants.maxChatHistory).toList();
      await saveChatHistory(userId, recentHistory);
    } catch (error) {
      throw Exception('Failed to add chat message: $error');
    }
  }

  Future<void> clearChatHistory(String userId) async {
    try {
      await _chatBox.delete(userId);
    } catch (error) {
      throw Exception('Failed to clear chat history: $error');
    }
  }

  // Learning Progress Management
  Future<LearningProgress?> getProgress(String userId) async {
    try {
      return _progressBox.get(userId);
    } catch (error) {
      throw Exception('Failed to get progress: $error');
    }
  }

  Future<void> saveProgress(String userId, LearningProgress progress) async {
    try {
      await _progressBox.put(userId, progress);
    } catch (error) {
      throw Exception('Failed to save progress: $error');
    }
  }

  Future<void> updateProgress(String userId, Map<String, dynamic> updates) async {
    try {
      final currentProgress = await getProgress(userId);
      if (currentProgress != null) {
        // Update specific fields
        final updatedProgress = currentProgress.copyWith(
          lastUpdated: DateTime.now(),
          // Add other fields as needed based on updates map
        );
        await saveProgress(userId, updatedProgress);
      }
    } catch (error) {
      throw Exception('Failed to update progress: $error');
    }
  }

  // Settings Management
  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    try {
      return _settingsBox.get(key, defaultValue: defaultValue);
    } catch (error) {
      throw Exception('Failed to get setting: $error');
    }
  }

  Future<void> saveSetting<T>(String key, T value) async {
    try {
      await _settingsBox.put(key, value);
    } catch (error) {
      throw Exception('Failed to save setting: $error');
    }
  }

  Future<Map<String, dynamic>> getAllSettings() async {
    try {
      final Map<String, dynamic> settings = {};
      for (final key in _settingsBox.keys) {
        settings[key.toString()] = _settingsBox.get(key);
      }
      return settings;
    } catch (error) {
      throw Exception('Failed to get all settings: $error');
    }
  }

  Future<void> clearSettings() async {
    try {
      await _settingsBox.clear();
    } catch (error) {
      throw Exception('Failed to clear settings: $error');
    }
  }

  // Achievement Management
  Future<List<Achievement>> getAchievements(String userId) async {
    try {
      return _achievementsBox.values
          .where((achievement) => achievement.userId == userId)
          .toList();
    } catch (error) {
      throw Exception('Failed to get achievements: $error');
    }
  }

  Future<void> saveAchievement(Achievement achievement) async {
    try {
      final key = '${achievement.userId}_${achievement.id}';
      await _achievementsBox.put(key, achievement);
    } catch (error) {
      throw Exception('Failed to save achievement: $error');
    }
  }

  Future<void> unlockAchievement(String userId, String achievementId) async {
    try {
      final achievement = Achievement(
        id: achievementId,
        userId: userId,
        unlockedAt: DateTime.now(),
        isUnlocked: true,
      );
      await saveAchievement(achievement);
    } catch (error) {
      throw Exception('Failed to unlock achievement: $error');
    }
  }

  Future<bool> isAchievementUnlocked(String userId, String achievementId) async {
    try {
      final key = '${userId}_$achievementId';
      final achievement = _achievementsBox.get(key);
      return achievement?.isUnlocked ?? false;
    } catch (error) {
      return false;
    }
  }

  // Data Export/Import
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final user = await getUser(userId);
      final chatHistory = await getChatHistory(userId);
      final progress = await getProgress(userId);
      final achievements = await getAchievements(userId);

      return {
        'user': user?.toJson(),
        'chatHistory': chatHistory.map((m) => (m as ChatMessage).toJson()).toList(),
        'progress': progress?.toJson(),
        'achievements': achievements.map((a) => a.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (error) {
      throw Exception('Failed to export user data: $error');
    }
  }

  Future<void> importUserData(String userId, Map<String, dynamic> data) async {
    try {
      // Import user
      if (data['user'] != null) {
        final user = UserModel.fromJson(data['user']);
        await saveUser(user);
      }

      // Import chat history
      if (data['chatHistory'] != null) {
        final messages = (data['chatHistory'] as List)
            .map((json) => ChatMessage.fromJson(json))
            .cast<Message>()
            .toList();
        await saveChatHistory(userId, messages);
      }

      // Import progress
      if (data['progress'] != null) {
        final progress = LearningProgress.fromJson(data['progress']);
        await saveProgress(userId, progress);
      }

      // Import achievements
      if (data['achievements'] != null) {
        final achievements = (data['achievements'] as List)
            .map((json) => Achievement.fromJson(json))
            .toList();

        for (final achievement in achievements) {
          await saveAchievement(achievement);
        }
      }
    } catch (error) {
      throw Exception('Failed to import user data: $error');
    }
  }

  // Database Statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      return {
        'totalUsers': _userBox.length,
        'totalChatSessions': _chatBox.length,
        'totalProgress': _progressBox.length,
        'totalAchievements': _achievementsBox.length,
        'totalSettings': _settingsBox.length,
        'databaseSize': await _calculateDatabaseSize(),
      };
    } catch (error) {
      throw Exception('Failed to get database stats: $error');
    }
  }

  Future<int> _calculateDatabaseSize() async {
    // This is an approximation
    int totalSize = 0;
    totalSize += _userBox.length * 1024; // Approximate 1KB per user
    totalSize += _chatBox.length * 5120; // Approximate 5KB per chat session
    totalSize += _progressBox.length * 512; // Approximate 512B per progress
    totalSize += _achievementsBox.length * 256; // Approximate 256B per achievement
    totalSize += _settingsBox.length * 128; // Approximate 128B per setting
    return totalSize;
  }

  // Cleanup and Maintenance
  Future<void> cleanupOldData() async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: 90));

      // Clean up old chat messages
      final chatKeys = _chatBox.keys.toList();
      for (final key in chatKeys) {
        final messages = _chatBox.get(key);
        if (messages != null && messages.isNotEmpty) {
          final filteredMessages = messages
              .cast<ChatMessage>()
              .where((message) => message.timestamp.isAfter(cutoffDate))
              .toList();

          if (filteredMessages.length != messages.length) {
            await _chatBox.put(key, filteredMessages);
          }
        }
      }

      // Clean up inactive users (no activity for 6 months)
      final inactiveCutoff = DateTime.now().subtract(Duration(days: 180));
      final userKeys = _userBox.keys.toList();

      for (final key in userKeys) {
        final user = _userBox.get(key);
        if (user != null && user.lastLoginAt.isBefore(inactiveCutoff)) {
          await deleteUser(user.id);
        }
      }
    } catch (error) {
      throw Exception('Failed to cleanup old data: $error');
    }
  }

  Future<void> compactDatabase() async {
    try {
      await _userBox.compact();
      await _chatBox.compact();
      await _progressBox.compact();
      await _settingsBox.compact();
      await _achievementsBox.compact();
    } catch (error) {
      throw Exception('Failed to compact database: $error');
    }
  }

  // Close all boxes (call this when app is closing)
  Future<void> dispose() async {
    try {
      await _userBox.close();
      await _chatBox.close();
      await _progressBox.close();
      await _settingsBox.close();
      await _achievementsBox.close();
    } catch (error) {
      // Log error but don't throw, as this is cleanup code
      print('Error disposing Hive boxes: $error');
    }
  }

  // Backup functionality
  Future<void> createBackup(String backupPath) async {
    try {
      // This would typically involve copying the Hive database files
      // Implementation depends on platform-specific file operations
      throw UnimplementedError('Backup functionality not yet implemented');
    } catch (error) {
      throw Exception('Failed to create backup: $error');
    }
  }

  Future<void> restoreFromBackup(String backupPath) async {
    try {
      // This would typically involve restoring from backup files
      // Implementation depends on platform-specific file operations
      throw UnimplementedError('Restore functionality not yet implemented');
    } catch (error) {
      throw Exception('Failed to restore from backup: $error');
    }
  }
}