import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/progress.dart';

part 'learning_progress.g.dart';

@HiveType(typeId: 2)
@JsonSerializable()
class LearningProgress extends Progress {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String userId;

  @HiveField(2)
  @override
  final String category;

  @HiveField(3)
  @override
  final int completedLessons;

  @HiveField(4)
  @override
  final int totalLessons;

  @HiveField(5)
  @override
  final double progressPercentage;

  @HiveField(6)
  @override
  final DateTime lastUpdated;

  @HiveField(7)
  @override
  final DateTime startedAt;

  @HiveField(8)
  @override
  final int currentStreak;

  @HiveField(9)
  @override
  final int longestStreak;

  @HiveField(10)
  @override
  final int totalXP;

  @HiveField(11)
  @override
  final int currentLevel;

  @HiveField(12)
  @override
  final Map<String, dynamic> statistics;

  @HiveField(13)
  @override
  final List<String> masteredCommands;

  @HiveField(14)
  @override
  final List<String> weakCommands;

  @HiveField(15)
  @override
  final Map<String, int> categoryScores;

  @HiveField(16)
  @override
  final DifficultyLevel currentDifficulty;

  @HiveField(17)
  @override
  final DateTime? lastActivityDate;

  @HiveField(18)
  @override
  final int totalStudyTimeMinutes;

  @HiveField(19)
  @override
  final List<String> completedAchievements;

  const LearningProgress({
    required this.id,
    required this.userId,
    required this.category,
    required this.completedLessons,
    required this.totalLessons,
    required this.progressPercentage,
    required this.lastUpdated,
    required this.startedAt,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalXP,
    required this.currentLevel,
    required this.statistics,
    required this.masteredCommands,
    required this.weakCommands,
    required this.categoryScores,
    required this.currentDifficulty,
    this.lastActivityDate,
    required this.totalStudyTimeMinutes,
    required this.completedAchievements,
  });

  // Factory constructor for new progress
  factory LearningProgress.createNew({
    required String userId,
    required String category,
    required int totalLessons,
  }) {
    final now = DateTime.now();
    return LearningProgress(
      id: 'progress_${userId}_${category}_${now.millisecondsSinceEpoch}',
      userId: userId,
      category: category,
      completedLessons: 0,
      totalLessons: totalLessons,
      progressPercentage: 0.0,
      lastUpdated: now,
      startedAt: now,
      currentStreak: 0,
      longestStreak: 0,
      totalXP: 0,
      currentLevel: 1,
      statistics: {
        'questionsAnswered': 0,
        'correctAnswers': 0,
        'incorrectAnswers': 0,
        'averageScore': 0.0,
        'totalQuizzes': 0,
        'passedQuizzes': 0,
        'commandsExecuted': 0,
        'totalSessionTime': 0,
        'averageSessionTime': 0,
        'dailyChallengesCompleted': 0,
        'hintsUsed': 0,
        'practiceExercisesCompleted': 0,
        'terminalCommandsExecuted': 0,
      },
      masteredCommands: [],
      weakCommands: [],
      categoryScores: {
        'file_management': 0,
        'system_admin': 0,
        'network': 0,
        'text_processing': 0,
        'package_management': 0,
        'security': 0,
        'process_management': 0,
        'archive': 0,
      },
      currentDifficulty: DifficultyLevel.beginner,
      lastActivityDate: null,
      totalStudyTimeMinutes: 0,
      completedAchievements: [],
    );
  }

  // JSON serialization
  factory LearningProgress.fromJson(Map<String, dynamic> json) =>
      _$LearningProgressFromJson(json);

  Map<String, dynamic> toJson() => _$LearningProgressToJson(this);

  // From domain entity
  factory LearningProgress.fromEntity(Progress progress) {
    return LearningProgress(
      id: progress.id,
      userId: progress.userId,
      category: progress.category,
      completedLessons: progress.completedLessons,
      totalLessons: progress.totalLessons,
      progressPercentage: progress.progressPercentage,
      lastUpdated: progress.lastUpdated,
      startedAt: progress.startedAt,
      currentStreak: progress.currentStreak,
      longestStreak: progress.longestStreak,
      totalXP: progress.totalXP,
      currentLevel: progress.currentLevel,
      statistics: progress.statistics,
      masteredCommands: progress.masteredCommands,
      weakCommands: progress.weakCommands,
      categoryScores: progress.categoryScores,
      currentDifficulty: progress.currentDifficulty,
      lastActivityDate: progress.lastActivityDate,
      totalStudyTimeMinutes: progress.totalStudyTimeMinutes,
      completedAchievements: progress.completedAchievements,
    );
  }

