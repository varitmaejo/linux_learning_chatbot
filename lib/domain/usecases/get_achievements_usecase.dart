import '../entities/progress.dart';
import '../entities/user.dart';
import '../repositories/progress_repository_interface.dart';
import '../repositories/user_repository_interface.dart';

class GetAchievementsUseCase {
  final ProgressRepositoryInterface _progressRepository;
  final UserRepositoryInterface _userRepository;

  GetAchievementsUseCase(
      this._progressRepository,
      this._userRepository,
      );

  /// Get all achievements for a user
  Future<AchievementsResult> execute({
    required String userId,
    AchievementFilter? filter,
  }) async {
    try {
      // Get user data
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        return AchievementsResult.failure(
          error: 'User not found',
          errorCode: 'USER_NOT_FOUND',
        );
      }

      // Get user's progress data
      final progressSummary = await _progressRepository.getUserProgressSummary(userId);
      final userStats = await _progressRepository.getProgressStats(userId: userId);
      final learningStreak = await _progressRepository.getLearningStreak(userId);

      // Generate achievements based on progress
      final achievements = await _generateAchievements(
        user: user,
        progressSummary: progressSummary,
        stats: userStats,
        learningStreak: learningStreak,
      );

      // Apply filters if provided
      final filteredAchievements = _applyFilters(achievements, filter);

      // Sort achievements
      final sortedAchievements = _sortAchievements(filteredAchievements);

      return AchievementsResult.success(
        achievements: sortedAchievements,
        totalCount: achievements.length,
        unlockedCount: achievements.where((a) => a.isUnlocked).length,
      );
    } catch (e) {
      return AchievementsResult.failure(
        error: e.toString(),
        errorCode: 'GET_ACHIEVEMENTS_ERROR',
      );
    }
  }

  /// Get unlocked achievements only
  Future<AchievementsResult> getUnlockedAchievements({
    required String userId,
  }) async {
    return execute(
      userId: userId,
      filter: AchievementFilter(unlockedOnly: true),
    );
  }

  /// Get achievements by category
  Future<AchievementsResult> getAchievementsByCategory({
    required String userId,
    required String category,
  }) async {
    return execute(
      userId: userId,
      filter: AchievementFilter(category: category),
    );
  }

  /// Get recent achievements
  Future<AchievementsResult> getRecentAchievements({
    required String userId,
    int days = 7,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    return execute(
      userId: userId,
      filter: AchievementFilter(
        unlockedOnly: true,
        unlockedAfter: startDate,
      ),
    );
  }

  /// Check for new achievements
  Future<List<Achievement>> checkForNewAchievements({
    required String userId,
  }) async {
    try {
      final user = await _userRepository.getUserById(userId);
      if (user == null) return [];

      final progressSummary = await _progressRepository.getUserProgressSummary(userId);
      final userStats = await _progressRepository.getProgressStats(userId: userId);
      final learningStreak = await _progressRepository.getLearningStreak(userId);

      // Generate all potential achievements
      final allAchievements = await _generateAchievements(
        user: user,
        progressSummary: progressSummary,
        stats: userStats,
        learningStreak: learningStreak,
      );

      // Filter newly unlocked achievements
      final newAchievements = allAchievements.where((achievement) {
        return achievement.isUnlocked &&
            !user.achievements.contains(achievement.id);
      }).toList();

      // Update user with new achievements
      for (final achievement in newAchievements) {
        await _userRepository.addAchievement(
          userId: userId,
          achievementId: achievement.id,
        );
      }

      return newAchievements;
    } catch (e) {
      return [];
    }
  }

  Future<List<Achievement>> _generateAchievements({
    required User user,
    required UserProgressSummary progressSummary,
    required ProgressStats stats,
    required LearningStreak learningStreak,
  }) async {
    final achievements = <Achievement>[];

    // Progress-based achievements
    achievements.addAll(_generateProgressAchievements(progressSummary));

    // Streak-based achievements
    achievements.addAll(_generateStreakAchievements(learningStreak));

    // Score-based achievements
    achievements.addAll(_generateScoreAchievements(stats));

    // Time-based achievements
    achievements.addAll(_generateTimeAchievements(stats));

    // Level-based achievements
    achievements.addAll(_generateLevelAchievements(user));

    // Category-specific achievements
    achievements.addAll(_generateCategoryAchievements(progressSummary));

    // Special achievements
    achievements.addAll(_generateSpecialAchievements(user, stats));

    return achievements;
  }

  List<Achievement> _generateProgressAchievements(UserProgressSummary summary) {
    final achievements = <Achievement>[];

    // First steps
    achievements.add(Achievement(
      id: 'first_completion',
      title: 'First Steps',
      description: 'Complete your first learning item',
      iconPath: 'assets/achievements/first_steps.png',
      category: 'progress',
      difficulty: 'easy',
      xpReward: 10,
      isUnlocked: summary.completedItems > 0,
      unlockedAt: summary.completedItems > 0 ? DateTime.now() : null,
      progress: summary.completedItems > 0 ? 1.0 : 0.0,
      maxProgress: 1.0,
      requirements: {'completed_items': 1},
      prerequisites: [],
      isSecret: false,
      badgeColor: 'bronze',
      rarity: 1,
      steps: [],
      metadata: {},
      createdAt: DateTime.now(),
      isActive: true,
    ));

    // Completion milestones
    final milestones = [10, 25, 50, 100, 250, 500];
    for (final milestone in milestones) {
      achievements.add(Achievement(
        id: 'completion_$milestone',
        title: 'Achiever ${milestone}',
        description: 'Complete $milestone learning items',
        iconPath: 'assets/achievements/achiever_$milestone.png',
        category: 'progress',
        difficulty: milestone <= 25 ? 'easy' : milestone <= 100 ? 'medium' : 'hard',
        xpReward: milestone ~/ 2,
        isUnlocked: summary.completedItems >= milestone,
        unlockedAt: summary.completedItems >= milestone ? DateTime.now() : null,
        progress: (summary.completedItems / milestone).clamp(0.0, 1.0),
        maxProgress: 1.0,
        requirements: {'completed_items': milestone},
        prerequisites: [],
        isSecret: false,
        badgeColor: milestone <= 25 ? 'bronze' : milestone <= 100 ? 'silver' : 'gold',
        rarity: milestone <= 25 ? 1 : milestone <= 100 ? 2 : 3,
        steps: [],
        metadata: {},
        createdAt: DateTime.now(),
        isActive: true,
      ));
    }

    return achievements;
  }

  List<Achievement> _generateStreakAchievements(LearningStreak streak) {
    final achievements = <Achievement>[];

    final streakMilestones = [3, 7, 14, 30, 60, 100];
    for (final milestone in streakMilestones) {
      achievements.add(Achievement(
        id: 'streak_$milestone',
        title: '${milestone}-Day Streak',
        description: 'Learn for $milestone consecutive days',
        iconPath: 'assets/achievements/streak_$milestone.png',
        category: 'streak',
        difficulty: milestone <= 7 ? 'easy' : milestone <= 30 ? 'medium' : 'hard',
        xpReward: milestone * 2,
        isUnlocked: streak.currentStreak >= milestone || streak.longestStreak >= milestone,
        unlockedAt: streak.longestStreak >= milestone ? DateTime.now() : null,
        progress: (streak.currentStreak / milestone).clamp(0.0, 1.0),
        maxProgress: 1.0,
        requirements: {'streak_days': milestone},
        prerequisites: [],
        isSecret: false,
        badgeColor: milestone <= 7 ? 'bronze' : milestone <= 30 ? 'silver' : 'gold',
        rarity: milestone <= 7 ? 1 : milestone <= 30 ? 2 : 3,
        steps: [],
        metadata: {},
        createdAt: DateTime.now(),
        isActive: true,
      ));
    }

    return achievements;
  }

  List<Achievement> _generateScoreAchievements(ProgressStats stats) {
    final achievements = <Achievement>[];

    // Perfect scores
    achievements.add(Achievement(
      id: 'perfectionist',
      title: 'Perfectionist',
      description: 'Score 100% on 10 items',
      iconPath: 'assets/achievements/perfectionist.png',
      category: 'score',
      difficulty: 'medium',
      xpReward: 50,
      isUnlocked: false, // Would need to track perfect scores
      progress: 0.0,
      maxProgress: 1.0,
      requirements: {'perfect_scores': 10},
      prerequisites: [],
      isSecret: false,
      badgeColor: 'gold',
      rarity: 2,
      steps: [],
      metadata: {},
      createdAt: DateTime.now(),
      isActive: true,
    ));

    // High average score
    achievements.add(Achievement(
      id: 'high_achiever',
      title: 'High Achiever',
      description: 'Maintain an average score above 80%',
      iconPath: 'assets/achievements/high_achiever.png',
      category: 'score',
      difficulty: 'medium',
      xpReward: 30,
      isUnlocked: stats.averageScore >= 80,
      unlockedAt: stats.averageScore >= 80 ? DateTime.now() : null,
      progress: (stats.averageScore / 80).clamp(0.0, 1.0),
      maxProgress: 1.0,
      requirements: {'average_score': 80},
      prerequisites: [],
      isSecret: false,
      badgeColor: 'silver',
      rarity: 2,
      steps: [],
      metadata: {},
      createdAt: DateTime.now(),
      isActive: true,
    ));

    return achievements;
  }

  List<Achievement> _generateTimeAchievements(ProgressStats stats) {
    final achievements = <Achievement>[];

    // Time spent milestones (in hours)
    final timeMilestones = [1, 5, 10, 25, 50, 100];
    for (final milestone in timeMilestones) {
      final hoursSpent = stats.totalTimeSpent.inHours;
      achievements.add(Achievement(
        id: 'time_spent_$milestone',
        title: 'Time Master ${milestone}h',
        description: 'Spend $milestone hours learning',
        iconPath: 'assets/achievements/time_master_$milestone.png',
        category: 'time',
        difficulty: milestone <= 5 ? 'easy' : milestone <= 25 ? 'medium' : 'hard',
        xpReward: milestone * 3,
        isUnlocked: hoursSpent >= milestone,
        unlockedAt: hoursSpent >= milestone ? DateTime.now() : null,
        progress: (hoursSpent / milestone).clamp(0.0, 1.0),
        maxProgress: 1.0,
        requirements: {'hours_spent': milestone},
        prerequisites: [],
        isSecret: false,
        badgeColor: milestone <= 5 ? 'bronze' : milestone <= 25 ? 'silver' : 'gold',
        rarity: milestone <= 5 ? 1 : milestone <= 25 ? 2 : 3,
        steps: [],
        metadata: {},
        createdAt: DateTime.now(),
        isActive: true,
      ));
    }

    return achievements;
  }

  List<Achievement> _generateLevelAchievements(User user) {
    final achievements = <Achievement>[];

    // Level achievements
    final levels = [
      ('intermediate', UserLevel.intermediate),
      ('advanced', UserLevel.advanced),
      ('expert', UserLevel.expert),
    ];

    for (final (levelName, level) in levels) {
      achievements.add(Achievement(
        id: 'level_$levelName',
        title: '${levelName.toUpperCase()} Level',
        description: 'Reach $levelName level',
        iconPath: 'assets/achievements/level_$levelName.png',
        category: 'level',
        difficulty: levelName == 'intermediate' ? 'easy' :
        levelName == 'advanced' ? 'medium' : 'hard',
        xpReward: levelName == 'intermediate' ? 50 :
        levelName == 'advanced' ? 100 : 200,
        isUnlocked: user.level.index >= level.index,
        unlockedAt: user.level.index >= level.index ? DateTime.now() : null,
        progress: user.level.index >= level.index ? 1.0 : user.levelProgress,
        maxProgress: 1.0,
        requirements: {'user_level': levelName},
        prerequisites: [],
        isSecret: false,
        badgeColor: levelName == 'intermediate' ? 'silver' :
        levelName == 'advanced' ? 'gold' : 'platinum',
        rarity: levelName == 'intermediate' ? 2 :
        levelName == 'advanced' ? 3 : 4,
        steps: [],
        metadata: {},
        createdAt: DateTime.now(),
        isActive: true,
      ));
    }

    return achievements;
  }

  List<Achievement> _generateCategoryAchievements(UserProgressSummary summary) {
    final achievements = <Achievement>[];

    // Category completion achievements
    for (final entry in summary.categoryProgress.entries) {
      final category = entry.key;
      final completed = entry.value;

      if (completed >= 10) {
        achievements.add(Achievement(
          id: 'category_${category}_master',
          title: '${category.toUpperCase()} Master',
          description: 'Complete 10 items in $category category',
          iconPath: 'assets/achievements/category_${category}_master.png',
          category: 'category',
          difficulty: 'medium',
          xpReward: 40,
          isUnlocked: completed >= 10,
          unlockedAt: completed >= 10 ? DateTime.now() : null,
          progress: (completed / 10).clamp(0.0, 1.0),
          maxProgress: 1.0,
          requirements: {'category_$category': 10},
          prerequisites: [],
          isSecret: false,
          badgeColor: 'gold',
          rarity: 2,
          steps: [],
          metadata: {},
          createdAt: DateTime.now(),
          isActive: true,
        ));
      }
    }

    return achievements;
  }

  List<Achievement> _generateSpecialAchievements(User user, ProgressStats stats) {
    final achievements = <Achievement>[];

    // Early bird (first week)
    final daysSinceCreated = DateTime.now().difference(user.createdAt).inDays;
    if (daysSinceCreated <= 7 && stats.completedItems >= 5) {
      achievements.add(Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Complete 5 items in your first week',
        iconPath: 'assets/achievements/early_bird.png',
        category: 'special',
        difficulty: 'medium',
        xpReward: 25,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
        progress: 1.0,
        maxProgress: 1.0,
        requirements: {'first_week_completions': 5},
        prerequisites: [],
        isSecret: false,
        badgeColor: 'silver',
        rarity: 2,
        steps: [],
        metadata: {},
        createdAt: DateTime.now(),
        isActive: true,
      ));
    }

    return achievements;
  }

  List<Achievement> _applyFilters(List<Achievement> achievements, AchievementFilter? filter) {
    if (filter == null) return achievements;

    var filtered = achievements;

    if (filter.unlockedOnly == true) {
      filtered = filtered.where((a) => a.isUnlocked).toList();
    }

    if (filter.category != null) {
      filtered = filtered.where((a) => a.category == filter.category).toList();
    }

    if (filter.difficulty != null) {
      filtered = filtered.where((a) => a.difficulty == filter.difficulty).toList();
    }

    if (filter.unlockedAfter != null) {
      filtered = filtered.where((a) =>
      a.unlockedAt != null && a.unlockedAt!.isAfter(filter.unlockedAfter!)
      ).toList();
    }

    return filtered;
  }

  List<Achievement> _sortAchievements(List<Achievement> achievements) {
    // Sort by: unlocked first, then by rarity (desc), then by creation date
    achievements.sort((a, b) {
      if (a.isUnlocked != b.isUnlocked) {
        return a.isUnlocked ? -1 : 1;
      }
      if (a.rarity != b.rarity) {
        return b.rarity.compareTo(a.rarity);
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return achievements;
  }
}

// Need to define Achievement class - this would typically come from a data model
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final String category;
  final String difficulty;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress;
  final double maxProgress;
  final Map<String, dynamic> requirements;
  final List<String> prerequisites;
  final bool isSecret;
  final String badgeColor;
  final int rarity;
  final List<dynamic> steps;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final bool isActive;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.category,
    required this.difficulty,
    required this.xpReward,
    required this.isUnlocked,
    this.unlockedAt,
    required this.progress,
    required this.maxProgress,
    required this.requirements,
    required this.prerequisites,
    required this.isSecret,
    required this.badgeColor,
    required this.rarity,
    required this.steps,
    required this.metadata,
    required this.createdAt,
    required this.isActive,
  });

  double get completionPercentage => (progress / maxProgress) * 100;

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, isUnlocked: $isUnlocked, progress: ${completionPercentage.toStringAsFixed(1)}%)';
  }
}

