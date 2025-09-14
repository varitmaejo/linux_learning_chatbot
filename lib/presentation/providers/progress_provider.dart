import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/learning_progress.dart';
import '../models/achievement.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../constants/firebase_constants.dart';

class ProgressProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  // State variables
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _currentUserId;

  // User progress data
  UserModel? _currentUser;
  List<LearningProgress> _learningProgress = [];
  List<Achievement> _achievements = [];
  List<Achievement> _unlockedAchievements = [];

  // Statistics
  Map<String, double> _categoryProgress = {};
  Map<String, int> _categoryXP = {};
  List<Map<String, dynamic>> _dailyActivity = [];
  List<Map<String, dynamic>> _weeklyStats = [];
  List<Map<String, dynamic>> _monthlyStats = [];

  // Leaderboard
  List<Map<String, dynamic>> _leaderboard = [];
  int _userRanking = 0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  List<LearningProgress> get learningProgress => List.unmodifiable(_learningProgress);
  List<Achievement> get achievements => List.unmodifiable(_achievements);
  List<Achievement> get unlockedAchievements => List.unmodifiable(_unlockedAchievements);
  Map<String, double> get categoryProgress => Map.unmodifiable(_categoryProgress);
  Map<String, int> get categoryXP => Map.unmodifiable(_categoryXP);
  List<Map<String, dynamic>> get dailyActivity => List.unmodifiable(_dailyActivity);
  List<Map<String, dynamic>> get weeklyStats => List.unmodifiable(_weeklyStats);
  List<Map<String, dynamic>> get monthlyStats => List.unmodifiable(_monthlyStats);
  List<Map<String, dynamic>> get leaderboard => List.unmodifiable(_leaderboard);
  int get userRanking => _userRanking;

  // Initialize progress provider
  Future<void> initialize([String? userId]) async {
    if (_isInitialized && _currentUserId == userId) return;

    _isLoading = true;
    _currentUserId = userId;
    notifyListeners();

    try {
      if (_currentUserId != null) {
        await _loadUserData();
        await _loadLearningProgress();
        await _loadAchievements();
        await _calculateStatistics();
        await _loadLeaderboard();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing progress provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user data
  Future<void> _loadUserData() async {
    if (_currentUserId == null) return;

    try {
      _currentUser = await _firebaseService.getUserProfile(_currentUserId!);
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Load learning progress
  Future<void> _loadLearningProgress() async {
    if (_currentUserId == null) return;

    try {
      _learningProgress = await _firebaseService.getLearningProgress(_currentUserId!);
      _calculateCategoryProgress();
    } catch (e) {
      debugPrint('Error loading learning progress: $e');
    }
  }

  // Load achievements
  Future<void> _loadAchievements() async {
    if (_currentUserId == null) return;

    try {
      // Load all available achievements
      final allAchievements = await _firebaseService.firestore
          .collection(FirebaseConstants.achievementsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      _achievements = allAchievements.docs
          .map((doc) => Achievement.fromMap(doc.data()))
          .toList();

      // Load user's unlocked achievements
      final userAchievements = await _firebaseService.firestore
          .collection(FirebaseConstants.achievementsCollection)
          .where('userId', isEqualTo: _currentUserId)
          .where('isUnlocked', isEqualTo: true)
          .get();

      _unlockedAchievements = userAchievements.docs
          .map((doc) => Achievement.fromMap(doc.data()))
          .toList();

    } catch (e) {
      debugPrint('Error loading achievements: $e');
      _createDefaultAchievements();
    }
  }

  // Create default achievements
  void _createDefaultAchievements() {
    _achievements = [
      Achievement(
        id: FirebaseConstants.achievementFirstLesson,
        title: 'ก้าวแรก',
        description: 'เรียนจบบทเรียนแรก',
        iconPath: 'assets/icons/achievements/first_lesson.png',
        category: 'learning',
        difficulty: 'easy',
        xpReward: 50,
        createdAt: DateTime.now(),
      ),
      Achievement(
        id: FirebaseConstants.achievementLevel5,
        title: 'นักเรียนขยัน',
        description: 'ขึ้นถึงระดับ 5',
        iconPath: 'assets/icons/achievements/level_5.png',
        category: 'learning',
        difficulty: 'medium',
        xpReward: 100,
        createdAt: DateTime.now(),
      ),
      Achievement(
        id: FirebaseConstants.achievementLessons10,
        title: 'ผู้ขยันหัดหนังสือ',
        description: 'เรียนจบ 10 บทเรียน',
        iconPath: 'assets/icons/achievements/lessons_10.png',
        category: 'learning',
        difficulty: 'medium',
        xpReward: 200,
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Calculate category progress
  void _calculateCategoryProgress() {
    _categoryProgress.clear();
    _categoryXP.clear();

    final categories = [
      FirebaseConstants.categoryFileManagement,
      FirebaseConstants.categorySystemAdmin,
      FirebaseConstants.categoryNetworking,
      FirebaseConstants.categoryTextProcessing,
      FirebaseConstants.categoryPackageManagement,
      FirebaseConstants.categorySecurity,
      FirebaseConstants.categoryShellScripting,
    ];

    for (final category in categories) {
      final categoryLessons = _learningProgress
          .where((progress) => progress.category == category)
          .toList();

      if (categoryLessons.isNotEmpty) {
        final completedLessons = categoryLessons
            .where((progress) => progress.isCompleted)
            .length;

        _categoryProgress[category] = completedLessons / categoryLessons.length;
        _categoryXP[category] = categoryLessons
            .where((progress) => progress.isCompleted)
            .fold(0, (sum, progress) => sum + progress.xpEarned);
      } else {
        _categoryProgress[category] = 0.0;
        _categoryXP[category] = 0;
      }
    }
  }

  // Calculate statistics
  Future<void> _calculateStatistics() async {
    await _calculateDailyActivity();
    await _calculateWeeklyStats();
    await _calculateMonthlyStats();
  }

  // Calculate daily activity
  Future<void> _calculateDailyActivity() async {
    _dailyActivity.clear();

    final now = DateTime.now();
    final last30Days = List.generate(30, (index) {
      final date = now.subtract(Duration(days: 29 - index));
      return DateTime(date.year, date.month, date.day);
    });

    for (final date in last30Days) {
      final nextDay = date.add(const Duration(days: 1));

      final dayProgress = _learningProgress
          .where((progress) =>
      progress.completedAt != null &&
          progress.completedAt!.isAfter(date) &&
          progress.completedAt!.isBefore(nextDay))
          .toList();

      final lessonsCompleted = dayProgress.length;
      final xpEarned = dayProgress.fold(0, (sum, progress) => sum + progress.xpEarned);
      final timeSpent = dayProgress.fold(0, (sum, progress) => sum + progress.completionTimeInSeconds);

      _dailyActivity.add({
        'date': date,
        'lessonsCompleted': lessonsCompleted,
        'xpEarned': xpEarned,
        'timeSpent': timeSpent,
        'accuracy': dayProgress.isNotEmpty
            ? dayProgress.fold(0.0, (sum, progress) => sum + progress.accuracy) / dayProgress.length
            : 0.0,
      });
    }
  }

  // Calculate weekly stats
  Future<void> _calculateWeeklyStats() async {
    _weeklyStats.clear();

    final now = DateTime.now();
    final last12Weeks = List.generate(12, (index) {
      final date = now.subtract(Duration(days: (11 - index) * 7));
      return DateTime(date.year, date.month, date.day - date.weekday + 1);
    });

    for (int i = 0; i < last12Weeks.length; i++) {
      final weekStart = last12Weeks[i];
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weekProgress = _learningProgress
          .where((progress) =>
      progress.completedAt != null &&
          progress.completedAt!.isAfter(weekStart) &&
          progress.completedAt!.isBefore(weekEnd))
          .toList();

      _weeklyStats.add({
        'week': i + 1,
        'startDate': weekStart,
        'endDate': weekEnd,
        'lessonsCompleted': weekProgress.length,
        'xpEarned': weekProgress.fold(0, (sum, progress) => sum + progress.xpEarned),
        'timeSpent': weekProgress.fold(0, (sum, progress) => sum + progress.completionTimeInSeconds),
        'averageAccuracy': weekProgress.isNotEmpty
            ? weekProgress.fold(0.0, (sum, progress) => sum + progress.accuracy) / weekProgress.length
            : 0.0,
      });
    }
  }

  // Calculate monthly stats
  Future<void> _calculateMonthlyStats() async {
    _monthlyStats.clear();

    final now = DateTime.now();
    final last6Months = List.generate(6, (index) {
      final date = now.subtract(Duration(days: (5 - index) * 30));
      return DateTime(date.year, date.month, 1);
    });

    for (int i = 0; i < last6Months.length; i++) {
      final monthStart = last6Months[i];
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);

      final monthProgress = _learningProgress
          .where((progress) =>
      progress.completedAt != null &&
          progress.completedAt!.isAfter(monthStart) &&
          progress.completedAt!.isBefore(monthEnd))
          .toList();

      _monthlyStats.add({
        'month': i + 1,
        'startDate': monthStart,
        'endDate': monthEnd,
        'lessonsCompleted': monthProgress.length,
        'xpEarned': monthProgress.fold(0, (sum, progress) => sum + progress.xpEarned),
        'timeSpent': monthProgress.fold(0, (sum, progress) => sum + progress.completionTimeInSeconds),
        'averageAccuracy': monthProgress.isNotEmpty
            ? monthProgress.fold(0.0, (sum, progress) => sum + progress.accuracy) / monthProgress.length
            : 0.0,
      });
    }
  }

  // Load leaderboard
  Future<void> _loadLeaderboard() async {
    try {
      _leaderboard = await _firebaseService.getLeaderboard(limit: 20);

      // Find current user's ranking
      _userRanking = 0;
      for (int i = 0; i < _leaderboard.length; i++) {
        if (_leaderboard[i]['uid'] == _currentUserId) {
          _userRanking = i + 1;
          break;
        }
      }
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
    }
  }

  // Update user progress
  Future<void> updateProgress({
    required String commandName,
    required String category,
    required String difficulty,
    required double accuracy,
    required int completionTimeInSeconds,
    int attempts = 1,
  }) async {
    if (_currentUserId == null || _currentUser == null) return;

    try {
      // Create learning progress
      final progressId = '${_currentUserId}_${commandName}_${DateTime.now().millisecondsSinceEpoch}';
      final progress = LearningProgress(
        id: progressId,
        userId: _currentUserId!,
        commandName: commandName,
        category: category,
        difficulty: difficulty,
        startedAt: DateTime.now().subtract(Duration(seconds: completionTimeInSeconds)),
        completedAt: DateTime.now(),
        isCompleted: true,
        accuracy: accuracy,
        attempts: attempts,
        completionTimeInSeconds: completionTimeInSeconds,
        xpEarned: _calculateXP(difficulty, accuracy),
        progressType: 'lesson',
        overallProgress: 1.0,
      );

      // Save to Firebase
      await _firebaseService.saveLearningProgress(_currentUserId!, progress);

      // Add to local list
      _learningProgress.add(progress);

      // Update user stats
      await _updateUserStats(progress);

      // Check for achievements
      await _checkAchievements();

      // Recalculate statistics
      _calculateCategoryProgress();
      await _calculateStatistics();

      notifyListeners();

      // Log analytics
      _analyticsService.logLessonCompleted(
        lessonId: commandName,
        category: category,
        difficulty: difficulty,
        completionTime: completionTimeInSeconds,
        accuracy: accuracy,
        xpEarned: progress.xpEarned,
      );

    } catch (e) {
      debugPrint('Error updating progress: $e');
    }
  }

  // Calculate XP based on difficulty and accuracy
  int _calculateXP(String difficulty, double accuracy) {
    int baseXP = switch (difficulty) {
      'beginner' => FirebaseConstants.defaultXPForBeginner,
      'intermediate' => FirebaseConstants.defaultXPForIntermediate,
      'advanced' => FirebaseConstants.defaultXPForAdvanced,
      'expert' => FirebaseConstants.defaultXPForExpert,
      _ => FirebaseConstants.defaultXPForBeginner,
    };

    // Apply accuracy multiplier
    final multiplier = (accuracy * 1.5).clamp(0.5, 2.0);
    return (baseXP * multiplier).round();
  }

  // Update user stats
  Future<void> _updateUserStats(LearningProgress progress) async {
    if (_currentUser == null) return;

    try {
      final newXP = _currentUser!.xp + progress.xpEarned;
      final newLevel = (newXP / FirebaseConstants.xpPerLevel).floor() + 1;
      final newTotalLessons = _currentUser!.totalLessonsCompleted + 1;

      // Check for level up
      final didLevelUp = newLevel > _currentUser!.level;

      // Update user model
      _currentUser = _currentUser!.copyWith(
        xp: newXP,
        level: newLevel,
        totalLessonsCompleted: newTotalLessons,
        lastActivity: DateTime.now(),
      );

      // Update in Firebase
      await _firebaseService.updateUserProfile(_currentUserId!, {
        'xp': newXP,
        'level': newLevel,
        'totalLessonsCompleted': newTotalLessons,
        'lastActivity': DateTime.now(),
      });

      // Update leaderboard
      await _firebaseService.updateLeaderboard(_currentUserId!, newXP, newLevel);

      // Log level up
      if (didLevelUp) {
        _analyticsService.logLevelUp(
          newLevel: newLevel,
          totalXP: newXP,
          category: progress.category,
        );
      }

    } catch (e) {
      debugPrint('Error updating user stats: $e');
    }
  }

  // Check for new achievements
  Future<void> _checkAchievements() async {
    if (_currentUser == null) return;

    final newAchievements = <Achievement>[];

    // Check each achievement
    for (final achievement in _achievements) {
      if (_isAchievementUnlocked(achievement.id)) continue;

      if (_checkAchievementConditions(achievement)) {
        // Unlock achievement
        final unlockedAchievement = achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );

        newAchievements.add(unlockedAchievement);
        _unlockedAchievements.add(unlockedAchievement);

        // Save to Firebase
        try {
          await _firebaseService.achievementsCollection
              .doc('${_currentUserId}_${achievement.id}')
              .set({
            ...unlockedAchievement.toMap(),
            'userId': _currentUserId,
          });

          // Log achievement
          _analyticsService.logAchievementUnlocked(
            achievementId: achievement.id,
            achievementName: achievement.title,
            category: achievement.category,
            xpReward: achievement.xpReward,
          );

        } catch (e) {
          debugPrint('Error saving achievement: $e');
        }
      }
    }

    // Notify about new achievements
    if (newAchievements.isNotEmpty) {
      notifyListeners();
      _notifyNewAchievements(newAchievements);
    }
  }

  // Check if achievement is already unlocked
  bool _isAchievementUnlocked(String achievementId) {
    return _unlockedAchievements.any((a) => a.id == achievementId);
  }

  // Check achievement conditions
  bool _checkAchievementConditions(Achievement achievement) {
    switch (achievement.id) {
      case FirebaseConstants.achievementFirstLesson:
        return _learningProgress.any((p) => p.isCompleted);

      case FirebaseConstants.achievementLevel5:
        return _currentUser!.level >= 5;

      case FirebaseConstants.achievementLevel10:
        return _currentUser!.level >= 10;

      case FirebaseConstants.achievementLevel20:
        return _currentUser!.level >= 20;

      case FirebaseConstants.achievementLessons10:
        return _learningProgress.where((p) => p.isCompleted).length >= 10;

      case FirebaseConstants.achievementLessons50:
        return _learningProgress.where((p) => p.isCompleted).length >= 50;

      case FirebaseConstants.achievementLessons100:
        return _learningProgress.where((p) => p.isCompleted).length >= 100;

      case FirebaseConstants.achievementPerfectAccuracy:
        return _learningProgress.any((p) => p.isCompleted && p.accuracy >= 1.0);

      case FirebaseConstants.achievementStreak7:
        return _calculateCurrentStreak() >= 7;

      case FirebaseConstants.achievementStreak30:
        return _calculateCurrentStreak() >= 30;

      default:
        return false;
    }
  }

  // Calculate current learning streak
  int _calculateCurrentStreak() {
    final completedProgress = _learningProgress
        .where((p) => p.isCompleted && p.completedAt != null)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    if (completedProgress.isEmpty) return 0;

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    // Check if user has activity today or yesterday
    final hasRecentActivity = completedProgress.any((p) =>
        p.completedAt!.isAfter(yesterday));

    if (!hasRecentActivity) return 0;

    int streak = 1;
    DateTime lastDate = completedProgress.first.completedAt!;

    for (int i = 1; i < completedProgress.length; i++) {
      final currentDate = completedProgress[i].completedAt!;
      final daysDifference = lastDate.difference(currentDate).inDays;

      if (daysDifference <= 1) {
        if (daysDifference == 1 ||
            (lastDate.day != currentDate.day)) {
          streak++;
        }
        lastDate = currentDate;
      } else {
        break;
      }
    }

    return streak;
  }

  // Notify about new achievements
  void _notifyNewAchievements(List<Achievement> achievements) {
    // This would typically show a notification or popup
    for (final achievement in achievements) {
      debugPrint('Achievement unlocked: ${achievement.title}');
    }
  }

  // Get detailed statistics
  Map<String, dynamic> getDetailedStatistics() {
    final completedLessons = _learningProgress.where((p) => p.isCompleted).length;
    final totalTime = _learningProgress
        .where((p) => p.isCompleted)
        .fold(0, (sum, p) => sum + p.completionTimeInSeconds);

    final averageAccuracy = _learningProgress
        .where((p) => p.isCompleted && p.accuracy > 0)
        .fold(0.0, (sum, p) => sum + p.accuracy) /
        _learningProgress.where((p) => p.isCompleted && p.accuracy > 0).length;

    final categoriesCompleted = _categoryProgress.values.where((p) => p >= 1.0).length;

    return {
      'totalXP': _currentUser?.xp ?? 0,
      'currentLevel': _currentUser?.level ?? 1,
      'completedLessons': completedLessons,
      'totalTimeSpent': totalTime,
      'averageAccuracy': averageAccuracy.isNaN ? 0.0 : averageAccuracy,
      'currentStreak': _calculateCurrentStreak(),
      'unlockedAchievements': _unlockedAchievements.length,
      'totalAchievements': _achievements.length,
      'categoriesCompleted': categoriesCompleted,
      'ranking': _userRanking,
      'categoryProgress': _categoryProgress,
      'categoryXP': _categoryXP,
    };
  }

  // Get progress for specific category
  double getCategoryProgress(String category) {
    return _categoryProgress[category] ?? 0.0;
  }

  // Get XP for specific category
  int getCategoryXP(String category) {
    return _categoryXP[category] ?? 0;
  }

  // Get user's rank in leaderboard
  int getUserRank() {
    return _userRanking;
  }

  // Get recent activity
  List<LearningProgress> getRecentActivity({int limit = 10}) {
    return _learningProgress
        .where((p) => p.isCompleted)
        .toList()
      ..sort((a, b) => (b.completedAt ?? DateTime.now())
          .compareTo(a.completedAt ?? DateTime.now()))
      ..take(limit);
  }

  // Get best performances
  List<LearningProgress> getBestPerformances({int limit = 5}) {
    return _learningProgress
        .where((p) => p.isCompleted && p.accuracy > 0)
        .toList()
      ..sort((a, b) => b.accuracy.compareTo(a.accuracy))
      ..take(limit);
  }

  // Get learning insights
  Map<String, dynamic> getLearningInsights() {
    final insights = <String, dynamic>{};

    // Most improved category
    String? mostImprovedCategory;
    double maxImprovement = 0;

    _categoryProgress.forEach((category, progress) {
      if (progress > maxImprovement) {
        maxImprovement = progress;
        mostImprovedCategory = category;
      }
    });

    insights['mostImprovedCategory'] = mostImprovedCategory;
    insights['improvementPercentage'] = maxImprovement;

    // Learning pattern
    final morningLessons = _learningProgress
        .where((p) => p.completedAt?.hour != null && p.completedAt!.hour < 12)
        .length;
    final afternoonLessons = _learningProgress
        .where((p) => p.completedAt?.hour != null &&
        p.completedAt!.hour >= 12 && p.completedAt!.hour < 18)
        .length;
    final eveningLessons = _learningProgress
        .where((p) => p.completedAt?.hour != null && p.completedAt!.hour >= 18)
        .length;

    insights['preferredTimeOfDay'] = morningLessons > afternoonLessons && morningLessons > eveningLessons
        ? 'morning'
        : afternoonLessons > eveningLessons
        ? 'afternoon'
        : 'evening';

    // Average session length
    insights['averageSessionLength'] = _learningProgress
        .where((p) => p.completionTimeInSeconds > 0)
        .fold(0, (sum, p) => sum + p.completionTimeInSeconds) /
        _learningProgress.where((p) => p.completionTimeInSeconds > 0).length;

    return insights;
  }

  // Refresh all data
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadUserData();
      await _loadLearningProgress();
      await _loadAchievements();
      await _calculateStatistics();
      await _loadLeaderboard();
    } catch (e) {
      debugPrint('Error refreshing progress data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset progress (for testing or new user)
  void reset() {
    _learningProgress.clear();
    _achievements.clear();
    _unlockedAchievements.clear();
    _categoryProgress.clear();
    _categoryXP.clear();
    _dailyActivity.clear();
    _weeklyStats.clear();
    _monthlyStats.clear();
    _leaderboard.clear();
    _userRanking = 0;
    notifyListeners();
  }
}