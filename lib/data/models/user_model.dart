import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String displayName;

  @HiveField(3)
  final String? photoUrl;

  @HiveField(4)
  final bool isAnonymous;

  @HiveField(5)
  final int level;

  @HiveField(6)
  final int xp;

  @HiveField(7)
  final int streak;

  @HiveField(8)
  final int totalCommandsLearned;

  @HiveField(9)
  final int totalQuizzesCompleted;

  @HiveField(10)
  final int totalTimeSpent; // in seconds

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final DateTime lastActive;

  @HiveField(14)
  final UserPreferences preferences;

  @HiveField(15)
  final String? fcmToken;

  @HiveField(16)
  final Map<String, int>? categoryProgress;

  @HiveField(17)
  final List<String>? unlockedAchievements;

  @HiveField(18)
  final UserStats? stats;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.isAnonymous,
    required this.level,
    required this.xp,
    required this.streak,
    required this.totalCommandsLearned,
    required this.totalQuizzesCompleted,
    required this.totalTimeSpent,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActive,
    required this.preferences,
    this.fcmToken,
    this.categoryProgress,
    this.unlockedAchievements,
    this.stats,
  });

  // Factory constructor from Map (Firebase)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'ผู้ใช้งาน',
      photoUrl: map['photoUrl'],
      isAnonymous: map['isAnonymous'] ?? true,
      level: map['level'] ?? 1,
      xp: map['xp'] ?? 0,
      streak: map['streak'] ?? 0,
      totalCommandsLearned: map['totalCommandsLearned'] ?? 0,
      totalQuizzesCompleted: map['totalQuizzesCompleted'] ?? 0,
      totalTimeSpent: map['totalTimeSpent'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferences: map['preferences'] != null
          ? UserPreferences.fromMap(Map<String, dynamic>.from(map['preferences']))
          : const UserPreferences(),
      fcmToken: map['fcmToken'],
      categoryProgress: map['categoryProgress'] != null
          ? Map<String, int>.from(map['categoryProgress'])
          : null,
      unlockedAchievements: map['unlockedAchievements'] != null
          ? List<String>.from(map['unlockedAchievements'])
          : null,
      stats: map['stats'] != null
          ? UserStats.fromMap(Map<String, dynamic>.from(map['stats']))
          : null,
    );
  }

  // Convert to Map (Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAnonymous': isAnonymous,
      'level': level,
      'xp': xp,
      'streak': streak,
      'totalCommandsLearned': totalCommandsLearned,
      'totalQuizzesCompleted': totalQuizzesCompleted,
      'totalTimeSpent': totalTimeSpent,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'preferences': preferences.toMap(),
      'fcmToken': fcmToken,
      'categoryProgress': categoryProgress,
      'unlockedAchievements': unlockedAchievements,
      'stats': stats?.toMap(),
    };
  }

  // Copy with method
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    int? level,
    int? xp,
    int? streak,
    int? totalCommandsLearned,
    int? totalQuizzesCompleted,
    int? totalTimeSpent,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActive,
    UserPreferences? preferences,
    String? fcmToken,
    Map<String, int>? categoryProgress,
    List<String>? unlockedAchievements,
    UserStats? stats,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      totalCommandsLearned: totalCommandsLearned ?? this.totalCommandsLearned,
      totalQuizzesCompleted: totalQuizzesCompleted ?? this.totalQuizzesCompleted,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActive: lastActive ?? this.lastActive,
      preferences: preferences ?? this.preferences,
      fcmToken: fcmToken ?? this.fcmToken,
      categoryProgress: categoryProgress ?? this.categoryProgress,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      stats: stats ?? this.stats,
    );
  }

  // Calculate XP needed for next level
  int get xpNeededForNextLevel {
    return (level * 100) - (xp % (level * 100));
  }

  // Calculate level progress percentage
  double get levelProgressPercentage {
    final currentLevelXp = xp % (level * 100);
    final totalXpForLevel = level * 100;
    return currentLevelXp / totalXpForLevel;
  }

  // Get user rank/title based on level
  String get rank {
    if (level <= 5) return 'มือใหม่';
    if (level <= 10) return 'ผู้เรียนรู้';
    if (level <= 20) return 'ผู้ใช้งาน';
    if (level <= 35) return 'ผู้เชี่ยวชาญ';
    if (level <= 50) return 'ผู้ช่วยสอน';
    return 'เซียนลีนุกซ์';
  }

  // Check if user is active (last active within 7 days)
  bool get isActiveUser {
    final daysSinceActive = DateTime.now().difference(lastActive).inDays;
    return daysSinceActive <= 7;
  }

  // Get total learning time in hours
  double get totalLearningHours {
    return totalTimeSpent / 3600.0;
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    isAnonymous,
    level,
    xp,
    streak,
    totalCommandsLearned,
    totalQuizzesCompleted,
    totalTimeSpent,
    createdAt,
    updatedAt,
    lastActive,
    preferences,
    fcmToken,
    categoryProgress,
    unlockedAchievements,
    stats,
  ];
}