  // Copy with method
  LearningProgress copyWith({
    int? completedLessons,
    double? progressPercentage,
    DateTime? lastUpdated,
    int? currentStreak,
    int? longestStreak,
    int? totalXP,
    int? currentLevel,
    Map<String, dynamic>? statistics,
    List<String>? masteredCommands,
    List<String>? weakCommands,
    Map<String, int>? categoryScores,
    DifficultyLevel? currentDifficulty,
    DateTime? lastActivityDate,
    int? totalStudyTimeMinutes,
    List<String>? completedAchievements,
  }) {
    return LearningProgress(
      id: id,
      userId: userId,
      category: category,
      completedLessons: completedLessons ?? this.completedLessons,
      totalLessons: totalLessons,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      startedAt: startedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalXP: totalXP ?? this.totalXP,
      currentLevel: currentLevel ?? this.currentLevel,
      statistics: statistics ?? Map.from(this.statistics),
      masteredCommands: masteredCommands ?? List.from(this.masteredCommands),
      weakCommands: weakCommands ?? List.from(this.weakCommands),
      categoryScores: categoryScores ?? Map.from(this.categoryScores),
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      totalStudyTimeMinutes: totalStudyTimeMinutes ?? this.totalStudyTimeMinutes,
      completedAchievements: completedAchievements ?? List.from(this.completedAchievements),
    );
  }

  // Helper methods
  bool get isCompleted => progressPercentage >= 100.0;
  bool get hasStarted => completedLessons > 0;

  double get completionRate => totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0.0;

  int get remainingLessons => totalLessons - completedLessons;

  bool get hasActiveStreak => currentStreak > 0 && lastActivityDate != null &&
      DateTime.now().difference(lastActivityDate!).inDays <= 1;

  double get accuracy {
    final questionsAnswered = statistics['questionsAnswered'] as int? ?? 0;
    final correctAnswers = statistics['correctAnswers'] as int? ?? 0;

    if (questionsAnswered == 0) return 0.0;
    return (correctAnswers / questionsAnswered) * 100;
  }

  double get quizPassRate {
    final totalQuizzes = statistics['totalQuizzes'] as int? ?? 0;
    final passedQuizzes = statistics['passedQuizzes'] as int? ?? 0;

    if (totalQuizzes == 0) return 0.0;
    return (passedQuizzes / totalQuizzes) * 100;
  }

  Duration get averageSessionTime {
    final avgMinutes = statistics['averageSessionTime'] as int? ?? 0;
    return Duration(minutes: avgMinutes);
  }

  Duration get totalStudyTime => Duration(minutes: totalStudyTimeMinutes);

  String get difficultyDisplayName {
    switch (currentDifficulty) {
      case DifficultyLevel.beginner:
        return 'เริ่มต้น';
      case DifficultyLevel.intermediate:
        return 'กลาง';
      case DifficultyLevel.advanced:
        return 'ขั้นสูง';
      case DifficultyLevel.expert:
        return 'ผู้เชี่ยวชาญ';
      default:
        return 'ไม่ระบุ';
    }
  }

  String get categoryDisplayName {
    const categories = {
      'file_management': 'การจัดการไฟล์',
      'system_admin': 'การจัดการระบบ',
      'network': 'เครือข่าย',
      'text_processing': 'การประมวลผลข้อความ',
      'package_management': 'การจัดการแพ็กเกจ',
      'security': 'ความปลอดภัย',
      'process_management': 'การจัดการโปรเซส',
      'archive': 'การจัดการไฟล์บีบอัด',
    };
    return categories[category] ?? category;
  }

  // Performance analysis
  Map<String, dynamic> getPerformanceAnalysis() {
    return {
      'overallScore': accuracy,
      'strengths': _getStrongestCategories(),
      'weaknesses': _getWeakestCategories(),
      'improvements': _getSuggestedImprovements(),
      'nextLevel': _getNextLevelInfo(),
      'studyPattern': _getStudyPatternAnalysis(),
    };
  }

  List<String> _getStrongestCategories() {
    return categoryScores.entries
        .where((entry) => entry.value >= 80)
        .map((entry) => entry.key)
        .toList()
      ..sort((a, b) => categoryScores[b]!.compareTo(categoryScores[a]!));
  }

  List<String> _getWeakestCategories() {
    return categoryScores.entries
        .where((entry) => entry.value < 60)
        .map((entry) => entry.key)
        .toList()
      ..sort((a, b) => categoryScores[a]!.compareTo(categoryScores[b]!));
  }

  List<String> _getSuggestedImprovements() {
    final suggestions = <String>[];

    if (accuracy < 70) {
      suggestions.add('ฝึกฝนการตอบคำถามให้มากขึ้น');
    }

    if (currentStreak < 3) {
      suggestions.add('พยายามเรียนรู้อย่างต่อเนื่องทุกวัน');
    }

    if (weakCommands.length > masteredCommands.length) {
      suggestions.add('ทบทวนคำสั่งที่ยังไม่เชี่ยวชาญ');
    }

    if (quizPassRate < 75) {
      suggestions.add('ฝึกทำแบบทดสอบให้มากขึ้น');
    }

    return suggestions;
  }

