import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class UserModel extends User {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String name;

  @HiveField(2)
  @override
  final String email;

  @HiveField(3)
  @override
  final String? avatar;

  @HiveField(4)
  @override
  final DateTime createdAt;

  @HiveField(5)
  @override
  final DateTime lastLoginAt;

  @HiveField(6)
  @override
  final String skillLevel;

  @HiveField(7)
  @override
  final int currentXP;

  @HiveField(8)
  @override
  final int currentLevel;

  @HiveField(9)
  @override
  final int totalPoints;

  @HiveField(10)
  @override
  final int streakDays;

  @HiveField(11)
  @override
  final DateTime? lastActivityDate;

  @HiveField(12)
  @override
  final List<String> completedLessons;

  @HiveField(13)
  @override
  final List<String> unlockedAchievements;

  @HiveField(14)
  @override
  final Map<String, dynamic> preferences;

  @HiveField(15)
  @override
  final Map<String, int> categoryProgress;

  @HiveField(16)
  @override
  final List<String> favoriteCommands;

  @HiveField(17)
  @override
  final Map<String, dynamic> stats;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.createdAt,
    required this.lastLoginAt,
    required this.skillLevel,
    required this.currentXP,
    required this.currentLevel,
    required this.totalPoints,
    required this.streakDays,
    this.lastActivityDate,
    required this.completedLessons,
    required this.unlockedAchievements,
    required this.preferences,
    required this.categoryProgress,
    required this.favoriteCommands,
    required this.stats,
  });

  // Factory constructor for creating default user
  factory UserModel.defaultUser() {
    final now = DateTime.now();
    return UserModel(
      id: 'user_${now.millisecondsSinceEpoch}',
      name: 'ผู้เรียนใหม่',
      email: '',
      avatar: null,
      createdAt: now,
      lastLoginAt: now,
      skillLevel: 'beginner',
      currentXP: 0,
      currentLevel: 1,
      totalPoints: 0,
      streakDays: 0,
      lastActivityDate: null,
      completedLessons: [],
      unlockedAchievements: [],
      preferences: {
        'language': 'th',
        'theme': 'system',
        'notifications': true,
        'sound': true,
        'voice': false,
        'fontSize': 'medium',
      },
      categoryProgress: {
        'file_management': 0,
        'system_admin': 0,
        'network': 0,
        'text_processing': 0,
        'package_management': 0,
        'security': 0,
        'process_management': 0,
        'archive': 0,
      },
      favoriteCommands: [],
      stats: {
        'totalCommandsLearned': 0,
        'totalQuestionsAnswered': 0,
        'correctAnswers': 0,
        'avgSessionTime': 0,
        'longestStreak': 0,
        'totalStudyTime': 0,
        'dailyChallengesCompleted': 0,
        'quizzesCompleted': 0,
        'terminalCommandsExecuted': 0,
      },
    );
  }

  // JSON serialization
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  // From domain entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      avatar: user.avatar,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      skillLevel: user.skillLevel,
      currentXP: user.currentXP,
      currentLevel: user.currentLevel,
      totalPoints: user.totalPoints,
      streakDays: user.streakDays,
      lastActivityDate: user.lastActivityDate,
      completedLessons: user.completedLessons,
      unlockedAchievements: user.unlockedAchievements,
      preferences: user.preferences,
      categoryProgress: user.categoryProgress,
      favoriteCommands: user.favoriteCommands,
      stats: user.stats,
    );
  }

  // Copy with method
  UserModel copyWith({
    String? name,
    String? email,
    String? avatar,
    DateTime? lastLoginAt,
    String? skillLevel,
    int? currentXP,
    int? currentLevel,
    int? totalPoints,
    int? streakDays,
    DateTime? lastActivityDate,
    List<String>? completedLessons,
    List<String>? unlockedAchievements,
    Map<String, dynamic>? preferences,
    Map<String, int>? categoryProgress,
    List<String>? favoriteCommands,
    Map<String, dynamic>? stats,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      skillLevel: skillLevel ?? this.skillLevel,
      currentXP: currentXP ?? this.currentXP,
      currentLevel: currentLevel ?? this.currentLevel,
      totalPoints: totalPoints ?? this.totalPoints,
      streakDays: streakDays ?? this.streakDays,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      completedLessons: completedLessons ?? List.from(this.completedLessons),
      unlockedAchievements: unlockedAchievements ?? List.from(this.unlockedAchievements),
      preferences: preferences ?? Map.from(this.preferences),
      categoryProgress: categoryProgress ?? Map.from(this.categoryProgress),
      favoriteCommands: favoriteCommands ?? List.from(this.favoriteCommands),
      stats: stats ?? Map.from(this.stats),
    );
  }

  // Helper methods
  bool get isNewUser => completedLessons.isEmpty && currentLevel == 1;

  bool get hasActiveStreak => streakDays > 0 && lastActivityDate != null &&
      DateTime.now().difference(lastActivityDate!).inDays <= 1;

  double get progressToNextLevel {
    const levelRequirements = {
      1: 0, 2: 100, 3: 250, 4: 500, 5: 1000,
      6: 1750, 7: 2750, 8: 4000, 9: 5500, 10: 7250,
    };

    final nextLevel = currentLevel + 1;
    if (nextLevel > 10) return 1.0;

    final currentLevelXP = levelRequirements[currentLevel] ?? 0;
    final nextLevelXP = levelRequirements[nextLevel] ?? 0;
    final progressXP = currentXP - currentLevelXP;
    final requiredXP = nextLevelXP - currentLevelXP;

    return requiredXP > 0 ? progressXP / requiredXP : 1.0;
  }

  int get xpToNextLevel {
    const levelRequirements = {
      1: 0, 2: 100, 3: 250, 4: 500, 5: 1000,
      6: 1750, 7: 2750, 8: 4000, 9: 5500, 10: 7250,
    };

    final nextLevel = currentLevel + 1;
    if (nextLevel > 10) return 0;

    final nextLevelXP = levelRequirements[nextLevel] ?? 0;
    return nextLevelXP - currentXP;
  }

  String get skillLevelDisplayName {
    const levels = {
      'beginner': 'เริ่มต้น',
      'intermediate': 'กลาง',
      'advanced': 'ขั้นสูง',
      'expert': 'ผู้เชี่ยวชาญ',
    };
    return levels[skillLevel] ?? 'ไม่ระบุ';
  }

  double get overallProgress {
    final totalCategories = categoryProgress.length;
    if (totalCategories == 0) return 0.0;

    final totalProgress = categoryProgress.values.reduce((a, b) => a + b);
    return totalProgress / (totalCategories * 100);
  }

  List<String> get strongCategories {
    return categoryProgress.entries
        .where((entry) => entry.value >= 80)
        .map((entry) => entry.key)
        .toList();
  }

  List<String> get weakCategories {
    return categoryProgress.entries
        .where((entry) => entry.value < 50)
        .map((entry) => entry.key)
        .toList();
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, level: $currentLevel, xp: $currentXP)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}