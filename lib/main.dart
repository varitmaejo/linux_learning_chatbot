import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/services/firebase_service.dart';
import 'core/services/dialogflow_service.dart';
import 'core/services/voice_service.dart';
import 'core/services/terminal_service.dart';
import 'core/services/analytics_service.dart';
import 'data/models/user_model.dart';
import 'data/models/chat_message.dart';
import 'data/models/learning_progress.dart';
import 'data/models/achievement.dart';
import 'data/models/linux_command.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/learning_provider.dart';
import 'presentation/providers/progress_provider.dart';
import 'presentation/providers/voice_provider.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('Firebase initialized successfully');

    // Initialize Firebase services
    await FirebaseService.instance.initialize();

    // Initialize Dialogflow
    await DialogflowService.instance.initialize();

    // Initialize Hive
    await Hive.initFlutter();

    // Register Hive Adapters
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    Hive.registerAdapter(LearningProgressAdapter());
    Hive.registerAdapter(AchievementAdapter());
    Hive.registerAdapter(LinuxCommandAdapter());

    // Open Hive Boxes
    await Hive.openBox<UserModel>('users');
    await Hive.openBox<ChatMessage>('chat_messages');
    await Hive.openBox<LearningProgress>('learning_progress');
    await Hive.openBox<Achievement>('achievements');
    await Hive.openBox<LinuxCommand>('linux_commands');
    await Hive.openBox('settings');
    await Hive.openBox('cache');

    // Initialize SharedPreferences
    await SharedPreferences.getInstance();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    print('App initialization completed successfully');

  } catch (e) {
    print('Error during app initialization: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core Providers
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),

        // Chat Provider
        ChangeNotifierProvider(
          create: (context) => ChatProvider(),
        ),

        // Learning Provider
        ChangeNotifierProvider(
          create: (_) => LearningProvider()..initialize(),
        ),

        // Progress Provider
        ChangeNotifierProvider(
          create: (_) => ProgressProvider()..initialize(),
        ),

        // Voice Provider
        ChangeNotifierProvider(
          create: (_) => VoiceProvider(VoiceService()),
        ),

        // Service Providers
        Provider<FirebaseService>(
          create: (_) => FirebaseService.instance,
        ),

        Provider<DialogflowService>(
          create: (_) => DialogflowService.instance,
        ),

        Provider<TerminalService>(
          create: (_) => TerminalService(),
        ),

        Provider<AnalyticsService>(
          create: (_) => AnalyticsService.instance,
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Linux Learning Chatbot',
            debugShowCheckedModeBanner: false,

            // Theme Configuration
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: authProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

            // Localization
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('th', 'TH'), // Thai (Primary)
              Locale('en', 'US'), // English (Secondary)
            ],
            locale: authProvider.currentLocale,

            // Initial Route
            home: const SplashScreen(),

            // Navigation
            navigatorKey: NavigationService.navigatorKey,
            onGenerateRoute: AppRouter.generateRoute,

            // Global Builder
            builder: (context, child) {
              // Error handling
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                return ErrorWidget.withDetails(
                  message: 'เกิดข้อผิดพลาด',
                  error: errorDetails.exception,
                );
              };

              // Text scaling
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: authProvider.textScale.clamp(0.8, 1.4),
                ),
                child: child!,
              );
            },

            // Scroll behavior
            scrollBehavior: const CustomScrollBehavior(),
          );
        },
      ),
    );
  }
}

// Custom scroll behavior for better touch support
class CustomScrollBehavior extends ScrollBehavior {
  const CustomScrollBehavior();

  @override
  Widget buildScrollbar(
      BuildContext context,
      Widget child,
      ScrollableDetails details,
      ) {
    switch (getPlatform(context)) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return Scrollbar(
          controller: details.controller,
          child: child,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        return child;
    }
  }
}

// Navigation service for global navigation
class NavigationService {
// Navigation service for global navigation
  class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
  return navigator!.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T>(String routeName, {Object? arguments}) {
  return navigator!.pushReplacementNamed<T>(routeName, arguments: arguments);
  }

  static void pop<T>([T? result]) {
  return navigator!.pop<T>(result);
  }

  static Future<T?> pushNamedAndClearStack<T>(String routeName, {Object? arguments}) {
  return navigator!.pushNamedAndRemoveUntil<T>(
  routeName,
  (route) => false,
  arguments: arguments,
  );
  }
  }

