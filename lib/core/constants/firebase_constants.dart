class FirebaseConstants {
  // Collection Names
  static const String usersCollection = 'users';
  static const String chatMessagesCollection = 'chat_messages';
  static const String learningProgressCollection = 'learning_progress';
  static const String achievementsCollection = 'achievements';
  static const String linuxCommandsCollection = 'linux_commands';
  static const String analyticsCollection = 'analytics';
  static const String feedbackCollection = 'feedback';
  static const String leaderboardCollection = 'leaderboard';
  static const String notificationsCollection = 'notifications';

  // User Document Fields
  static const String userIdField = 'userId';
  static const String emailField = 'email';
  static const String displayNameField = 'displayName';
  static const String photoUrlField = 'photoUrl';
  static const String createdAtField = 'createdAt';
  static const String updatedAtField = 'updatedAt';
  static const String lastActiveField = 'lastActive';
  static const String isAnonymousField = 'isAnonymous';
  static const String fcmTokenField = 'fcmToken';
  static const String themePreferenceField = 'themePreference';
  static const String languageField = 'language';
  static const String levelField = 'level';
  static const String xpField = 'xp';
  static const String streakField = 'streak';
  static const String totalCommandsLearnedField = 'totalCommandsLearned';
  static const String totalQuizzesCompletedField = 'totalQuizzesCompleted';
  static const String totalTimeSpentField = 'totalTimeSpent';
  static const String preferencesField = 'preferences';

  // Chat Message Fields
  static const String messageIdField = 'messageId';
  static const String textField = 'text';
  static const String isUserField = 'isUser';
  static const String timestampField = 'timestamp';
  static const String messageTypeField = 'messageType';
  static const String metadataField = 'metadata';
  static const String imageUrlField = 'imageUrl';
  static const String fileUrlField = 'fileUrl';
  static const String isReadField = 'isRead';
  static const String isFavoriteField = 'isFavorite';
  static const String replyToMessageIdField = 'replyToMessageId';
  static const String confidenceField = 'confidence';
  static const String quickRepliesField = 'quickReplies';
  static const String voiceDurationField = 'voiceDuration';

  // Learning Progress Fields
  static const String progressIdField = 'progressId';
  static const String commandIdField = 'commandId';
  static const String categoryField = 'category';
  static const String difficultyField = 'difficulty';
  static const String statusField = 'status';
  static const String progressPercentageField = 'progressPercentage';
  static const String completedAtField = 'completedAt';
  static const String attemptsField = 'attempts';
  static const String bestScoreField = 'bestScore';
  static const String lastAttemptField = 'lastAttempt';
  static const String timeSpentField = 'timeSpent';
  static const String hintsUsedField = 'hintsUsed';

  // Achievement Fields
  static const String achievementIdField = 'achievementId';
  static const String titleField = 'title';
  static const String descriptionField = 'description';
  static const String iconField = 'icon';
  static const String typeField = 'type';
  static const String requirementField = 'requirement';
  static const String unlockedAtField = 'unlockedAt';
  static const String isUnlockedField = 'isUnlocked';
  static const String pointsField = 'points';
  static const String rarityField = 'rarity';

  // Linux Command Fields
  static const String commandNameField = 'commandName';
  static const String syntaxField = 'syntax';
  static const String descriptionField = 'description';
  static const String examplesField = 'examples';
  static const String parametersField = 'parameters';
  static const String relatedCommandsField = 'relatedCommands';
  static const String tagsField = 'tags';
  static const String difficultyLevelField = 'difficultyLevel';
  static const String usageCountField = 'usageCount';
  static const String averageRatingField = 'averageRating';

  // Analytics Fields
  static const String sessionIdField = 'sessionId';
  static const String eventNameField = 'eventName';
  static const String eventDataField = 'eventData';
  static const String deviceInfoField = 'deviceInfo';
  static const String appVersionField = 'appVersion';
  static const String platformField = 'platform';
  static const String userAgentField = 'userAgent';
  static const String screenResolutionField = 'screenResolution';

  // Notification Fields
  static const String notificationIdField = 'notificationId';
  static const String recipientIdField = 'recipientId';
  static const String senderIdField = 'senderId';
  static const String messageField = 'message';
  static const String readAtField = 'readAt';
  static const String actionUrlField = 'actionUrl';
  static const String priorityField = 'priority';

  // Storage Paths
  static const String userProfileImagesPath = 'user_profiles';
  static const String chatAttachmentsPath = 'chat_attachments';
  static const String achievementIconsPath = 'achievement_icons';
  static const String commandExamplesPath = 'command_examples';
  static const String exportedDataPath = 'exported_data';

  // Message Types
  static const String textMessageType = 'text';
  static const String voiceMessageType = 'voice';
  static const String linuxCommandMessageType = 'linuxCommand';
  static const String quizMessageType = 'quiz';
  static const String quizResultMessageType = 'quizResult';
  static const String learningPathMessageType = 'learningPath';
  static const String suggestionsMessageType = 'suggestions';
  static const String errorMessageType = 'error';
  static const String systemMessageType = 'system';
  static const String imageMessageType = 'image';
  static const String fileMessageType = 'file';

  // Progress Status
  static const String notStartedStatus = 'not_started';
  static const String inProgressStatus = 'in_progress';
  static const String completedStatus = 'completed';
  static const String reviewStatus = 'review';
  static const String masteredStatus = 'mastered';

  // Achievement Types
  static const String streakAchievementType = 'streak';
  static const String commandsLearnedAchievementType = 'commands_learned';
  static const String quizCompletedAchievementType = 'quiz_completed';
  static const String timeSpentAchievementType = 'time_spent';
  static const String perfectScoreAchievementType = 'perfect_score';
  static const String firstTimeAchievementType = 'first_time';
  static const String milestoneAchievementType = 'milestone';

  // Achievement Rarity
  static const String commonRarity = 'common';
  static const String rareRarity = 'rare';
  static const String epicRarity = 'epic';
  static const String legendaryRarity = 'legendary';

  // Difficulty Levels
  static const String beginnerDifficulty = 'beginner';
  static const String intermediateDifficulty = 'intermediate';
  static const String advancedDifficulty = 'advanced';
  static const String expertDifficulty = 'expert';

  // Command Categories
  static const String fileSystemCategory = 'file_system';
  static const String textProcessingCategory = 'text_processing';
  static const String systemInfoCategory = 'system_info';
  static const String networkCategory = 'network';
  static const String processCategory = 'process';
  static const String permissionCategory = 'permission';
  static const String archiveCategory = 'archive';
  static const String searchCategory = 'search';
  static const String ioRedirectionCategory = 'io_redirection';
  static const String environmentCategory = 'environment';

  // Theme Preferences
  static const String lightTheme = 'light';
  static const String darkTheme = 'dark';
  static const String systemTheme = 'system';

  // Languages
  static const String thaiLanguage = 'th';
  static const String englishLanguage = 'en';

  // Notification Priorities
  static const String lowPriority = 'low';
  static const String normalPriority = 'normal';
  static const String highPriority = 'high';
  static const String urgentPriority = 'urgent';

  // Firestore Settings
  static const int maxBatchSize = 500;
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration cacheTimeout = Duration(minutes: 30);

  // Validation Rules
  static const int maxDisplayNameLength = 50;
  static const int maxMessageLength = 1000;
  static const int maxDescriptionLength = 500;
  static const int minPasswordLength = 6;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // Default Values
  static const int defaultLevel = 1;
  static const int defaultXp = 0;
  static const int defaultStreak = 0;
  static const String defaultLanguage = thaiLanguage;
  static const String defaultTheme = lightTheme;
  static const double defaultConfidence = 0.0;
  static const int defaultProgressPercentage = 0;
  static const int defaultAttempts = 0;
  static const int defaultBestScore = 0;
  static const int defaultTimeSpent = 0;
  static const int defaultUsageCount = 0;
  static const double defaultAverageRating = 0.0;

  // Error Messages
  static const String userNotFoundError = 'User not found';
  static const String unauthorizedError = 'Unauthorized access';
  static const String networkError = 'Network error occurred';
  static const String firestoreError = 'Database error occurred';
  static const String storageError = 'Storage error occurred';
  static const String authError = 'Authentication error occurred';
  static const String validationError = 'Validation error occurred';
  static const String unknownError = 'An unknown error occurred';

  // Success Messages
  static const String userCreatedSuccess = 'User created successfully';
  static const String userUpdatedSuccess = 'User updated successfully';
  static const String messagesSavedSuccess = 'Messages saved successfully';
  static const String progressSavedSuccess = 'Progress saved successfully';
  static const String achievementUnlockedSuccess = 'Achievement unlocked!';
  static const String dataExportedSuccess = 'Data exported successfully';
  static const String settingsUpdatedSuccess = 'Settings updated successfully';
}