@HiveType(typeId: 1)
class UserPreferences extends Equatable {
  @HiveField(0)
  final String theme; // 'light', 'dark', 'system'

  @HiveField(1)
  final String language; // 'th', 'en'

  @HiveField(2)
  final bool enableNotifications;

  @HiveField(3)
  final bool enableSounds;

  @HiveField(4)
  final bool enableVibration;

  @HiveField(5)
  final bool enableVoiceInput;

  @HiveField(6)
  final bool enableVoiceOutput;

  @HiveField(7)
  final double voiceSpeed; // 0.5 to 2.0

  @HiveField(8)
  final String voiceLanguage; // 'th-TH', 'en-US'

  @HiveField(9)
  final bool autoPlayVoice;

  @HiveField(10)
  final bool showHints;

  @HiveField(11)
  final String difficultyLevel; // 'beginner', 'intermediate', 'advanced'

  @HiveField(12)
  final List<String> interestedCategories;

  @HiveField(13)
  final bool enableAnalytics;

  @HiveField(14)
  final int dailyGoalMinutes;

  const UserPreferences({
    this.theme = 'system',
    this.language = 'th',
    this.enableNotifications = true,
    this.enableSounds = true,
    this.enableVibration = true,
    this.enableVoiceInput = true,
    this.enableVoiceOutput = true,
    this.voiceSpeed = 1.0,
    this.voiceLanguage = 'th-TH',
    this.autoPlayVoice = false,
    this.showHints = true,
    this.difficultyLevel = 'beginner',
    this.interestedCategories = const [],
    this.enableAnalytics = true,
    this.dailyGoalMinutes = 30,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      theme: map['theme'] ?? 'system',
      language: map['language'] ?? 'th',
      enableNotifications: map['enableNotifications'] ?? true,
      enableSounds: map['enableSounds'] ?? true,
      enableVibration: map['enableVibration'] ?? true,
      enableVoiceInput: map['enableVoiceInput'] ?? true,
      enableVoiceOutput: map['enableVoiceOutput'] ?? true,
      voiceSpeed: (map['voiceSpeed'] ?? 1.0).toDouble(),
      voiceLanguage: map['voiceLanguage'] ?? 'th-TH',
      autoPlayVoice: map['autoPlayVoice'] ?? false,
      showHints: map['showHints'] ?? true,
      difficultyLevel: map['difficultyLevel'] ?? 'beginner',
      interestedCategories: List<String>.from(map['interestedCategories'] ?? []),
      enableAnalytics: map['enableAnalytics'] ?? true,
      dailyGoalMinutes: map['dailyGoalMinutes'] ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'language': language,
      'enableNotifications': enableNotifications,
      'enableSounds': enableSounds,
      'enableVibration': enableVibration,
      'enableVoiceInput': enableVoiceInput,
      'enableVoiceOutput': enableVoiceOutput,
      'voiceSpeed': voiceSpeed,
      'voiceLanguage': voiceLanguage,
      'autoPlayVoice': autoPlayVoice,
      'showHints': showHints,
      'difficultyLevel': difficultyLevel,
      'interestedCategories': interestedCategories,
      'enableAnalytics': enableAnalytics,
      'dailyGoalMinutes': dailyGoalMinutes,
    };
  }

