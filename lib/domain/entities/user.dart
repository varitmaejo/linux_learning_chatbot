enum UserLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

enum AccountStatus {
  active,
  inactive,
  suspended,
  pending,
}

class User {
  final String id;
  final String email;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final UserLevel level;
  final int experience;
  final int totalCommands;
  final AccountStatus accountStatus;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final DateTime updatedAt;
  final UserPreferences preferences;
  final UserStats stats;
  final List<String> achievements;
  final List<String> badges;
  final Map<String, dynamic> metadata;
  final bool isEmailVerified;
  final String? phoneNumber;
  final bool isPhoneVerified;

  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.level,
    required this.experience,
    required this.totalCommands,
    required this.accountStatus,
    required this.createdAt,
    required this.lastLoginAt,
    required this.updatedAt,
    required this.preferences,
    required this.stats,
    required this.achievements,
    required this.badges,
    required this.metadata,
    required this.isEmailVerified,
    this.phoneNumber,
    required this.isPhoneVerified,
  });

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? avatarUrl,
    UserLevel? level,
    int? experience,
    int? totalCommands,
    AccountStatus? accountStatus,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? updatedAt,
    UserPreferences? preferences,
    UserStats? stats,
    List<String>? achievements,
    List<String>? badges,
    Map<String, dynamic>? metadata,
    bool? isEmailVerified,
    String? phoneNumber,
    bool? isPhoneVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      totalCommands: totalCommands ?? this.totalCommands,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      achievements: achievements ?? this.achievements,
      badges: badges ?? this.badges,
      metadata: metadata ?? this.metadata,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }

  bool get isActive => accountStatus == AccountStatus.active;
  bool get isVerified => isEmailVerified;
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  int get experienceToNextLevel {
    switch (level) {
      case UserLevel.beginner:
        return 1000 - experience;
      case UserLevel.intermediate:
        return 2500 - experience;
      case UserLevel.advanced:
        return 5000 - experience;
      case UserLevel.expert:
        return 0; // Max level
    }
  }

  double get levelProgress {
    switch (level) {
      case UserLevel.beginner:
        return experience / 1000.0;
      case UserLevel.intermediate:
        return (experience - 1000) / 1500.0;
      case UserLevel.advanced:
        return (experience - 2500) / 2500.0;
      case UserLevel.expert:
        return 1.0;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.email == email &&
        other.username == username;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode ^ username.hashCode;
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, level: $level, experience: $experience)';
  }
}

class UserPreferences {
  final String language;
  final String theme;
  final bool soundEnabled;
  final bool notificationsEnabled;
  final bool autoSave;
  final String voiceLanguage;
  final double voiceSpeed;
  final bool showHints;
  final String defaultShell;
  final Map<String, dynamic> customSettings;

  const UserPreferences({
    required this.language,
    required this.theme,
    required this.soundEnabled,
    required this.notificationsEnabled,
    required this.autoSave,
    required this.voiceLanguage,
    required this.voiceSpeed,
    required this.showHints,
    required this.defaultShell,
    required this.customSettings,
  });

  UserPreferences copyWith({
    String? language,
    String? theme,
    bool? soundEnabled,
    bool? notificationsEnabled,
    bool? autoSave,
    String? voiceLanguage,
    double? voiceSpeed,
    bool? showHints,
    String? defaultShell,
    Map<String, dynamic>? customSettings,
  }) {
    return UserPreferences(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoSave: autoSave ?? this.autoSave,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      showHints: showHints ?? this.showHints,
      defaultShell: defaultShell ?? this.defaultShell,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

class UserStats {
  final int totalSessions;
  final Duration totalTimeSpent;
  final int commandsExecuted;
  final int lessonsCompleted;
  final int quizzesCompleted;
  final double averageScore;
  final int streakDays;
  final int maxStreak;
  final DateTime? lastActivityDate;
  final Map<String, int> categoryProgress;
  final Map<String, double> skillLevels;

  const UserStats({
    required this.totalSessions,
    required this.totalTimeSpent,
    required this.commandsExecuted,
    required this.lessonsCompleted,
    required this.quizzesCompleted,
    required this.averageScore,
    required this.streakDays,
    required this.maxStreak,
    this.lastActivityDate,
    required this.categoryProgress,
    required this.skillLevels,
  });

  UserStats copyWith({
    int? totalSessions,
    Duration? totalTimeSpent,
    int? commandsExecuted,
    int? lessonsCompleted,
    int? quizzesCompleted,
    double? averageScore,
    int? streakDays,
    int? maxStreak,
    DateTime? lastActivityDate,
    Map<String, int>? categoryProgress,
    Map<String, double>? skillLevels,
  }) {
    return UserStats(
      totalSessions: totalSessions ?? this.totalSessions,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      commandsExecuted: commandsExecuted ?? this.commandsExecuted,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      quizzesCompleted: quizzesCompleted ?? this.quizzesCompleted,
      averageScore: averageScore ?? this.averageScore,
      streakDays: streakDays ?? this.streakDays,
      maxStreak: maxStreak ?? this.maxStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      categoryProgress: categoryProgress ?? this.categoryProgress,
      skillLevels: skillLevels ?? this.skillLevels,
    );
  }

  bool get hasActiveStreak => streakDays > 0;
  double get averageSessionTime => totalSessions > 0
      ? totalTimeSpent.inMinutes / totalSessions
      : 0.0;
}