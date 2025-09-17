import '../entities/progress.dart';

abstract class ProgressRepositoryInterface {
  /// Get user's overall progress
  Future<UserProgressSummary> getUserProgressSummary(String userId);

  /// Get progress for specific item
  Future<Progress?> getProgressById({
    required String userId,
    required String itemId,
    required ProgressType type,
  });

  /// Get all progress for user
  Future<List<Progress>> getUserProgress({
    required String userId,
    ProgressType? type,
    ProgressStatus? status,
  });

  /// Update or create progress
  Future<Progress> updateProgress({
    required String userId,
    required String itemId,
    required ProgressType type,
    int? currentStep,
    double? completionPercentage,
    int? score,
    ProgressStatus? status,
    Duration? timeSpent,
    List<String>? skillsLearned,
    Map<String, dynamic>? data,
  });

  /// Start new progress tracking
  Future<Progress> startProgress({
    required String userId,
    required String itemId,
    required ProgressType type,
    required int totalSteps,
    required int maxScore,
    required double difficulty,
  });

  /// Complete progress item
  Future<Progress> completeProgress({
    required String userId,
    required String itemId,
    required ProgressType type,
    int? finalScore,
    List<String>? skillsLearned,
  });

  /// Reset progress
  Future<void> resetProgress({
    required String userId,
    required String itemId,
    required ProgressType type,
  });

  /// Delete progress
  Future<void> deleteProgress({
    required String userId,
    required String itemId,
    required ProgressType type,
  });

  /// Get progress by category
  Future<List<Progress>> getProgressByCategory({
    required String userId,
    required String category,
  });

