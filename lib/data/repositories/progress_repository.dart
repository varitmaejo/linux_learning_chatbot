import 'dart:async';

import '../../domain/entities/progress.dart';
import '../../domain/repositories/progress_repository_interface.dart';
import '../models/learning_progress.dart';
import '../models/achievement.dart';
import '../datasources/local/hive_datasource.dart';
import '../datasources/local/shared_prefs_datasource.dart';
import '../datasources/remote/firebase_datasource.dart';

class ProgressRepository implements ProgressRepositoryInterface {
  final HiveDatasource _localDataSource;
  final SharedPrefsDatasource _prefsDataSource;
  final FirebaseDatasource _remoteDataSource;

  ProgressRepository({
    required HiveDatasource localDataSource,
    required SharedPrefsDatasource prefsDataSource,
    required FirebaseDatasource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _prefsDataSource = prefsDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<Progress?> getUserProgress(String userId, String category) async {
    try {
      // Try local storage first
      final localProgress = await _localDataSource.getProgress(userId);
      if (localProgress != null && localProgress.category == category) {
        return localProgress;
      }

      // Try remote storage
      if (_remoteDataSource.isAuthenticated) {
        final remoteProgress = await _remoteDataSource.getProgress(userId, category);
        if (remoteProgress != null) {
          // Cache locally
          await _localDataSource.saveProgress(userId, remoteProgress);
          return remoteProgress;
        }
      }

      return null;
    } catch (error) {
      throw Exception('Failed to get user progress: $error');
    }
  }

  @override
  Future<List<Progress>> getAllUserProgress(String userId) async {
    try {
      List<LearningProgress> allProgress = [];

      // Get from remote if available
      if (_remoteDataSource.isAuthenticated) {
        try {
          allProgress = await _remoteDataSource.getAllProgress(userId);

          // Cache all progress locally
          for (final progress in allProgress) {
            await _localDataSource.saveProgress(userId, progress);
          }
        } catch (remoteError) {
          print('Warning: Failed to get progress from remote: $remoteError');
        }
      }

      // If no remote data, try local
      if (allProgress.isEmpty) {
        // For local storage, we need to implement a way to get all progress
        // This is a simplified version - in practice, you'd store multiple progress records
        final localProgress = await _localDataSource.getProgress(userId);
        if (localProgress != null) {
          allProgress = [localProgress];
        }
      }

      return allProgress.cast<Progress>();
    } catch (error) {
      throw Exception('Failed to get all user progress: $error');
    }
  }

  @override
  Future<Progress> createProgress({
    required String userId,
    required String category,
    required int totalLessons,
  }) async {
    try {
      final newProgress = LearningProgress.createNew(
        userId: userId,
        category: category,
        totalLessons: totalLessons,
      );

      // Save to local storage
      await _localDataSource.saveProgress(userId, newProgress);

      // Save to remote if connected
      if (_remoteDataSource.isAuthenticated) {
        try {
          await _remoteDataSource.saveProgress(newProgress);
        } catch (remoteError) {
          print('Warning: Failed to save progress to remote: $remoteError');
        }
      }

      return newProgress;
    } catch (error) {
      throw Exception('Failed to create progress: $error');
    }
  }

  @override
  Future<Progress> updateProgress(
      String userId,
      String category,
      Map<String, dynamic> updates,
      ) async {
    try {
      final currentProgress = await getUserProgress(userId, category);

      if (currentProgress == null) {
        throw Exception('Progress not found for category: $category');
      }

      final progressModel = currentProgress is LearningProgress
          ? currentProgress
          : LearningProgress.fromEntity(currentProgress);

      // Apply updates
      final updatedProgress = progressModel.copyWith(
        completedLessons: updates['completedLessons'],
        progressPercentage: updates['progressPercentage'],
        lastUpdated: DateTime.now(),
        currentStreak: updates['currentStreak'],
        longestStreak: updates['longestStreak'],
        totalXP: updates['totalXP'],
        currentLevel: updates['currentLevel'],
        statistics: updates['statistics'],
        masteredCommands: updates['masteredCommands'],
        weakCommands: updates['weakCommands'],
        categoryScores: updates['categoryScores'],
        currentDifficulty: updates['currentDifficulty'],
        lastActivityDate: updates['lastActivityDate'] ?? DateTime.now(),
        totalStudyTimeMinutes: updates['totalStudyTimeMinutes'],
        completedAchievements: updates['completedAchievements'],
      );

      // Save to local storage
      await _localDataSource.saveProgress(userId, updatedProgress);

      // Save to remote if connected
      if (_remoteDataSource.isAuthenticated) {
        try {
          await _remoteDataSource.saveProgress(updatedProgress);
        } catch (remoteError) {
          print('Warning: Failed to update progress on remote: $remoteError');
        }
      }

      return updatedProgress;
    } catch (error) {
      throw Exception('Failed to update progress: $error');
    }
  }

  @override
  Future<Progress> completeLesson(
      String userId,
      String category,
      String lessonId,
      ) async {
    try {
      var progress = await getUserProgress(userId, category);

      // Create new progress if it doesn't exist
      if (progress == null) {
        progress = await createProgress(
          userId: userId,
          category: category,
          totalLessons: 100, // Default value, should be configured per category
        );
      }

      final progressModel = progress is LearningProgress
          ? progress
          : LearningProgress.fromEntity(progress);

      // Update progress for completed lesson
      final updatedProgress = progressModel.completeLesson();

      // Update statistics
      final newStats = Map<String, dynamic>.from(updatedProgress.statistics);
      newStats['completedLessons'] = (newStats['completedLessons'] as int? ?? 0) + 1;
      newStats['lastLessonCompleted'] = lessonId;
      newStats['lastLessonCompletedAt'] = DateTime.now().toIso8601String();

      return await updateProgress(userId, category, {
        'completedLessons': updatedProgress.completedLessons,
        'progressPercentage': updatedProgress.progressPercentage,
        'statistics': newStats,
        'lastActivityDate': DateTime.now(),
      });
    } catch (error) {
      throw Exception('Failed to complete lesson: $error');
    }
  }

  @override
  Future<Progress> addXP(String userId, String category, int xp) async {
    try {
      var progress = await getUserProgress(userId, category);

      if (progress == null) {
        progress = await createProgress(
          userId: userId,
          category: category,
          totalLessons: 100,
        );
      }

      final progressModel = progress is LearningProgress
          ? progress
          : LearningProgress.fromEntity(progress);

      // Add XP and update level
      final updatedProgress = progressModel.addXP(xp);

      return await updateProgress(userId, category, {
        'totalXP': updatedProgress.totalXP,
        'currentLevel': updatedProgress.currentLevel,
        'lastActivityDate': DateTime.now(),
      });
    } catch (error) {
      throw Exception('Failed to add XP: $error');
    }
  }

  @override
  Future<Progress> updateStreak(String userId, String category) async {
    try {
      var progress = await getUserProgress(userId, category);

      if (progress == null) {
        progress = await createProgress(
          userId: userId,
          category: category,
          totalLessons: 100,
        );
      }

      final progressModel = progress is LearningProgress
          ? progress
          : LearningProgress.fromEntity(progress);

      // Update streak
      final updatedProgress = progressModel.updateStreak();

      return await updateProgress(userId, category, {
        'currentStreak': updatedProgress.currentStreak,
        'longestStreak': updatedProgress.longestStreak,
        'lastActivityDate': updatedProgress.lastActivityDate,
      });
    } catch (error) {
      throw Exception('Failed to update streak: $error');
    }
  }

  @override
  Future<Progress> addMasteredCommand(
      String userId,
      String category,
      String command,
      ) async {
    try {
      final progress = await getUserProgress(userId, category);

      if (progress == null) {
        throw Exception('Progress not found for category: $category');
      }

      final progressModel = progress is LearningProgress
          ? progress
          : LearningProgress.fromEntity(progress);

      final updatedMastered = List<String>.from(progressModel.masteredCommands);
      final updatedWeak = List<String>.from(progressModel.weakCommands);

      if (!updatedMastered.contains(command)) {
        updatedMastered.add(command);
        updatedWeak.remove(command); // Remove from weak if it was there

        return await updateProgress(userId, category, {
          'masteredCommands': updatedMastered,
          'weakCommands': updatedWeak,
          'lastActivityDate': DateTime.now(),
        });
      }

      return progressModel;
    } catch (error) {
      throw Exception('Failed to add mastered command: $error');
    }
  }

  @override
  Future<Progress> addWeakCommand(
      String userId,
      String category,
      String command,
      ) async {
    try {
      final progress = await getUserProgress(userId, category);

      if (progress == null) {
        throw Exception('Progress not found for category: $category');
      }

      final progressModel = progress is LearningProgress
          ? progress
          : LearningProgress.fromEntity(progress);

      final updatedWeak = List<String>.from(progressModel.weakCommands);

      if (!updatedWeak.contains(command) &&
          !progressModel.masteredCommands.contains(command)) {
        updatedWeak.add(command);

        return await updateProgress(userId, category, {
          'weakCommands': updatedWeak,
          'lastActivityDate': DateTime.now(),
        });
      }

      return progressModel;
    } catch (error) {
      throw Exception('Failed to add weak command: $error');
    }
  }

  @override
  Future<Progress> updateCategoryScore(
      String userId,
      String category,
      String scoreCategory,
      int score,
      ) async {
    try {
      final progress = await getUserProgress(userId, category);

      if (progress == null) {
        throw Exception('Progress not found for category: $category');
      }

      final progressModel = progress is LearningProgress
          ? progress
          : LearningProgress.fromEntity(progress);

      final updatedScores = Map<String, int>.from(progressModel.categoryScores);
      updatedScores[scoreCategory] = score;

      return await updateProgress(userId, category, {
        'categoryScores': updatedScores,
        'lastActivityDate': DateTime.now(),
      });
    } catch (error) {
      throw Exception('Failed to update category score: $error');
    }
  }

  @override
  Future<Progress> recordStudyTime(
      String userId,
      String category,
      Duration studyTime,
      ) async {
    try {
      final progress = await getUserProgress(userId, category);

      if (progress == null) {
        throw Exception('Progress not found for category: $category');
      }

      final progressModel = progress is LearningProgress
          ? progress
          : LearningProgress.fromEntity(progress);

      final newTotalMinutes = progressModel.totalStudyTimeMinutes + studyTime.inMinutes;

      // Update statistics
      final newStats = Map<String, dynamic>.from(progressModel.statistics);
      newStats['totalSessionTime'] = (newStats['totalSessionTime'] as int? ?? 0) + studyTime.inMinutes;

      // Calculate average session time
      final totalSessions = (newStats['totalQuizzes'] as int? ?? 0) + 1;
      newStats['averageSessionTime'] = newTotalMinutes ~/ totalSessions;

      return await updateProgress(userId, category, {
        'totalStudyTimeMinutes': newTotalMinutes,
        'statistics': newStats,
        'lastActivityDate': DateTime.now(),
      });
    } catch (error) {
      throw Exception('Failed to record study time: $error');
    }
  }

  @override
  Future<Progress> recordQuizResult(
      String userId,
      String category, {
        required int score,
        required int totalQuestions,
        required bool passed,
        Map<String, dynamic>? quizMetadata,
      }) async {
    try {
      final progress = await getUserProgress(userId, category);

      if (progress == null) {
        throw Exception('Progress not found for category: $category');
      }

      final progressModel = progress is LearningProgress
          ? progress
          : LearningProgress.fromEntity(progress);

      // Update statistics
      final newStats = Map<String, dynamic>.from(progressModel.statistics);
      newStats['totalQuizzes'] = (newStats['totalQuizzes'] as int? ?? 0) + 1;
      newStats['questionsAnswered'] = (newStats['questionsAnswered'] as int? ?? 0) + totalQuestions;
      newStats['correctAnswers'] = (newStats['correctAnswers'] as int? ?? 0) + score;
      newStats['incorrectAnswers'] = (newStats['incorrectAnswers'] as int? ?? 0) + (totalQuestions - score);

      if (passed) {
        newStats['passedQuizzes'] = (newStats['passedQuizzes'] as int? ?? 0) + 1;
      }

      // Calculate average score
      final totalCorrect = newStats['correctAnswers'] as int;
      final totalAnswered = newStats['questionsAnswered'] as int;
      newStats['averageScore'] = totalAnswered > 0 ? (totalCorrect / totalAnswered) * 100 : 0.0;

      // Add quiz metadata if provided
      if (quizMetadata != null) {
        newStats['lastQuizScore'] = score;
        newStats['lastQuizTotalQuestions'] = totalQuestions;
        newStats['lastQuizPassed'] = passed;
        newStats['lastQuizAt'] = DateTime.now().toIso8601String();
        newStats.addAll(quizMetadata);
      }

      return await updateProgress(userId, category, {
        'statistics': newStats,
        'lastActivityDate': DateTime.now(),
      });
    } catch (error) {
      throw Exception('Failed to record quiz result: $error');
    }
  }

  @override
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      // Get achievements from local storage first
      final localAchievements = await _localDataSource.getAchievements(userId);

      // Try to get from remote if connected
      if (_remoteDataSource.isAuthenticated) {
        try {
          final remoteAchievements = await _remoteDataSource.getAchievements(userId);

          // Merge achievements (prefer remote)
          final achievementMap = <String, Achievement>{};

          // Add local achievements
          for (final achievement in localAchievements) {
            achievementMap[achievement.id] = achievement;
          }

          // Override with remote achievements
          for (final achievement in remoteAchievements) {
            achievementMap[achievement.id] = achievement;
          }

          final mergedAchievements = achievementMap.values.toList();

          // Cache merged achievements locally
          for (final achievement in mergedAchievements) {
            await _localDataSource.saveAchievement(achievement);
          }

          return mergedAchievements;
        } catch (remoteError) {
          print('Warning: Failed to get achievements from remote: $remoteError');
        }
      }

      return localAchievements;
    } catch (error) {
      throw Exception('Failed to get user achievements: $error');
    }
  }

