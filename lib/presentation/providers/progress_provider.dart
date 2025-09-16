import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/analytics_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/learning_progress.dart';
import '../../data/models/achievement.dart';

enum ProgressState {
  idle,
  loading,
  loaded,
  error
}

class ProgressProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  // State
  ProgressState _state = ProgressState.idle;
  UserModel? _currentUser;
  Map<String, LearningProgress> _progressMap = {};
  List<Achievement> _allAchievements = [];
  List<Achievement> _unlockedAchievements = [];
  Map<String, double> _categoryProgress = {};
  Map<String, int> _weeklyActivity = {};

  // Statistics
  int _totalXP = 0;
  int _currentLevel = 1;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalTimeSpent = 0;
  int _commandsLearned = 0;
  int _perfectScores = 0;
  double _averageScore = 0.0;

  String? _errorMessage;
  bool _isInitialized = false;

  // Getters
  ProgressState get state => _state;
  UserModel? get currentUser => _currentUser;
  Map<String, LearningProgress> get progressMap => Map.unmodifiable(_progressMap);
  List<Achievement> get allAchievements => List.unmodifiable(_allAchievements);
  List<Achievement> get unlockedAchievements => List.unmodifiable(_unlockedAchievements);
  Map<String, double> get categoryProgress => Map.unmodifiable(_categoryProgress);
  Map<String, int> get weeklyActivity => Map.unmodifiable(_weeklyActivity);

  // Statistics getters
  int get totalXP => _totalXP;
  int get currentLevel => _currentLevel;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get totalTimeSpent => _totalTimeSpent;
  int get commandsLearned => _commandsLearned;
  int get perfectScores => _perfectScores;
  double get averageScore => _averageScore;

  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  /// Initialize progress provider
  Future<void> initialize(String? userId) async {
    try {
      _setState(ProgressState.loading);

      if (userId != null) {
        await _loadUserProgress(userId);
        await _loadAchievements();
        await _calculateStatistics();
        await _checkForNewAchievements();
      } else {
        await _loadAchievements();
      }

      _isInitialized = true;
      _setState(ProgressState.loaded);

    } catch (e) {
      _setError('Failed to initialize progress: ${e.toString()}');
    }
  }

  /// Update current user
  void updateUser(UserModel? user) {
    _currentUser = user;
    if (user != null && !_isInitialized) {
      initialize(user.id);
    } else if (user != null) {
      _loadUserProgress(user.id);
    }
    notifyListeners();
  }

  /// Load user progress from Firebase
  Future<void> _loadUserProgress(String userId) async {
    try {
      _progressMap.clear();

      // This would typically query Firestore for user's progress
      // For now, we'll simulate some data

      // Update statistics based on loaded progress
      _updateStatisticsFromProgress();

    } catch (e) {
      print('Error loading user progress: $e');
    }
  }

  /// Load achievements
  Future<void> _loadAchievements() async {
    try {
      // Load from cache first
      await _loadAchievementsFromCache();

      // Create default achievements if empty
      if (_allAchievements.isEmpty) {
        _allAchievements = AchievementFactory.createDefaultAchievements();
        await _cacheAchievements();
      }

      // Load user's unlocked achievements
      if (_currentUser != null) {
        await _loadUnlockedAchievements(_currentUser!.id);
      }

    } catch (e) {
      print('Error loading achievements: $e');
      _allAchievements = AchievementFactory.createDefaultAchievements();
    }
  }

  /// Load achievements from cache
  Future<void> _loadAchievementsFromCache() async {
    try {
      final box = await Hive.openBox<Achievement>('achievements');
      _allAchievements = box.values.toList();
    } catch (e) {
      print('Error loading achievements from cache: $e');
    }
  }

  /// Cache achievements
  Future<void> _cacheAchievements() async {
    try {
      final box = await Hive.openBox<Achievement>('achievements');
      await box.clear();
      for (final achievement in _allAchievements) {
        await box.put(achievement.id, achievement);
      }
    } catch (e) {
      print('Error caching achievements: $e');
    }
  }

  /// Load unlocked achievements
  Future<void> _loadUnlockedAchievements(String userId) async {
    try {
      final stream = _firebaseService.getUserAchievements(userId);
      stream.listen((snapshot) {
        final achievements = snapshot.docs
            .map((doc) => Achievement.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        _unlockedAchievements = achievements;
        notifyListeners();
      });
    } catch (e) {
      print('Error loading unlocked achievements: $e');
    }
  }

  /// Update statistics from progress data
  void _updateStatisticsFromProgress() {
    _commandsLearned = _progressMap.values.where((p) => p.isCompleted).length;
    _totalTimeSpent = _progressMap.values.fold(0, (sum, p) => sum + p.timeSpentSeconds);
    _perfectScores = _progressMap.values.fold(0, (sum, p) =>
    sum + p.sessions.where((s) => s.scorePercentage >= 100.0).length);

    // Calculate average score
    final allScores = _progressMap.values
        .expand((p) => p.sessions.map((s) => s.scorePercentage))
        .toList();
    _averageScore = allScores.isNotEmpty
        ? allScores.reduce((a, b) => a + b) / allScores.length
        : 0.0;

    // Calculate XP and level
    _totalXP = _calculateTotalXP();
    _currentLevel = _calculateLevel(_totalXP);

    // Calculate streaks
    _calculateStreaks();

    // Calculate category progress
    _calculateCategoryProgress();

    // Calculate weekly activity
    _calculateWeeklyActivity();
  }

  /// Calculate total XP
  int _calculateTotalXP() {
    int xp = 0;

    for (final progress in _progressMap.values) {
      // XP for completion
      if (progress.isCompleted) {
        xp += 100;
      }

      // Bonus XP for high scores
      for (final session in progress.sessions) {
        if (session.scorePercentage >= 90) {
          xp += 50;
        } else if (session.scorePercentage >= 80) {
          xp += 25;
        } else if (session.scorePercentage >= 70) {
          xp += 10;
        }
      }

      // Bonus XP for perfect scores
      xp += progress.sessions.where((s) => s.scorePercentage >= 100.0).length * 25;
    }

    // XP from achievements
    xp += _unlockedAchievements.fold(0, (sum, achievement) => sum + achievement.points);

    return xp;
  }

  /// Calculate level from XP
  int _calculateLevel(int xp) {
    // Level calculation: every 500 XP = 1 level
    return (xp / 500).floor() + 1;
  }

  /// Calculate streaks
  void _calculateStreaks() {
    if (_progressMap.isEmpty) {
      _currentStreak = 0;
      _longestStreak = 0;
      return;
    }

    // Sort progress by last attempt date
    final sortedProgress = _progressMap.values
        .where((p) => p.sessions.isNotEmpty)
        .toList()
      ..sort((a, b) => b.lastAttemptAt.compareTo(a.lastAttemptAt));

    if (sortedProgress.isEmpty) {
      _currentStreak = 0;
      _longestStreak = 0;
      return;
    }

    // Calculate current streak
    _currentStreak = _calculateCurrentStreak(sortedProgress);

    // Calculate longest streak
    _longestStreak = _calculateLongestStreak(sortedProgress);
  }

  /// Calculate current streak
  int _calculateCurrentStreak(List<LearningProgress> sortedProgress) {
    final now = DateTime.now();
    int streak = 0;

    for (final progress in sortedProgress) {
      final daysDiff = now.difference(progress.lastAttemptAt).inDays;

      if (daysDiff <= 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calculate longest streak
  int _calculateLongestStreak(List<LearningProgress> sortedProgress) {
    if (sortedProgress.isEmpty) return 0;

    // Group by days and find longest consecutive sequence
    final activityDays = <DateTime>{};

    for (final progress in sortedProgress) {
      for (final session in progress.sessions) {
        final day = DateTime(
          session.startTime.year,
          session.startTime.month,
          session.startTime.day,
        );
        activityDays.add(day);
      }
    }

    final sortedDays = activityDays.toList()..sort();
    if (sortedDays.isEmpty) return 0;

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDays.length; i++) {
      final diff = sortedDays[i].difference(sortedDays[i - 1]).inDays;

      if (diff == 1) {
        currentStreak++;
        maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
      } else {
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  /// Calculate category progress
  void _calculateCategoryProgress() {
    _categoryProgress.clear();

    // Group progress by category (would need command data)
    final categories = <String, List<LearningProgress>>{};

    for (final progress in _progressMap.values) {
      // This would get category from command data
      final category = 'general'; // Placeholder
      categories.putIfAbsent(category, () => []).add(progress);
    }

    for (final entry in categories.entries) {
      final completed = entry.value.where((p) => p.isCompleted).length;
      final total = entry.value.length;
      _categoryProgress[entry.key] = total > 0 ? (completed / total) * 100 : 0.0;
    }
  }

  /// Calculate weekly activity
  void _calculateWeeklyActivity() {
    _weeklyActivity.clear();
    final now = DateTime.now();

    // Last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      int activityCount = 0;
      for (final progress in _progressMap.values) {
        activityCount += progress.sessions
            .where((session) => _isSameDay(session.startTime, date))
            .length;
      }

      _weeklyActivity[dateKey] = activityCount;
    }
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Calculate overall statistics
  Future<void> _calculateStatistics() async {
    _updateStatisticsFromProgress();
    notifyListeners();
  }

  /// Check for new achievements
  Future<void> _checkForNewAchievements() async {
    if (_currentUser == null) return;

    try {
      final userStats = _getUserStatsForAchievements();
      final newAchievements = <Achievement>[];

      for (final achievement in _allAchievements) {
        // Skip already unlocked achievements
        if (_unlockedAchievements.any((a) => a.id == achievement.id)) continue;

        // Check if achievement requirements are met
        if (achievement.checkRequirements(userStats)) {
          final unlockedAchievement = achievement.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
            progress: 1.0,
          );

          newAchievements.add(unlockedAchievement);

          // Save to Firebase
          await _firebaseService.saveAchievement(
            _currentUser!.id,
            unlockedAchievement.toMap(),
          );

          // Log analytics
          await _analyticsService.logAchievementUnlock(
            achievementId: achievement.id,
            achievementName: achievement.title,
            achievementType: achievement.type.toString().split('.').last,
            points: achievement.points,
          );
        }
      }

      // Add new achievements to unlocked list
      _unlockedAchievements.addAll(newAchievements);

      if (newAchievements.isNotEmpty) {
        notifyListeners();

        // Notify about new achievements (could trigger UI celebrations)
        for (final achievement in newAchievements) {
          _onAchievementUnlocked(achievement);
        }
      }

    } catch (e) {
      print('Error checking for achievements: $e');
    }
  }

  /// Get user stats for achievement checking
  Map<String, dynamic> _getUserStatsForAchievements() {
    return {
      'commandsLearned': _commandsLearned,
      'perfectScores': _perfectScores,
      'longestStreak': _longestStreak,
      'totalTimeSpentHours': _totalTimeSpent / 3600.0,
      'totalSessions': _progressMap.values.fold(0, (sum, p) => sum + p.totalSessions),
      'averageScore': _averageScore,
      'totalXP': _totalXP,
      'currentLevel': _currentLevel,
    };
  }

  /// Handle achievement unlocked
  void _onAchievementUnlocked(Achievement achievement) {
    // This could trigger notifications, sounds, animations, etc.
    print('Achievement unlocked: ${achievement.title}');
  }

  /// Add XP
  Future<void> addXP(int xp, String reason) async {
    _totalXP += xp;
    final oldLevel = _currentLevel;
    _currentLevel = _calculateLevel(_totalXP);

    // Check for level up
    if (_currentLevel > oldLevel) {
      await _onLevelUp(oldLevel, _currentLevel);
    }

    // Update user model if available
    if (_currentUser != null) {
      // This would update the user's XP in Firebase
    }

    await _checkForNewAchievements();
    notifyListeners();
  }

  /// Handle level up
  Future<void> _onLevelUp(int oldLevel, int newLevel) async {
    // Log analytics
    await _analyticsService.logLevelUp(
      newLevel: newLevel,
      xpEarned: _totalXP - (oldLevel - 1) * 500,
      totalXp: _totalXP,
    );

    print('Level up! From $oldLevel to $newLevel');
  }

  /// Update progress for command
  Future<void> updateCommandProgress(String commandId, LearningProgress progress) async {
    _progressMap[commandId] = progress;
    await _calculateStatistics();
    await _checkForNewAchievements();
    notifyListeners();
  }

  /// Get progress for command
  LearningProgress? getProgressForCommand(String commandId) {
    return _progressMap[commandId];
  }

  /// Get recent activity
  List<LearningProgress> getRecentActivity({int limit = 10}) {
    final recentProgress = _progressMap.values
        .where((p) => p.sessions.isNotEmpty)
        .toList()
      ..sort((a, b) => b.lastAttemptAt.compareTo(a.lastAttemptAt));

    return recentProgress.take(limit).toList();
  }

  /// Get achievement by ID
  Achievement? getAchievementById(String id) {
    try {
      return _allAchievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get achievements by type
  List<Achievement> getAchievementsByType(AchievementType type) {
    return _allAchievements.where((a) => a.type == type).toList();
  }

  /// Get unlocked achievements by type
  List<Achievement> getUnlockedAchievementsByType(AchievementType type) {
    return _unlockedAchievements.where((a) => a.type == type).toList();
  }

  /// Check if achievement is unlocked
  bool isAchievementUnlocked(String achievementId) {
    return _unlockedAchievements.any((a) => a.id == achievementId);
  }

  /// Get completion percentage for category
  double getCategoryCompletion(String category) {
    return _categoryProgress[category] ?? 0.0;
  }

  /// Get XP needed for next level
  int get xpNeededForNextLevel {
    final currentLevelXP = (_currentLevel - 1) * 500;
    final nextLevelXP = _currentLevel * 500;
    return nextLevelXP - _totalXP;
  }

  /// Get level progress percentage
  double get levelProgressPercentage {
    final currentLevelXP = (_currentLevel - 1) * 500;
    final nextLevelXP = _currentLevel * 500;
    final progressInLevel = _totalXP - currentLevelXP;
    final levelXPRange = nextLevelXP - currentLevelXP;

    return levelXPRange > 0 ? (progressInLevel / levelXPRange) * 100 : 100.0;
  }

  /// Get user rank/title
  String get userRank {
    if (_currentLevel <= 5) return 'มือใหม่';
    if (_currentLevel <= 10) return 'ผู้เรียนรู้';
    if (_currentLevel <= 20) return 'ผู้ใช้งาน';
    if (_currentLevel <= 35) return 'ผู้เชี่ยวชาญ';
    if (_currentLevel <= 50) return 'ผู้ช่วยสอน';
    return 'เซียนลีนุกซ์';
  }

  /// Get learning summary
  Map<String, dynamic> getLearningSummary() {
    return {
      'totalXP': _totalXP,
      'currentLevel': _currentLevel,
      'userRank': userRank,
      'commandsLearned': _commandsLearned,
      'totalTimeSpent': _totalTimeSpent,
      'currentStreak': _currentStreak,
      'longestStreak': _longestStreak,
      'perfectScores': _perfectScores,
      'averageScore': _averageScore,
      'achievementsUnlocked': _unlockedAchievements.length,
      'totalAchievements': _allAchievements.length,
      'levelProgress': levelProgressPercentage,
      'xpNeededForNextLevel': xpNeededForNextLevel,
    };
  }

  /// Export progress data
  Map<String, dynamic> exportProgressData() {
    return {
      'user': _currentUser?.toMap(),
      'progress': _progressMap.map((key, value) => MapEntry(key, value.toMap())),
      'achievements': _unlockedAchievements.map((a) => a.toMap()).toList(),
      'statistics': getLearningSummary(),
      'categoryProgress': _categoryProgress,
      'weeklyActivity': _weeklyActivity,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// State management
  void _setState(ProgressState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(ProgressState.error);
  }

  void clearError() {
    _errorMessage = null;
    if (_state == ProgressState.error) {
      _setState(ProgressState.loaded);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}