  Map<String, dynamic> _getNextLevelInfo() {
    const levelRequirements = {
      1: 100, 2: 250, 3: 500, 4: 1000, 5: 1750,
      6: 2750, 7: 4000, 8: 5500, 9: 7250, 10: 10000,
    };

    final nextLevel = currentLevel + 1;
    final requiredXP = levelRequirements[nextLevel] ?? 0;
    final remainingXP = requiredXP - totalXP;

    return {
      'nextLevel': nextLevel,
      'requiredXP': requiredXP,
      'remainingXP': remainingXP > 0 ? remainingXP : 0,
      'progressToNext': requiredXP > 0 ? (totalXP / requiredXP) * 100 : 100,
    };
  }

  Map<String, dynamic> _getStudyPatternAnalysis() {
    final totalSessions = statistics['totalQuizzes'] as int? ?? 0;
    final avgSessionTime = statistics['averageSessionTime'] as int? ?? 0;

    String pattern = 'ไม่มีข้อมูลเพียงพอ';
    if (totalSessions > 0) {
      if (avgSessionTime < 15) {
        pattern = 'เรียนรู้แบบสั้นๆ แต่บ่อย';
      } else if (avgSessionTime > 45) {
        pattern = 'เรียนรู้แบบยาวๆ ในแต่ละครั้ง';
      } else {
        pattern = 'เรียนรู้แบบปกติ';
      }
    }

    return {
      'pattern': pattern,
      'consistency': hasActiveStreak ? 'สม่ำเสมอ' : 'ไม่สม่ำเสมอ',
      'intensity': _getStudyIntensity(),
      'efficiency': _getStudyEfficiency(),
    };
  }

  String _getStudyIntensity() {
    final sessionsPerWeek = totalStudyTimeMinutes / 7 / 60; // hours per week

    if (sessionsPerWeek < 1) return 'น้อย';
    if (sessionsPerWeek < 3) return 'ปกติ';
    if (sessionsPerWeek < 6) return 'มาก';
    return 'มากมาย';
  }

  String _getStudyEfficiency() {
    final efficiency = accuracy * (quizPassRate / 100);

    if (efficiency < 40) return 'ต่ำ';
    if (efficiency < 60) return 'ปกติ';
    if (efficiency < 80) return 'ดี';
    return 'ยอดเยี่ยม';
  }

  // Update methods
  LearningProgress completeLesson() {
    final newCompleted = completedLessons + 1;
    final newProgress = (newCompleted / totalLessons) * 100;

    return copyWith(
      completedLessons: newCompleted,
      progressPercentage: newProgress.clamp(0.0, 100.0),
      lastUpdated: DateTime.now(),
      lastActivityDate: DateTime.now(),
    );
  }

  LearningProgress addXP(int xp) {
    final newXP = totalXP + xp;
    final newLevel = _calculateLevel(newXP);

    return copyWith(
      totalXP: newXP,
      currentLevel: newLevel,
      lastUpdated: DateTime.now(),
      lastActivityDate: DateTime.now(),
    );
  }

  int _calculateLevel(int xp) {
    const levelRequirements = {
      1: 0, 2: 100, 3: 250, 4: 500, 5: 1000,
      6: 1750, 7: 2750, 8: 4000, 9: 5500, 10: 7250,
    };

    for (int level = 10; level >= 1; level--) {
      if (xp >= (levelRequirements[level] ?? 0)) {
        return level;
      }
    }
    return 1;
  }

  LearningProgress updateStreak() {
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));

    int newStreak = currentStreak;

    if (lastActivityDate == null) {
      newStreak = 1;
    } else {
      final daysSinceLastActivity = now.difference(lastActivityDate!).inDays;

      if (daysSinceLastActivity == 1) {
        // Consecutive day
        newStreak = currentStreak + 1;
      } else if (daysSinceLastActivity > 1) {
        // Streak broken
        newStreak = 1;
      }
      // If same day, keep current streak
    }

    final newLongestStreak = newStreak > longestStreak ? newStreak : longestStreak;

    return copyWith(
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastActivityDate: now,
      lastUpdated: now,
    );
  }

  @override
  String toString() {
    return 'LearningProgress(id: $id, category: $category, progress: ${progressPercentage.toStringAsFixed(1)}%, level: $currentLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearningProgress && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Hive Adapter for DifficultyLevel enum
@HiveType(typeId: 5)
enum DifficultyLevel {
  @HiveField(0)
  beginner,

  @HiveField(1)
  intermediate,

  @HiveField(2)
  advanced,

  @HiveField(3)
  expert,
}