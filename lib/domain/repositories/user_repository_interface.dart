import '../entities/user.dart';

abstract class UserRepositoryInterface {
  /// Get current user
  Future<User?> getCurrentUser();

  /// Get user by ID
  Future<User?> getUserById(String userId);

  /// Get user by email
  Future<User?> getUserByEmail(String email);

  /// Get user by username
  Future<User?> getUserByUsername(String username);

  /// Create new user
  Future<User> createUser({
    required String email,
    required String username,
    required String displayName,
    String? phoneNumber,
    String? avatarUrl,
    UserPreferences? preferences,
  });

  /// Update user profile
  Future<User> updateUser({
    required String userId,
    String? email,
    String? username,
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
    UserLevel? level,
    int? experience,
    AccountStatus? accountStatus,
    UserPreferences? preferences,
    Map<String, dynamic>? metadata,
  });

  /// Delete user account
  Future<void> deleteUser(String userId);

  /// Update user experience
  Future<User> updateUserExperience({
    required String userId,
    required int experienceGained,
  });

  /// Update user level
  Future<User> updateUserLevel({
    required String userId,
    required UserLevel newLevel,
  });

  /// Add achievement to user
  Future<User> addAchievement({
    required String userId,
    required String achievementId,
  });

  /// Remove achievement from user
  Future<User> removeAchievement({
    required String userId,
    required String achievementId,
  });

  /// Add badge to user
  Future<User> addBadge({
    required String userId,
    required String badgeId,
  });

  /// Remove badge from user
  Future<User> removeBadge({
    required String userId,
    required String badgeId,
  });

  /// Update user preferences
  Future<UserPreferences> updateUserPreferences({
    required String userId,
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
  });

  /// Update user statistics
  Future<UserStats> updateUserStats({
    required String userId,
    int? totalSessions,
    Duration? additionalTimeSpent,
    int? commandsExecuted,
    int? lessonsCompleted,
    int? quizzesCompleted,
    double? newScore,
    int? streakDays,
    DateTime? lastActivityDate,
    Map<String, int>? categoryProgress,
    Map<String, double>? skillLevels,
  });

  /// Record user login
  Future<User> recordUserLogin(String userId);

  /// Verify user email
  Future<User> verifyUserEmail({
    required String userId,
    required String verificationToken,
  });

  /// Verify user phone
  Future<User> verifyUserPhone({
    required String userId,
    required String verificationCode,
  });

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username);

  /// Check if email is available
  Future<bool> isEmailAvailable(String email);

  /// Search users
  Future<List<User>> searchUsers({
    String? query,
    UserLevel? level,
    AccountStatus? status,
    int limit = 20,
    String? cursor,
  });

  /// Get user leaderboard
  Future<List<UserLeaderboardEntry>> getUserLeaderboard({
    String? category,
    String? timeframe, // 'day', 'week', 'month', 'all'
    int limit = 100,
  });

  /// Get user followers
  Future<List<User>> getUserFollowers({
    required String userId,
    int limit = 50,
    String? cursor,
  });

  /// Get user following
  Future<List<User>> getUserFollowing({
    required String userId,
    int limit = 50,
    String? cursor,
  });

  /// Follow user
  Future<void> followUser({
    required String userId,
    required String targetUserId,
  });

  /// Unfollow user
  Future<void> unfollowUser({
    required String userId,
    required String targetUserId,
  });

  /// Check if user is following another user
  Future<bool> isFollowing({
    required String userId,
    required String targetUserId,
  });

  /// Get user activity feed
  Future<List<UserActivity>> getUserActivityFeed({
    required String userId,
    int limit = 20,
    String? cursor,
  });

  /// Record user activity
  Future<void> recordUserActivity({
    required String userId,
    required UserActivityType type,
    required Map<String, dynamic> data,
  });

  /// Get user notifications
  Future<List<UserNotification>> getUserNotifications({
    required String userId,
    bool? unreadOnly,
    int limit = 50,
  });

  /// Mark notifications as read
  Future<void> markNotificationsAsRead({
    required String userId,
    required List<String> notificationIds,
  });

  /// Send notification to user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    Map<String, dynamic>? data,
  });

  /// Upload user avatar
  Future<String> uploadAvatar({
    required String userId,
    required List<int> imageData,
    required String fileName,
  });

  /// Delete user avatar
  Future<User> deleteAvatar(String userId);

  /// Export user data
  Future<String> exportUserData({
    required String userId,
    String format = 'json', // json, csv
  });

  /// Sync user data
  Future<void> syncUserData({
    required String userId,
    DateTime? lastSyncDate,
  });

  /// Cache user data locally
  Future<void> cacheUserLocally(User user);

  /// Get cached user data
  Future<User?> getCachedUser(String userId);

  /// Clear user cache
  Future<void> clearUserCache(String userId);

  /// Backup user data
  Future<String> backupUserData({
    required String userId,
    String format = 'json',
  });

  /// Restore user data
  Future<User> restoreUserData({
    required String userId,
    required String backupData,
    String format = 'json',
  });
}

class UserLeaderboardEntry {
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final UserLevel level;
  final int experience;
  final int rank;
  final int score;
  final Map<String, dynamic> stats;

  const UserLeaderboardEntry({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.level,
    required this.experience,
    required this.rank,
    required this.score,
    required this.stats,
  });

  @override
  String toString() {
    return 'UserLeaderboardEntry(rank: $rank, username: $username, level: $level, score: $score)';
  }
}

enum UserActivityType {
  levelUp,
  achievementUnlocked,
  badgeEarned,
  commandCompleted,
  lessonCompleted,
  quizCompleted,
  streakMilestone,
  profileUpdated,
  followed,
  unfollowed,
}

class UserActivity {
  final String id;
  final String userId;
  final UserActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool isPublic;

  const UserActivity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.data,
    required this.isPublic,
  });

  @override
  String toString() {
    return 'UserActivity(id: $id, type: $type, title: $title, timestamp: $timestamp)';
  }
}

enum NotificationType {
  info,
  warning,
  success,
  error,
  achievement,
  reminder,
  social,
}

class UserNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic> data;
  final String? actionUrl;

  const UserNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.readAt,
    required this.data,
    this.actionUrl,
  });

  UserNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? data,
    String? actionUrl,
  }) {
    return UserNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  @override
  String toString() {
    return 'UserNotification(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
}