  @override
  Future<Achievement> unlockAchievement(String userId, String achievementId) async {
    try {
      // Check if already unlocked
      final isAlreadyUnlocked = await _localDataSource.isAchievementUnlocked(userId, achievementId);

      if (isAlreadyUnlocked) {
        final existingAchievements = await getUserAchievements(userId);
        final existingAchievement = existingAchievements
            .where((a) => a.id == achievementId)
            .firstOrNull;

        if (existingAchievement != null) {
          return existingAchievement;
        }
      }

      // Create achievement (this would typically come from a predefined list)
      final achievement = _createAchievement(userId, achievementId);
      final unlockedAchievement = achievement.unlock();

      // Save to local storage
      await _localDataSource.saveAchievement(unlockedAchievement);

      // Save to remote if connected
      if (_remoteDataSource.isAuthenticated) {
        try {
          await _remoteDataSource.saveAchievement(unlockedAchievement);
        } catch (remoteError) {
          print('Warning: Failed to save achievement to remote: $remoteError');
        }
      }

      return unlockedAchievement;
    } catch (error) {
      throw Exception('Failed to unlock achievement: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> getOverallProgress(String userId) async {
    try {
      final allProgress = await getAllUserProgress(userId);

      if (allProgress.isEmpty) {
        return {
          'totalXP': 0,
          'currentLevel': 1,
          'overallProgress': 0.0,
          'completedCategories': 0,
          'totalCategories': 8, // Based on AppConstants.commandCategories
          'averageScore': 0.0,
          'totalStudyTime': 0,
          'longestStreak': 0,
          'currentStreak': 0,
          'categoriesProgress': <String, double>{},
        };
      }

      // Calculate overall statistics
      int totalXP = 0;
      int maxLevel = 1;
      double totalProgress = 0;
      int completedCategories = 0;
      int totalStudyTime = 0;
      int longestStreak = 0;
      int currentStreak = 0;
      double totalScore = 0;
      int scoreCount = 0;

      final categoriesProgress = <String, double>{};

      for (final progress in allProgress) {
        totalXP += progress.totalXP;
        maxLevel = progress.currentLevel > maxLevel ? progress.currentLevel : maxLevel;
        totalProgress += progress.progressPercentage;
        totalStudyTime += progress.totalStudyTimeMinutes;
        longestStreak = progress.longestStreak > longestStreak ? progress.longestStreak : longestStreak;

        // Use the highest current streak
        if (progress.hasActiveStreak && progress.currentStreak > currentStreak) {
          currentStreak = progress.currentStreak;
        }

        if (progress.progressPercentage >= 100) {
          completedCategories++;
        }

        // Calculate average score for this category
        final stats = progress.statistics;
        final categoryScore = stats['averageScore'] as num? ?? 0;
        if (categoryScore > 0) {
          totalScore += categoryScore.toDouble();
          scoreCount++;
        }

        categoriesProgress[progress.category] = progress.progressPercentage;
      }

      final averageProgress = allProgress.isNotEmpty ? totalProgress / allProgress.length : 0.0;
      final averageScore = scoreCount > 0 ? totalScore / scoreCount : 0.0;

      return {
        'totalXP': totalXP,
        'currentLevel': maxLevel,
        'overallProgress': averageProgress,
        'completedCategories': completedCategories,
        'totalCategories': 8,
        'averageScore': averageScore,
        'totalStudyTime': totalStudyTime,
        'longestStreak': longestStreak,
        'currentStreak': currentStreak,
        'categoriesProgress': categoriesProgress,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (error) {
      throw Exception('Failed to get overall progress: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> getProgressAnalytics(String userId) async {
    try {
      final allProgress = await getAllUserProgress(userId);
      final overallProgress = await getOverallProgress(userId);
      final achievements = await getUserAchievements(userId);

      // Calculate learning velocity (XP gained per day)
      double learningVelocity = 0;
      if (allProgress.isNotEmpty) {
        final firstProgress = allProgress.reduce((a, b) => a.startedAt.isBefore(b.startedAt) ? a : b);
        final daysSinceStart = DateTime.now().difference(firstProgress.startedAt).inDays;
        if (daysSinceStart > 0) {
          learningVelocity = (overallProgress['totalXP'] as int) / daysSinceStart;
        }
      }

      // Find strongest and weakest categories
      final categoriesProgress = overallProgress['categoriesProgress'] as Map<String, double>;
      var strongestCategory = '';
      var weakestCategory = '';
      double highestProgress = 0;
      double lowestProgress = 100;

      categoriesProgress.forEach((category, progress) {
        if (progress > highestProgress) {
          highestProgress = progress;
          strongestCategory = category;
        }
        if (progress < lowestProgress) {
          lowestProgress = progress;
          weakestCategory = category;
        }
      });

      // Calculate study consistency (days studied in last 30 days)
      int studyDaysInLast30 = 0;
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

      for (final progress in allProgress) {
        if (progress.lastActivityDate != null &&
            progress.lastActivityDate!.isAfter(thirtyDaysAgo)) {
          studyDaysInLast30++;
        }
      }

      return {
        'overallProgress': overallProgress,
        'learningVelocity': learningVelocity,
        'strongestCategory': strongestCategory,
        'weakestCategory': weakestCategory,
        'studyConsistency': (studyDaysInLast30 / 30) * 100,
        'unlockedAchievements': achievements.length,
        'totalAchievementsAvailable': _getTotalAvailableAchievements(),
        'studyStreak': {
          'current': overallProgress['currentStreak'],
          'longest': overallProgress['longestStreak'],
          'isActive': overallProgress['currentStreak'] > 0,
        },
        'recommendations': _generateRecommendations(allProgress, categoriesProgress),
        'nextMilestone': _getNextMilestone(overallProgress['totalXP'] as int),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (error) {
      throw Exception('Failed to get progress analytics: $error');
    }
  }

  @override
  Future<void> syncWithRemote(String userId) async {
    try {
      if (!_remoteDataSource.isAuthenticated) {
        return;
      }

      // Sync all progress categories
      final localProgress = await getAllUserProgress(userId);
      final remoteProgress = await _remoteDataSource.getAllProgress(userId);

      // Merge progress (prefer latest update)
      final mergedProgress = <String, Progress>{};

      // Add local progress
      for (final progress in localProgress) {
        mergedProgress['${progress.userId}_${progress.category}'] = progress;
      }

      // Override with remote if newer
      for (final progress in remoteProgress) {
        final key = '${progress.userId}_${progress.category}';
        final localVersion = mergedProgress[key];

        if (localVersion == null || progress.lastUpdated.isAfter(localVersion.lastUpdated)) {
          mergedProgress[key] = progress;
        }
      }

      // Save merged progress
      for (final progress in mergedProgress.values) {
        final progressModel = progress is LearningProgress
            ? progress
            : LearningProgress.fromEntity(progress);

        await _localDataSource.saveProgress(userId, progressModel);
        await _remoteDataSource.saveProgress(progressModel);
      }

    } catch (error) {
      throw Exception('Failed to sync with remote: $error');
    }
  }

  @override
  Stream<List<Progress>> getProgressStream(String userId) {
    if (_remoteDataSource.isAuthenticated) {
      return _remoteDataSource.getProgressStream(userId);
    } else {
      // Return single emission for local data
      return Stream.fromFuture(getAllUserProgress(userId));
    }
  }

  // Private helper methods
  Achievement _createAchievement(String userId, String achievementId) {
    // This would typically load from a predefined achievements list
    switch (achievementId) {
      case 'first_login':
        return Achievement.firstLogin(userId);
      case 'first_command':
        return Achievement.firstCommand(userId);
      case 'week_streak':
        return Achievement.weekStreak(userId);
      case 'month_streak':
        return Achievement.monthStreak(userId);
      case 'perfect_quiz':
        return Achievement.perfectQuiz(userId);
      default:
        throw Exception('Unknown achievement ID: $achievementId');
    }
  }

  int _getTotalAvailableAchievements() {
    // This would be loaded from configuration
    return 50; // Placeholder
  }

  List<String> _generateRecommendations(
      List<Progress> allProgress,
      Map<String, double> categoriesProgress,
      ) {
    final recommendations = <String>[];

    // Find categories that need attention
    categoriesProgress.forEach((category, progress) {
      if (progress < 50) {
        recommendations.add('เพิ่มการเรียนรู้ในหมวด $category');
      }
    });

    // Check for inactive users
    final hasRecentActivity = allProgress.any((p) =>
    p.lastActivityDate != null &&
        DateTime.now().difference(p.lastActivityDate!).inDays < 3);

    if (!hasRecentActivity) {
      recommendations.add('กลับมาเรียนรู้อีกครั้งเพื่อรักษาความต่อเนื่อง');
    }

    return recommendations;
  }

  Map<String, dynamic> _getNextMilestone(int currentXP) {
    const milestones = {
      100: 'เลเวล 2',
      250: 'เลเวล 3',
      500: 'เลเวล 4',
      1000: 'เลเวล 5',
      1750: 'เลเวล 6',
      2750: 'เลเวล 7',
      4000: 'เลเวล 8',
      5500: 'เลเวล 9',
      7250: 'เลเวล 10 (สูงสุด)',
    };

    for (final entry in milestones.entries) {
      if (currentXP < entry.key) {
        return {
          'xpRequired': entry.key,
          'xpRemaining': entry.key - currentXP,
          'milestone': entry.value,
          'progress': (currentXP / entry.key) * 100,
        };
      }
    }

    // Already at max level
    return {
      'xpRequired': 7250,
      'xpRemaining': 0,
      'milestone': 'เลเวลสูงสุดแล้ว!',
      'progress': 100.0,
    };
  }
}