abstract class Progress {
  const Progress();

  String get id;
  String get userId;
  String get category;
  int get completedLessons;
  int get totalLessons;
  double get progressPercentage;
  DateTime get lastUpdated;
  DateTime get startedAt;
  int get currentStreak;
  int get longestStreak;
  int get totalXP;
  int get currentLevel;
  Map<String, dynamic> get statistics;
  List<String> get masteredCommands;
  List<String> get weakCommands;
  Map<String, int> get categoryScores;
  DifficultyLevel get currentDifficulty;
  DateTime? get lastActivityDate;
  int get totalStudyTimeMinutes;
  List<String> get completedAchievements;

  // Helper methods
  bool get isCompleted => progressPercentage >= 100.0;
  bool get hasStarted => completedLessons > 0;
  double get completionRate => totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0.0;
  int get remainingLessons => totalLessons - completedLessons;
  bool get hasActiveStreak => currentStreak > 0 && lastActivityDate != null &&
      DateTime.now().difference(lastActivityDate!).inDays <= 1;
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}