class AchievementFilter {
  final bool? unlockedOnly;
  final String? category;
  final String? difficulty;
  final DateTime? unlockedAfter;

  const AchievementFilter({
    this.unlockedOnly,
    this.category,
    this.difficulty,
    this.unlockedAfter,
  });
}

class AchievementsResult {
  final bool isSuccess;
  final List<Achievement>? achievements;
  final int? totalCount;
  final int? unlockedCount;
  final String? error;
  final String? errorCode;

  const AchievementsResult._({
    required this.isSuccess,
    this.achievements,
    this.totalCount,
    this.unlockedCount,
    this.error,
    this.errorCode,
  });

  factory AchievementsResult.success({
    required List<Achievement> achievements,
    required int totalCount,
    required int unlockedCount,
  }) {
    return AchievementsResult._(
      isSuccess: true,
      achievements: achievements,
      totalCount: totalCount,
      unlockedCount: unlockedCount,
    );
  }

  factory AchievementsResult.failure({
    required String error,
    required String errorCode,
  }) {
    return AchievementsResult._(
      isSuccess: false,
      error: error,
      errorCode: errorCode,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'AchievementsResult.success(total: $totalCount, unlocked: $unlockedCount)';
    } else {
      return 'AchievementsResult.failure(error: $error, errorCode: $errorCode)';
    }
  }
}