  /// Get completed items
  Future<List<Progress>> getCompletedItems({
    required String userId,
    ProgressType? type,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get in-progress items
  Future<List<Progress>> getInProgressItems({
    required String userId,
    ProgressType? type,
  });

  /// Get progress statistics
  Future<ProgressStats> getProgressStats({
    required String userId,
    ProgressType? type,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get learning streak
  Future<LearningStreak> getLearningStreak(String userId);

  /// Update learning streak
  Future<LearningStreak> updateLearningStreak({
    required String userId,
    required DateTime date,
  });

  /// Get daily progress
  Future<Map<DateTime, int>> getDailyProgress({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get weekly progress summary
  Future<WeeklyProgressSummary> getWeeklyProgress({
    required String userId,
    required DateTime weekStart,
  });

  /// Get monthly progress summary
  Future<MonthlyProgressSummary> getMonthlyProgress({
    required String userId,
    required DateTime monthStart,
  });

  /// Get skill progress
  Future<Map<String, double>> getSkillProgress(String userId);

  /// Update skill level
  Future<void> updateSkillLevel({
    required String userId,
    required String skill,
    required double level,
  });

  /// Get achievements progress
  Future<List<Progress>> getAchievementsProgress(String userId);

  /// Add milestone
  Future<Progress> addMilestone({
    required String progressId,
    required ProgressMilestone milestone,
  });

  /// Complete milestone
  Future<Progress> completeMilestone({
    required String progressId,
    required String milestoneId,
  });

  /// Get leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard({
    ProgressType? type,
    String? category,
    String? timeframe, // 'day', 'week', 'month', 'all'
    int limit = 100,
  });

  /// Get user rank
  Future<UserRank> getUserRank({
    required String userId,
    ProgressType? type,
    String? category,
  });

  /// Export progress data
  Future<String> exportProgressData({
    required String userId,
    String format = 'json', // json, csv
  });

  /// Import progress data
  Future<void> importProgressData({
    required String userId,
    required String data,
    String format = 'json',
  });

  /// Sync progress with remote server
  Future<void> syncProgress({
    required String userId,
    DateTime? lastSyncDate,
  });

  /// Cache progress locally
  Future<void> cacheProgressLocally({
    required String userId,
    required List<Progress> progressList,
  });

  /// Get cached progress
  Future<List<Progress>> getCachedProgress(String userId);

  /// Clear progress cache
  Future<void> clearProgressCache(String userId);
}

class UserProgressSummary {
  final String userId;
  final int totalItems;
  final int completedItems;
  final int inProgressItems;
  final double overallCompletionRate;
  final int totalExperience;
  final Map<String, int> categoryProgress;
  final Map<String, double> skillLevels;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActivity;

  const UserProgressSummary({
    required this.userId,
    required this.totalItems,
    required this.completedItems,
    required this.inProgressItems,
    required this.overallCompletionRate,
    required this.totalExperience,
    required this.categoryProgress,
    required this.skillLevels,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivity,
  });

  double get completionPercentage => totalItems > 0 ? (completedItems / totalItems) * 100 : 0.0;
  bool get hasActiveStreak => currentStreak > 0;

  @override
  String toString() {
    return 'UserProgressSummary(userId: $userId, completedItems: $completedItems/$totalItems, completionRate: ${overallCompletionRate.toStringAsFixed(1)}%)';
  }
}

class ProgressStats {
  final int totalItems;
  final int completedItems;
  final int inProgressItems;
  final double averageScore;
  final Duration totalTimeSpent;
  final Map<ProgressType, int> typeBreakdown;
  final Map<String, int> categoryBreakdown;
  final List<DateTime> completionDates;

  const ProgressStats({
    required this.totalItems,
    required this.completedItems,
    required this.inProgressItems,
    required this.averageScore,
    required this.totalTimeSpent,
    required this.typeBreakdown,
    required this.categoryBreakdown,
    required this.completionDates,
  });

  double get completionRate => totalItems > 0 ? (completedItems / totalItems) * 100 : 0.0;

  @override
  String toString() {
    return 'ProgressStats(total: $totalItems, completed: $completedItems, avgScore: ${averageScore.toStringAsFixed(1)})';
  }
}

class LearningStreak {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime streakStartDate;
  final DateTime lastActivityDate;
  final List<DateTime> activityDates;

  const LearningStreak({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.streakStartDate,
    required this.lastActivityDate,
    required this.activityDates,
  });

  bool get isActiveToday {
    final today = DateTime.now();
    final lastActivity = lastActivityDate;
    return today.year == lastActivity.year &&
        today.month == lastActivity.month &&
        today.day == lastActivity.day;
  }

  @override
  String toString() {
    return 'LearningStreak(userId: $userId, current: $currentStreak, longest: $longestStreak)';
  }
}

class WeeklyProgressSummary {
  final String userId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int itemsCompleted;
  final Duration timeSpent;
  final double averageScore;
  final Map<DateTime, int> dailyCompletions;
  final List<String> skillsLearned;

  const WeeklyProgressSummary({
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    required this.itemsCompleted,
    required this.timeSpent,
    required this.averageScore,
    required this.dailyCompletions,
    required this.skillsLearned,
  });
}

class MonthlyProgressSummary {
  final String userId;
  final DateTime monthStart;
  final DateTime monthEnd;
  final int itemsCompleted;
  final Duration timeSpent;
  final double averageScore;
  final Map<int, int> weeklyCompletions; // week number -> completions
  final List<String> skillsLearned;
  final Map<String, int> categoryBreakdown;

  const MonthlyProgressSummary({
    required this.userId,
    required this.monthStart,
    required this.monthEnd,
    required this.itemsCompleted,
    required this.timeSpent,
    required this.averageScore,
    required this.weeklyCompletions,
    required this.skillsLearned,
    required this.categoryBreakdown,
  });
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int score;
  final int rank;
  final Map<String, dynamic> metadata;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.score,
    required this.rank,
    required this.metadata,
  });

  @override
  String toString() {
    return 'LeaderboardEntry(rank: $rank, username: $username, score: $score)';
  }
}

class UserRank {
  final String userId;
  final int rank;
  final int totalUsers;
  final int score;
  final double percentile;

  const UserRank({
    required this.userId,
    required this.rank,
    required this.totalUsers,
    required this.score,
    required this.percentile,
  });

  @override
  String toString() {
    return 'UserRank(userId: $userId, rank: $rank/$totalUsers, percentile: ${percentile.toStringAsFixed(1)}%)';
  }
}