  UserPreferences copyWith({
    String? theme,
    String? language,
    bool? enableNotifications,
    bool? enableSounds,
    bool? enableVibration,
    bool? enableVoiceInput,
    bool? enableVoiceOutput,
    double? voiceSpeed,
    String? voiceLanguage,
    bool? autoPlayVoice,
    bool? showHints,
    String? difficultyLevel,
    List<String>? interestedCategories,
    bool? enableAnalytics,
    int? dailyGoalMinutes,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSounds: enableSounds ?? this.enableSounds,
      enableVibration: enableVibration ?? this.enableVibration,
      enableVoiceInput: enableVoiceInput ?? this.enableVoiceInput,
      enableVoiceOutput: enableVoiceOutput ?? this.enableVoiceOutput,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      autoPlayVoice: autoPlayVoice ?? this.autoPlayVoice,
      showHints: showHints ?? this.showHints,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      interestedCategories: interestedCategories ?? this.interestedCategories,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
    );
  }

  @override
  List<Object?> get props => [
    theme,
    language,
    enableNotifications,
    enableSounds,
    enableVibration,
    enableVoiceInput,
    enableVoiceOutput,
    voiceSpeed,
    voiceLanguage,
    autoPlayVoice,
    showHints,
    difficultyLevel,
    interestedCategories,
    enableAnalytics,
    dailyGoalMinutes,
  ];
}

@HiveType(typeId: 2)
class UserStats extends Equatable {
  @HiveField(0)
  final int commandsPracticed;

  @HiveField(1)
  final int perfectScores;

  @HiveField(2)
  final int hintsUsed;

  @HiveField(3)
  final int longestStreak;

  @HiveField(4)
  final DateTime? lastPracticeDate;

  @HiveField(5)
  final Map<String, int> categoryScores;

  @HiveField(6)
  final Map<String, int> weeklyActivity;

  @HiveField(7)
  final double averageSessionTime;

  @HiveField(8)
  final int totalSessions;

  const UserStats({
    this.commandsPracticed = 0,
    this.perfectScores = 0,
    this.hintsUsed = 0,
    this.longestStreak = 0,
    this.lastPracticeDate,
    this.categoryScores = const {},
    this.weeklyActivity = const {},
    this.averageSessionTime = 0.0,
    this.totalSessions = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      commandsPracticed: map['commandsPracticed'] ?? 0,
      perfectScores: map['perfectScores'] ?? 0,
      hintsUsed: map['hintsUsed'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastPracticeDate: map['lastPracticeDate'] != null
          ? (map['lastPracticeDate'] as Timestamp).toDate()
          : null,
      categoryScores: Map<String, int>.from(map['categoryScores'] ?? {}),
      weeklyActivity: Map<String, int>.from(map['weeklyActivity'] ?? {}),
      averageSessionTime: (map['averageSessionTime'] ?? 0.0).toDouble(),
      totalSessions: map['totalSessions'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commandsPracticed': commandsPracticed,
      'perfectScores': perfectScores,
      'hintsUsed': hintsUsed,
      'longestStreak': longestStreak,
      'lastPracticeDate': lastPracticeDate != null
          ? Timestamp.fromDate(lastPracticeDate!)
          : null,
      'categoryScores': categoryScores,
      'weeklyActivity': weeklyActivity,
      'averageSessionTime': averageSessionTime,
      'totalSessions': totalSessions,
    };
  }

  UserStats copyWith({
    int? commandsPracticed,
    int? perfectScores,
    int? hintsUsed,
    int? longestStreak,
    DateTime? lastPracticeDate,
    Map<String, int>? categoryScores,
    Map<String, int>? weeklyActivity,
    double? averageSessionTime,
    int? totalSessions,
  }) {
    return UserStats(
      commandsPracticed: commandsPracticed ?? this.commandsPracticed,
      perfectScores: perfectScores ?? this.perfectScores,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
      categoryScores: categoryScores ?? this.categoryScores,
      weeklyActivity: weeklyActivity ?? this.weeklyActivity,
      averageSessionTime: averageSessionTime ?? this.averageSessionTime,
      totalSessions: totalSessions ?? this.totalSessions,
    );
  }

  // Calculate accuracy percentage
  double get accuracyPercentage {
    if (commandsPracticed == 0) return 0.0;
    return (perfectScores / commandsPracticed) * 100;
  }

  @override
  List<Object?> get props => [
    commandsPracticed,
    perfectScores,
    hintsUsed,
    longestStreak,
    lastPracticeDate,
    categoryScores,
    weeklyActivity,
    averageSessionTime,
    totalSessions,
  ];
}