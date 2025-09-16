import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/services/firebase_service.dart';
import 'core/services/dialogflow_service.dart';
import 'core/services/voice_service.dart';
import 'core/services/terminal_service.dart';
import 'core/services/analytics_service.dart';

// Models
import 'data/models/user_model.dart';
import 'data/models/chat_message.dart';
import 'data/models/learning_progress.dart';
import 'data/models/achievement.dart';
import 'data/models/linux_command.dart';

// Providers
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/learning_provider.dart';
import 'presentation/providers/progress_provider.dart';
import 'presentation/providers/voice_provider.dart';

// Screens
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/learning_screen.dart';
import 'presentation/screens/practice_screen.dart';
import 'presentation/screens/terminal_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/progress_screen.dart';
import 'presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize Firebase
    await Firebase.initializeApp();
    print('Firebase initialized successfully');

    // Initialize Firebase services
    await FirebaseService.instance.initialize();

    // Initialize Dialogflow
    await DialogflowService.instance.initialize();

    // Initialize Analytics
    await AnalyticsService.instance.initialize();

    // Initialize Hive
    await Hive.initFlutter();

    // Register Hive Adapters (Note: These adapters need to be generated)
    // Run: flutter packages pub run build_runner build
    try {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(UserPreferencesAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(UserStatsAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ChatMessageAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(LinuxCommandAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(CommandExampleAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(CommandParameterAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(LearningProgressAdapter());
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(LearningSessionAdapter());
      }
      if (!Hive.isAdapterRegistered(9)) {
        Hive.registerAdapter(SessionErrorAdapter());
      }
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(AchievementAdapter());
      }
    } catch (e) {
      print('Error registering Hive adapters: $e');
      print('Please run: flutter packages pub run build_runner build');
    }

    // Open Hive Boxes
    await Hive.openBox<UserModel>('users');
    await Hive.openBox<ChatMessage>('chat_messages');
    await Hive.openBox<LearningProgress>('learning_progress');
    await Hive.openBox<Achievement>('achievements');
    await Hive.openBox<LinuxCommand>('linux_commands');
    await Hive.openBox('settings');

    // Log app open
    await AnalyticsService.instance.logAppOpen();

    print('App initialization completed successfully');

  } catch (e) {
    print('Error during app initialization: $e');
  }

  runApp(const LinuxLearningChatApp());
}

class LinuxLearningChatApp extends StatelessWidget {
  const LinuxLearningChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VoiceService.instance),

        // Data providers (depend on auth)
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, auth, chat) => chat!..updateUser(auth.currentUser),
        ),
        ChangeNotifierProxyProvider<AuthProvider, LearningProvider>(
          create: (_) => LearningProvider(),
          update: (_, auth, learning) => learning!..updateUser(auth.currentUser),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProgressProvider>(
          create: (_) => ProgressProvider(),
          update: (_, auth, progress) => progress!..updateUser(auth.currentUser),
        ),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Linux Learning Chat',
            debugShowCheckedModeBanner: false,

            // Theme
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _getThemeMode(authProvider.currentUser?.preferences.theme),

            // Localization
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('th', 'TH'),
              Locale('en', 'US'),
            ],
            locale: _getLocale(authProvider.currentUser?.preferences.language),

            // Navigation
            navigatorObservers: AnalyticsService.instance.observer != null
                ? [AnalyticsService.instance.observer!]
                : [],

            // Routes
            initialRoute: '/',
            onGenerateRoute: _generateRoute,

            // Home
            home: const SplashScreen(),
          );
        },
      ),
    );
  }

  ThemeMode _getThemeMode(String? theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Locale _getLocale(String? language) {
    switch (language) {
      case 'en':
        return const Locale('en', 'US');
      case 'th':
      default:
        return const Locale('th', 'TH');
    }
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case '/onboarding':
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );

      case '/home':
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      case '/chat':
        return MaterialPageRoute(
          builder: (_) => const ChatScreen(),
          settings: settings,
        );

      case '/learning':
        return MaterialPageRoute(
          builder: (_) => const LearningScreen(),
          settings: settings,
        );

      case '/practice':
        return MaterialPageRoute(
          builder: (_) => const PracticeScreen(),
          settings: settings,
        );

      case '/terminal':
        return MaterialPageRoute(
          builder: (_) => const TerminalScreen(),
          settings: settings,
        );

      case '/profile':
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );

      case '/progress':
        return MaterialPageRoute(
          builder: (_) => const ProgressScreen(),
          settings: settings,
        );

      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );

      case '/achievements':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AchievementsScreen(
            userId: args?['userId'] ?? '',
          ),
          settings: settings,
        );

      case '/leaderboard':
        return MaterialPageRoute(
          builder: (_) => const LeaderboardScreen(),
          settings: settings,
        );

      case '/lesson-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => LessonDetailScreen(
            lessonId: args?['lessonId'] ?? '',
            lesson: args?['lesson'],
          ),
          settings: settings,
        );

      case '/quiz':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => QuizScreen(
            quizId: args?['quizId'] ?? '',
            difficulty: args?['difficulty'] ?? 'beginner',
            category: args?['category'] ?? 'general',
          ),
          settings: settings,
        );

      case '/command-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CommandDetailScreen(
            command: args?['command'],
            commandName: args?['commandName'] ?? '',
          ),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundScreen(),
          settings: settings,
        );
    }
  }
}

// Placeholder screens that need to be created
class AchievementsScreen extends StatelessWidget {
  final String userId;

  const AchievementsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ความสำเร็จ')),
      body: const Center(
        child: Text('หน้าแสดงความสำเร็จ'),
      ),
    );
  }
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('กระดานผู้นำ')),
      body: const Center(
        child: Text('หน้ากระดานผู้นำ'),
      ),
    );
  }
}

class LessonDetailScreen extends StatelessWidget {
  final String lessonId;
  final dynamic lesson;

  const LessonDetailScreen({
    Key? key,
    required this.lessonId,
    this.lesson,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('บทเรียน $lessonId')),
      body: const Center(
        child: Text('รายละเอียดบทเรียน'),
      ),
    );
  }
}

class QuizScreen extends StatelessWidget {
  final String quizId;
  final String difficulty;
  final String category;

  const QuizScreen({
    Key? key,
    required this.quizId,
    required this.difficulty,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('แบบทดสอบ $category')),
      body: const Center(
        child: Text('หน้าแบบทดสอบ'),
      ),
    );
  }
}

class CommandDetailScreen extends StatelessWidget {
  final dynamic command;
  final String commandName;

  const CommandDetailScreen({
    Key? key,
    this.command,
    required this.commandName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('คำสั่ง $commandName')),
      body: const Center(
        child: Text('รายละเอียดคำสั่ง'),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ไม่พบหน้า')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64),
            SizedBox(height: 16),
            Text(
              'ไม่พบหน้าที่คุณต้องการ',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'กรุณาตรวจสอบ URL หรือกลับไปหน้าหลัก',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
              (route) => false,
        ),
        child: const Icon(Icons.home),
      ),
    );
  }
}