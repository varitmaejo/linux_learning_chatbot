class FirebaseConstants {
  FirebaseConstants._();

  // Collection Names
  static const String usersCollection = 'users';
  static const String progressCollection = 'learning_progress';
  static const String chatHistoryCollection = 'chat_history';
  static const String achievementsCollection = 'achievements';
  static const String leaderboardCollection = 'leaderboard';
  static const String lessonsCollection = 'lessons';
  static const String commandsCollection = 'linux_commands';
  static const String quizzesCollection = 'quizzes';
  static const String feedbackCollection = 'feedback';
  static const String notificationsCollection = 'notifications';

  // Storage Paths
  static const String userProfilesPath = 'user_profiles';
  static const String achievementIconsPath = 'achievement_icons';
  static const String commandIconsPath = 'command_icons';
  static const String lessonsPath = 'lessons';

  // Analytics Events
  static const String eventLessonStarted = 'lesson_started';
  static const String eventLessonCompleted = 'lesson_completed';
  static const String eventQuizTaken = 'quiz_taken';
  static const String eventCommandExecuted = 'command_executed';
  static const String eventAchievementUnlocked = 'achievement_unlocked';
  static const String eventChatMessageSent = 'chat_message_sent';
  static const String eventVoiceUsed = 'voice_used';
  static const String eventTerminalUsed = 'terminal_used';
  static const String eventLearningPathChanged = 'learning_path_changed';

  // User Properties
  static const String userPropertyLevel = 'user_level';
  static const String userPropertyDifficulty = 'current_difficulty';
  static const String userPropertyLanguage = 'preferred_language';
  static const String userPropertyStreak = 'learning_streak';

  // FCM Topics
  static const String topicAllUsers = 'all_users';
  static const String topicBeginners = 'beginners';
  static const String topicIntermediate = 'intermediate';
  static const String topicAdvanced = 'advanced';
  static const String topicExperts = 'experts';
  static const String topicDailyReminders = 'daily_reminders';
  static const String topicWeeklyChallenge = 'weekly_challenge';

  // Dialogflow Configuration
  static const String dialogflowProjectId = 'linux-learning-chatbot';
  static const String dialogflowLanguageCode = 'th';
  static const String dialogflowSessionPrefix = 'linux_chatbot_session_';

  // Default Values
  static const int defaultXPForBeginner = 10;
  static const int defaultXPForIntermediate = 20;
  static const int defaultXPForAdvanced = 30;
  static const int defaultXPForExpert = 50;
  static const int xpPerLevel = 100;
  static const int maxStreakDays = 365;
  static const int dailyChallengeXP = 25;
  static const int weeklyChallengXP = 100;

  // Achievement IDs
  static const String achievementFirstLesson = 'first_lesson';
  static const String achievementLevel5 = 'level_5';
  static const String achievementLevel10 = 'level_10';
  static const String achievementLevel20 = 'level_20';
  static const String achievementLessons10 = 'lessons_10';
  static const String achievementLessons50 = 'lessons_50';
  static const String achievementLessons100 = 'lessons_100';
  static const String achievementPerfectAccuracy = 'perfect_accuracy';
  static const String achievementStreak7 = 'streak_7';
  static const String achievementStreak30 = 'streak_30';
  static const String achievementTerminalMaster = 'terminal_master';
  static const String achievementCommandExplorer = 'command_explorer';
  static const String achievementQuizMaster = 'quiz_master';

  // Difficulty Levels
  static const String difficultyBeginner = 'beginner';
  static const String difficultyIntermediate = 'intermediate';
  static const String difficultyAdvanced = 'advanced';
  static const String difficultyExpert = 'expert';

  // Learning Categories
  static const String categoryFileManagement = 'file_management';
  static const String categorySystemAdmin = 'system_administration';
  static const String categoryNetworking = 'networking';
  static const String categoryTextProcessing = 'text_processing';
  static const String categoryPackageManagement = 'package_management';
  static const String categorySecurity = 'security';
  static const String categoryShellScripting = 'shell_scripting';

  // Command Types
  static const String commandTypeBasic = 'basic';
  static const String commandTypeAdvanced = 'advanced';
  static const String commandTypeSystem = 'system';
  static const String commandTypeNetwork = 'network';
  static const String commandTypeFile = 'file';
  static const String commandTypeText = 'text';

  // Message Types
  static const String messageTypeUser = 'user';
  static const String messageTypeBot = 'bot';
  static const String messageTypeSystem = 'system';
  static const String messageTypeCommand = 'command';

  // Notification Types
  static const String notificationDailyReminder = 'daily_reminder';
  static const String notificationStreak = 'streak_reminder';
  static const String notificationAchievement = 'achievement_unlocked';
  static const String notificationWeeklyChallenge = 'weekly_challenge';
  static const String notificationNewFeature = 'new_feature';

  // Error Codes
  static const String errorDialogflowConnection = 'DIALOGFLOW_CONNECTION_ERROR';
  static const String errorFirebaseConnection = 'FIREBASE_CONNECTION_ERROR';
  static const String errorAuthFailed = 'AUTH_FAILED';
  static const String errorDataNotFound = 'DATA_NOT_FOUND';
  static const String errorPermissionDenied = 'PERMISSION_DENIED';
  static const String errorNetworkUnavailable = 'NETWORK_UNAVAILABLE';

  // Cache Keys
  static const String cacheUserProfile = 'user_profile';
  static const String cacheLearningProgress = 'learning_progress';
  static const String cacheAchievements = 'achievements';
  static const String cacheLinuxCommands = 'linux_commands';
  static const String cacheLessons = 'lessons';

  // Settings Keys
  static const String settingsDarkMode = 'dark_mode';
  static const String settingsLanguage = 'language';
  static const String settingsTextScale = 'text_scale';
  static const String settingsVoiceEnabled = 'voice_enabled';
  static const String settingsNotificationsEnabled = 'notifications_enabled';
  static const String settingsAnalyticsEnabled = 'analytics_enabled';
  static const String settingsOfflineMode = 'offline_mode';
}