// App router for route management
  class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String learning = '/learning';
  static const String practice = '/practice';
  static const String terminal = '/terminal';
  static const String profile = '/profile';
  static const String progress = '/progress';
  static const String settings = '/settings';
  static const String achievements = '/achievements';
  static const String leaderboard = '/leaderboard';
  static const String lessonDetail = '/lesson-detail';
  static const String quiz = '/quiz';
  static const String commandDetail = '/command-detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
  case splash:
  return MaterialPageRoute(
  builder: (_) => const SplashScreen(),
  settings: settings,
  );

  case onboarding:
  return MaterialPageRoute(
  builder: (_) => const OnboardingScreen(),
  settings: settings,
  );

  case home:
  return MaterialPageRoute(
  builder: (_) => const HomeScreen(),
  settings: settings,
  );

  case chat:
  return MaterialPageRoute(
  builder: (_) => const ChatScreen(),
  settings: settings,
  );

  case learning:
  return MaterialPageRoute(
  builder: (_) => const LearningScreen(),
  settings: settings,
  );

  case practice:
  return MaterialPageRoute(
  builder: (_) => const PracticeScreen(),
  settings: settings,
  );

  case terminal:
  return MaterialPageRoute(
  builder: (_) => const TerminalScreen(),
  settings: settings,
  );

  case profile:
  return MaterialPageRoute(
  builder: (_) => const ProfileScreen(),
  settings: settings,
  );

  case progress:
  return MaterialPageRoute(
  builder: (_) => const ProgressScreen(),
  settings: settings,
  );

  case settings:
  return MaterialPageRoute(
  builder: (_) => const SettingsScreen(),
  settings: settings,
  );

  case achievements:
  return MaterialPageRoute(
  builder: (_) => const AchievementsScreen(),
  settings: settings,
  );

  case leaderboard:
  return MaterialPageRoute(
  builder: (_) => const LeaderboardScreen(),
  settings: settings,
  );

  case lessonDetail:
  final args = settings.arguments as Map<String, dynamic>?;
  return MaterialPageRoute(
  builder: (_) => LessonDetailScreen(
  lessonId: args?['lessonId'] ?? '',
  lesson: args?['lesson'],
  ),
  settings: settings,
  );

  case quiz:
  final args = settings.arguments as Map<String, dynamic>?;
  return MaterialPageRoute(
  builder: (_) => QuizScreen(
  quizId: args?['quizId'] ?? '',
  difficulty: args?['difficulty'] ?? 'beginner',
  category: args?['category'] ?? 'general',
  ),
  settings: settings,
  );

  case commandDetail:
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

// Import statements for screens (these would be actual imports in real implementation)
// For demonstration purposes, we'll create placeholder classes

  class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(title: const Text('เริ่มต้นใช้งาน')),
  body: const Center(
  child: Text('หน้าแนะนำการใช้งาน'),
  ),
  );
  }
  }

  class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(title: const Text('หน้าหลัก')),
  body: const Center(
  child: Text('หน้าหลักของแอป'),
  ),
  );
  }
  }

  class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(title: const Text('แชทบอท')),
  body: const Center(
  child: Text('หน้าแชทกับบอท'),
  ),
  );
  }
  }

  class LearningScreen extends StatelessWidget {
  const LearningScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(title: const Text('เรียนรู้')),
  body: const Center(
  child: Text('หน้าเรียนรู้'),
  ),
  );
  }
  }

  class PracticeScreen extends StatelessWidget {
  const PracticeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(title: const Text('ฝึกฝน')),
  body: const Center(
  child: Text('หน้าฝึกฝนทักษะ'),
  ),
  );
  }
  }

  class TerminalScreen extends StatelessWidget {
  const TerminalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(title: const Text('เทอร์มินัล')),
  body: const Center(
  child: Text('หน้าจำลองเทอร์มินัล'),
  ),
  );
  }
  }

  class ProgressScreen extends StatelessWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(title: const Text('ความก้าวหน้า')),
  body: const Center(
  child: Text('หน้าติดตามความก้าวหน้า'),
  ),
  );
  }
  }

  class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(title: const Text('การตั้งค่า')),
  body: const Center(
  child: Text('หน้าการตั้งค่า'),
  ),
  );
  }
  }

  class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(title: const Text('ความสำเร็จ')),
  body: const Center(
  child: Text('หน้าความสำเร็จ'),
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
  child: Text('ไม่พบหน้าที่ต้องการ'),
  ),
  );
  }
  } final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  static