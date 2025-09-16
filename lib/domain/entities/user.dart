abstract class User {
  const User();

  String get id;
  String get name;
  String get email;
  String? get avatar;
  DateTime get createdAt;
  DateTime get lastLoginAt;
  String get skillLevel;
  int get currentXP;
  int get currentLevel;
  int get totalPoints;
  int get streakDays;
  DateTime? get lastActivityDate;
  List<String> get completedLessons;
  List<String> get unlockedAchievements;
  Map<String, dynamic> get preferences;
  Map<String, int> get categoryProgress;
  List<String> get favoriteCommands;
  Map<String, dynamic> get stats;

  // Helper methods that can be overridden by implementations
  bool get isNewUser => completedLessons.isEmpty && currentLevel == 1;
  bool get hasActiveStreak => streakDays > 0 && lastActivityDate != null &&
      DateTime.now().difference(lastActivityDate!).inDays <= 1;
  String get skillLevelDisplayName {
    const levels = {
      'beginner': 'เริ่มต้น',
      'intermediate': 'กลาง',
      'advanced': 'ขั้นสูง',
      'expert': 'ผู้เชี่ยวชาญ',
    };
    return levels[skillLevel] ?? 'ไม่ระบุ';
  }
}