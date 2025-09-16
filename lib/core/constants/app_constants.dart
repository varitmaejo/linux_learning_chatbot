class AppConstants {
  // App Info
  static const String appName = 'Linux Learning Chat';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'ระบบสนทนาอัตโนมัติอัจฉริยะเพื่อส่งเสริมการเรียนรู้คำสั่งลีนุกส์เฉพาะบุคคล';

  // API Configuration
  static const String dialogflowProjectId = 'linux-learning-chat';
  static const String dialogflowLanguageCode = 'th-TH';
  static const String dialogflowSessionId = 'default-session';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String chatCollection = 'chats';
  static const String commandsCollection = 'linux_commands';
  static const String progressCollection = 'user_progress';
  static const String achievementsCollection = 'achievements';

  // Local Storage Keys
  static const String userProfileBox = 'user_profile';
  static const String chatHistoryBox = 'chat_history';
  static const String learningProgressBox = 'learning_progress';
  static const String settingsBox = 'settings';
  static const String achievementsBox = 'achievements_box';

  // User Preferences Keys
  static const String isDarkModeKey = 'is_dark_mode';
  static const String languageKey = 'language';
  static const String textSizeKey = 'text_size';
  static const String voiceEnabledKey = 'voice_enabled';
  static const String soundEnabledKey = 'sound_enabled';

  // Learning Levels
  static const Map<String, String> difficultyLevels = {
    'beginner': 'เริ่มต้น',
    'intermediate': 'กลาง',
    'advanced': 'ขั้นสูง',
    'expert': 'ผู้เชี่ยวชาญ',
  };

  // Command Categories
  static const Map<String, String> commandCategories = {
    'file_management': 'การจัดการไฟล์',
    'system_admin': 'การจัดการระบบ',
    'network': 'เครือข่าย',
    'text_processing': 'การประมวลผลข้อความ',
    'package_management': 'การจัดการแพ็กเกจ',
    'security': 'ความปลอดภัย',
    'process_management': 'การจัดการโปรเซส',
    'archive': 'การจัดการไฟล์บีบอัด',
  };

  // XP Points Configuration
  static const int xpPerCorrectAnswer = 10;
  static const int xpPerCompletedLesson = 25;
  static const int xpPerDailyChallenge = 50;
  static const int xpPerAchievement = 100;

  // Level Requirements
  static const Map<int, int> levelRequirements = {
    1: 0,
    2: 100,
    3: 250,
    4: 500,
    5: 1000,
    6: 1750,
    7: 2750,
    8: 4000,
    9: 5500,
    10: 7250,
  };

  // UI Constants
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  static const double iconSize = 24.0;
  static const double buttonHeight = 48.0;

  // Animation Durations
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // Chat Configuration
  static const int maxChatHistory = 100;
  static const int typingIndicatorDelay = 1500;
  static const int maxMessageLength = 500;

  // Terminal Configuration
  static const String defaultTerminalPrompt = 'user@linux-learning:~\$ ';
  static const int maxTerminalHistory = 50;
  static const List<String> supportedCommands = [
    'ls', 'cd', 'pwd', 'mkdir', 'rmdir', 'rm', 'cp', 'mv',
    'cat', 'less', 'more', 'head', 'tail', 'grep', 'find',
    'chmod', 'chown', 'ps', 'top', 'kill', 'ping', 'wget',
    'curl', 'tar', 'gzip', 'unzip', 'history', 'clear',
    'man', 'help', 'echo', 'touch', 'nano', 'vim',
  ];

  // Audio Configuration
  static const String achievementSoundPath = 'assets/sounds/achievement.mp3';
  static const String correctAnswerSoundPath = 'assets/sounds/correct.mp3';
  static const String incorrectAnswerSoundPath = 'assets/sounds/incorrect.mp3';
  static const String notificationSoundPath = 'assets/sounds/notification.mp3';

  // Error Messages
  static const String networkErrorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อเครือข่าย';
  static const String unknownErrorMessage = 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
  static const String noDataMessage = 'ไม่พบข้อมูล';

  // Success Messages
  static const String profileUpdatedMessage = 'อัปเดตโปรไฟล์สำเร็จ';
  static const String achievementUnlockedMessage = 'ปลดล็อกความสำเร็จแล้ว!';
  static const String levelUpMessage = 'เลเวลอัป!';

  // Validation Patterns
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^[0-9]{10}$';

  // Quiz Configuration
  static const int questionsPerQuiz = 5;
  static const int timePerQuestion = 30; // seconds
  static const int passingScore = 70; // percentage

  // Daily Challenge Configuration
  static const int dailyChallengesPerLevel = 3;
  static const int streakBonusThreshold = 7;
  static const double streakBonusMultiplier = 1.5;

  // Notification Configuration
  static const String dailyReminderTitle = 'เวลาเรียนรู้ Linux แล้ว!';
  static const String dailyReminderBody = 'มาเรียนรู้คำสั่ง Linux ใหม่ๆ กันเถอะ';
  static const String streakReminderTitle = 'รักษาสถิติการเรียนต่อเนื่อง';
  static const String streakReminderBody = 'อย่าให้สถิติการเรียนต่อเนื่องขาดตอน!';
}