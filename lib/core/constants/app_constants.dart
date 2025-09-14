class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'Linux Learning Chatbot';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // API URLs
  static const String baseUrl = 'https://api.linuxlearning.com';
  static const String dialogflowApiUrl = 'https://dialogflow.googleapis.com/v2';

  // Asset Paths
  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';
  static const String dataPath = 'assets/data/';
  static const String fontsPath = 'assets/fonts/';
  static const String credentialsPath = 'assets/credentials/';

  // Image Assets
  static const String logoImage = '${imagesPath}logo.png';
  static const String onboardingImage1 = '${imagesPath}onboarding/welcome.png';
  static const String onboardingImage2 = '${imagesPath}onboarding/learning.png';
  static const String onboardingImage3 = '${imagesPath}onboarding/practice.png';
  static const String terminalBg = '${imagesPath}terminal_bg.png';
  static const String chatBg = '${imagesPath}chat_bg.png';

  // Icon Assets
  static const String terminalIcon = '${iconsPath}terminal.png';
  static const String chatIcon = '${iconsPath}chat.png';
  static const String learningIcon = '${iconsPath}learning.png';
  static const String progressIcon = '${iconsPath}progress.png';
  static const String achievementIcon = '${iconsPath}achievement.png';

  // Data Files
  static const String linuxCommandsData = '${dataPath}linux_commands.json';
  static const String learningPathsData = '${dataPath}learning_paths.json';
  static const String achievementsData = '${dataPath}achievements.json';
  static const String quizQuestionsData = '${dataPath}quiz_questions.json';

  // Fonts
  static const String promptFont = 'Prompt';

  // Credentials
  static const String dialogflowCredentials = '${credentialsPath}dialogflow_credentials.json';

  // Local Storage Keys
  static const String userDataKey = 'user_data';
  static const String settingsKey = 'app_settings';
  static const String progressKey = 'learning_progress';
  static const String achievementsKey = 'achievements';
  static const String chatHistoryKey = 'chat_history';
  static const String commandHistoryKey = 'command_history';
  static const String lastSessionKey = 'last_session';
  static const String onboardingCompletedKey = 'onboarding_completed';

  // Animation Durations
  static const int splashDuration = 3000; // milliseconds
  static const int shortAnimationDuration = 300;
  static const int mediumAnimationDuration = 500;
  static const int longAnimationDuration = 1000;
  static const int pageTransitionDuration = 250;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultRadius = 12.0;
  static const double smallRadius = 8.0;
  static const double largeRadius = 16.0;
  static const double defaultElevation = 4.0;
  static const double maxWidth = 600.0;

  // Text Sizes
  static const double titleLargeSize = 28.0;
  static const double titleMediumSize = 24.0;
  static const double titleSmallSize = 20.0;
  static const double bodyLargeSize = 16.0;
  static const double bodyMediumSize = 14.0;
  static const double bodySmallSize = 12.0;
  static const double captionSize = 10.0;

  // Feature Flags
  static const bool enableVoiceFeatures = true;
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
  static const bool enablePushNotifications = true;
  static const bool enableDarkMode = true;
  static const bool enableDeveloperMode = false;

  // Learning Constants
  static const int defaultLessonTimeLimit = 1800; // 30 minutes
  static const int defaultQuizTimeLimit = 300; // 5 minutes
  static const int maxCommandHistoryLength = 1000;
  static const int maxChatHistoryLength = 500;
  static const int dailyChallengeCount = 5;
  static const int weeklyGoalLessons = 10;

  // Voice Settings
  static const double defaultSpeechRate = 0.5;
  static const double defaultVolume = 1.0;
  static const double defaultPitch = 1.0;
  static const String defaultLanguage = 'th-TH';
  static const int maxSpeechDuration = 30; // seconds
  static const int voiceTimeoutDuration = 5; // seconds

  // Terminal Settings
  static const int maxTerminalHistory = 1000;
  static const String defaultPrompt = 'user@linux-learning:\$ ';
  static const String terminalFont = 'monospace';
  static const double terminalFontSize = 14.0;
  static const int terminalCursorBlinkRate = 500; // milliseconds

  // Network Settings
  static const int connectionTimeout = 30; // seconds
  static const int requestTimeout = 15; // seconds
  static const int maxRetryAttempts = 3;
  static const int retryDelay = 1000; // milliseconds

  // Cache Settings
  static const int imageCacheMaxAge = 7; // days
  static const int dataCacheMaxAge = 1; // days
  static const int maxCacheSize = 100; // MB

  // Performance Settings
  static const int maxConcurrentRequests = 3;
  static const int imageLoadTimeout = 10; // seconds
  static const int databaseTimeout = 5; // seconds

  // Security Settings
  static const int sessionTimeout = 3600; // seconds (1 hour)
  static const int maxLoginAttempts = 5;
  static const int lockoutDuration = 300; // seconds (5 minutes)

  // Notification Settings
  static const String notificationChannelId = 'linux_learning_notifications';
  static const String notificationChannelName = 'Linux Learning';
  static const String notificationChannelDescription = 'Notifications for Linux Learning App';

  // Deep Link Settings
  static const String deepLinkScheme = 'linuxlearning';
  static const String deepLinkHost = 'app';

  // Social Sharing
  static const String shareText = 'ฉันกำลังเรียนรู้ Linux ด้วย Linux Learning Chatbot!';
  static const String appStoreUrl = 'https://apps.apple.com/app/linux-learning-chatbot';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.linuxlearning.chatbot';
  static const String websiteUrl = 'https://linuxlearning.com';

  // Support
  static const String supportEmail = 'support@linuxlearning.com';
  static const String feedbackEmail = 'feedback@linuxlearning.com';
  static const String privacyPolicyUrl = 'https://linuxlearning.com/privacy';
  static const String termsOfServiceUrl = 'https://linuxlearning.com/terms';

  // Error Messages
  static const String networkErrorMessage = 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อของคุณ';
  static const String serverErrorMessage = 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ กรุณาลองใหม่ภายหลัง';
  static const String timeoutErrorMessage = 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
  static const String unknownErrorMessage = 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
  static const String authErrorMessage = 'การยืนยันตัวตนล้มเหลว กรุณาเข้าสู่ระบบใหม่';
  static const String permissionErrorMessage = 'แอปต้องการสิทธิ์เพื่อการทำงานที่สมบูรณ์';

  // Success Messages
  static const String loginSuccessMessage = 'เข้าสู่ระบบสำเร็จ';
  static const String logoutSuccessMessage = 'ออกจากระบบสำเร็จ';
  static const String lessonCompletedMessage = 'ยินดีด้วย! คุณเรียนจบบทเรียนนี้แล้ว';
  static const String achievementUnlockedMessage = 'ยินดีด้วย! คุณได้รับความสำเร็จใหม่';
  static const String levelUpMessage = 'ยินดีด้วย! คุณเลื่อนระดับแล้ว';
  static const String dataBackupSuccessMessage = 'สำรองข้อมูลสำเร็จ';
  static const String dataRestoreSuccessMessage = 'กู้คืนข้อมูลสำเร็จ';

  // Validation Rules
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int maxEmailLength = 255;
  static const int maxMessageLength = 1000;
  static const int maxFeedbackLength = 2000;

  // Regex Patterns
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String usernamePattern = r'^[a-zA-Z0-9_]+$';
  static const String phonePattern = r'^[0-9]{10}$';

  // Default Values
  static const String defaultUsername = 'ผู้ใช้งาน';
  static const String defaultEmail = '';
  static const String defaultLanguageCode = 'th';
  static const String defaultCountryCode = 'TH';
  static const String defaultCurrency = 'THB';
  static const String defaultTimezone = 'Asia/Bangkok';

  // Limits
  static const int maxFileUploadSize = 10 * 1024 * 1024; // 10 MB
  static const int maxImageUploadSize = 5 * 1024 * 1024; // 5 MB
  static const int maxAudioRecordingDuration = 60; // seconds
  static const int maxVideoRecordingDuration = 300; // seconds
  static const int maxSearchResults = 50;
  static const int maxRecentItems = 20;

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String iso8601Format = "yyyy-MM-dd'T'HH:mm:ss'Z'";

  // Test Data (Development Only)
  static const bool useTestData = false;
  static const String testUserEmail = 'test@linuxlearning.com';
  static const String testUserPassword = 'testuser123';

  // Environment
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'production');
  static const bool isProduction = environment == 'production';
  static const bool isDevelopment = environment == 'development';
  static const bool isStaging = environment == 'staging';

  // Feature Gates
  static const bool enableBetaFeatures = bool.fromEnvironment('ENABLE_BETA_FEATURES', defaultValue: false);
  static const bool enableLogging = bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true);
  static const bool enableCrashReporting = bool.fromEnvironment('ENABLE_CRASH_REPORTING', defaultValue: true);
}