import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends Equatable {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String displayName;

  @HiveField(3)
  final String? photoURL;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime lastLoginAt;

  @HiveField(6)
  final DateTime? lastActivity;

  @HiveField(7)
  final int level;

  @HiveField(8)
  final int xp;

  @HiveField(9)
  final int streak;

  @HiveField(10)
  final int maxStreak;

  @HiveField(11)
  final int totalLessonsCompleted;

  @HiveField(12)
  final int totalQuizzesTaken;

  @HiveField(13)
  final int totalCommandsLearned;

  @HiveField(14)
  final String currentDifficulty;

  @HiveField(15)
  final String preferredLanguage;

  @HiveField(16)
  final List<String> completedCategories;

  @HiveField(17)
  final List<String> favoriteCommands;

  @HiveField(18)
  final Map<String, dynamic> settings;

  @HiveField(19)
  final Map<String, double> categoryProgress;

  @HiveField(20)
  final bool isAnonymous;

  @HiveField(21)
  final bool isPremium;

  @HiveField(22)
  final DateTime? premiumExpiresAt;

  @HiveField(23)
  final String? fcmToken;

  @HiveField(24)
  final List<String> subscribedTopics;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.lastLoginAt,
    this.lastActivity,
    this.level = 1,
    this.xp = 0,
    this.streak = 0,
    this.maxStreak = 0,
    this.totalLessonsCompleted = 0,
    this.totalQuizzesTaken = 0,
    this.totalCommandsLearned = 0,
    this.currentDifficulty = 'beginner',
    this.preferredLanguage = 'th',
    this.completedCategories = const [],
    this.favoriteCommands = const [],
    this.settings = const {},
    this.categoryProgress = const {},
    this.isAnonymous = false,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.fcmToken,
    this.subscribedTopics = const [],
  });

  // Factory constructor from Map (Firebase)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActivity: (map['lastActivity'] as Timestamp?)?.toDate(),
      level: map['level'] ?? 1,
      xp: map['xp'] ?? 0,
      streak: map['streak'] ?? 0,
      maxStreak: map['maxStreak'] ?? 0,
      totalLessonsCompleted: map['totalLessonsCompleted'] ?? 0,
      totalQuizzesTaken: map['totalQuizzesTaken'] ?? 0,
      totalCommandsLearned: map['totalCommandsLearned'] ?? 0,
      currentDifficulty: map['currentDifficulty'] ?? 'beginner',
      preferredLanguage: map['preferredLanguage'] ?? 'th',
      completedCategories: List<String>.from(map['completedCategories'] ?? []),
      favoriteCommands: List<String>.from(map['favoriteCommands'] ?? []),
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      categoryProgress: Map<String, double>.from(map['categoryProgress'] ?? {}),
      isAnonymous: map['isAnonymous'] ?? false,
      isPremium: map['isPremium'] ?? false,
      premiumExpiresAt: (map['premiumExpiresAt'] as Timestamp?)?.toDate(),
      fcmToken: map['fcmToken'],
      subscribedTopics: List<String>.from(map['subscribedTopics'] ?? []),
    );
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'lastActivity': lastActivity != null ? Timestamp.fromDate(lastActivity!) : null,
      'level': level,
      'xp': xp,
      'streak': streak,
      'maxStreak': maxStreak,
      'totalLessonsCompleted': totalLessonsCompleted,
      'totalQuizzesTaken': totalQuizzesTaken,
      'totalCommandsLearned': totalCommandsLearned,
      'currentDifficulty': currentDifficulty,
      'preferredLanguage': preferredLanguage,
      'completedCategories': completedCategories,
      'favoriteCommands': favoriteCommands,
      'settings': settings,
      'categoryProgress': categoryProgress,
      'isAnonymous': isAnonymous,
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt != null ? Timestamp.fromDate(premiumExpiresAt!) : null,
      'fcmToken': fcmToken,
      'subscribedTopics': subscribedTopics,
    };
  }

  // JSON serialization (for local storage)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoURL: json['photoURL'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
      lastActivity: json['lastActivity'] != null ? DateTime.parse(json['lastActivity']) : null,
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      streak: json['streak'] ?? 0,
      maxStreak: json['maxStreak'] ?? 0,
      totalLessonsCompleted: json['totalLessonsCompleted'] ?? 0,
      totalQuizzesTaken: json['totalQuizzesTaken'] ?? 0,
      totalCommandsLearned: json['totalCommandsLearned'] ?? 0,
      currentDifficulty: json['currentDifficulty'] ?? 'beginner',
      preferredLanguage: json['preferredLanguage'] ?? 'th',
      completedCategories: List<String>.from(json['completedCategories'] ?? []),
      favoriteCommands: List<String>.from(json['favoriteCommands'] ?? []),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      categoryProgress: Map<String, double>.from(json['categoryProgress'] ?? {}),
      isAnonymous: json['isAnonymous'] ?? false,
      isPremium: json['isPremium'] ?? false,
      premiumExpiresAt: json['premiumExpiresAt'] != null ? DateTime.parse(json['premiumExpiresAt']) : null,
      fcmToken: json['fcmToken'],
      subscribedTopics: List<String>.from(json['subscribedTopics'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'lastActivity': lastActivity?.toIso8601String(),
      'level': level,
      'xp': xp,
      'streak': streak,
      'maxStreak': maxStreak,
      'totalLessonsCompleted': totalLessonsCompleted,
      'totalQuizzesTaken': totalQuizzesTaken,
      'totalCommandsLearned': totalCommandsLearned,
      'currentDifficulty': currentDifficulty,
      'preferredLanguage': preferredLanguage,
      'completedCategories': completedCategories,
      'favoriteCommands': favoriteCommands,
      'settings': settings,
      'categoryProgress': categoryProgress,
      'isAnonymous': isAnonymous,
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt?.toIso8601String(),
      'fcmToken': fcmToken,
      'subscribedTopics': subscribedTopics,
    };
  }

  // Copy with method
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? lastActivity,
    int? level,
    int? xp,
    int? streak,
    int? maxStreak,
    int? totalLessonsCompleted,
    int? totalQuizzesTaken,
    int? totalCommandsLearned,
    String? currentDifficulty,
    String? preferredLanguage,
    List<String>? completedCategories,
    List<String>? favoriteCommands,
    Map<String, dynamic>? settings,
    Map<String, double>? categoryProgress,
    bool? isAnonymous,
    bool? isPremium,
    DateTime? premiumExpiresAt,
    String? fcmToken,
    List<String>? subscribedTopics,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastActivity: lastActivity ?? this.lastActivity,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      maxStreak: maxStreak ?? this.maxStreak,
      totalLessonsCompleted: totalLessonsCompleted ?? this.totalLessonsCompleted,
      totalQuizzesTaken: totalQuizzesTaken ?? this.totalQuizzesTaken,
      totalCommandsLearned: totalCommandsLearned ?? this.totalCommandsLearned,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      completedCategories: completedCategories ?? this.completedCategories,
      favoriteCommands: favoriteCommands ?? this.favoriteCommands,
      settings: settings ?? this.settings,
      categoryProgress: categoryProgress ?? this.categoryProgress,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      fcmToken: fcmToken ?? this.fcmToken,
      subscribedTopics: subscribedTopics ?? this.subscribedTopics,
    );
  }

  // Helper methods
  double get totalProgress {
    if (categoryProgress.isEmpty) return 0.0;
    final total = categoryProgress.values.reduce((a, b) => a + b);
    return total / categoryProgress.length;
  }

  int get xpToNextLevel {
    return ((level * 100) - xp).clamp(0, double.infinity).toInt();
  }

  double get currentLevelProgress {
    final currentLevelXP = (level - 1) * 100;
    final nextLevelXP = level * 100;
    final progress = (xp - currentLevelXP) / (nextLevelXP - currentLevelXP);
    return progress.clamp(0.0, 1.0);
  }

  bool get isStreakActive {
    if (lastActivity == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastActivity!).inDays;
    return difference <= 1;
  }

  String get difficultyDisplayName {
    switch (currentDifficulty) {
      case 'beginner':
        return 'ผู้เริ่มต้น';
      case 'intermediate':
        return 'ระดับกลาง';
      case 'advanced':
        return 'ระดับสูง';
      case 'expert':
        return 'ผู้เชี่ยวชาญ';
      default:
        return 'ไม่ระบุ';
    }
  }

  String get experienceTitle {
    if (level <= 5) return 'มือใหม่';
    if (level <= 10) return 'ผู้เรียนรู้';
    if (level <= 20) return 'ผู้ฝึกหัด';
    if (level <= 30) return 'ผู้เชี่ยวชาญ';
    return 'ผู้ท่องแท้';
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoURL,
    createdAt,
    lastLoginAt,
    lastActivity,
    level,
    xp,
    streak,
    maxStreak,
    totalLessonsCompleted,
    totalQuizzesTaken,
    totalCommandsLearned,
    currentDifficulty,
    preferredLanguage,
    completedCategories,
    favoriteCommands,
    settings,
    categoryProgress,
    isAnonymous,
    isPremium,
    premiumExpiresAt,
    fcmToken,
    subscribedTopics,
  ];
}