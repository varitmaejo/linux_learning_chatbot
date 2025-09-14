import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import '../theme/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isInitialized = false;
  String _statusText = 'กำลังเริ่มต้น...';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Logo scale animation
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Text fade animation
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Slide animation for status text
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize Firebase services
      setState(() {
        _statusText = 'กำลังเชื่อมต่อ Firebase...';
      });
      await FirebaseService.instance.initialize();

      // Initialize Analytics
      setState(() {
        _statusText = 'กำลังตั้งค่าระบบ...';
      });
      await AnalyticsService.instance.initialize();

      // Initialize Auth Provider
      setState(() {
        _statusText = 'กำลังโหลดข้อมูลผู้ใช้...';
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isInitialized) {
        await authProvider.initialize();
      }

      // Wait for minimum splash duration
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _statusText = 'เสร็จสิ้น!';
        _isInitialized = true;
      });

      // Navigate to appropriate screen
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToNextScreen();

    } catch (e) {
      setState(() {
        _statusText = 'เกิดข้อผิดพลาด: $e';
      });

      // Show error dialog and retry option
      await Future.delayed(const Duration(seconds: 2));
      _showErrorDialog();
    }
  }

  void _navigateToNextScreen() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            // Check if user needs onboarding
            if (authProvider.needsOnboarding && !authProvider.isAuthenticated) {
              return const OnboardingScreen();
            } else {
              return const HomeScreen();
            }
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  void _showErrorDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.errorColor),
              const SizedBox(width: 8),
              const Text('เกิดข้อผิดพลาด'),
            ],
          ),
          content: const Text(
            'ไม่สามารถเริ่มต้นแอปพลิเคชันได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ตและลองใหม่อีกครั้ง',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retryInitialization();
              },
              child: const Text('ลองใหม่'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToOfflineMode();
              },
              child: const Text('ใช้งานแบบออฟไลน์'),
            ),
          ],
        );
      },
    );
  }

  void _retryInitialization() {
    setState(() {
      _isInitialized = false;
      _statusText = 'กำลังเริ่มต้นใหม่...';
    });
    _initializeApp();
  }

  void _navigateToOfflineMode() {
    // Navigate to home screen in offline mode
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.primaryGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top spacer
              const Expanded(flex: 2, child: SizedBox()),

              // Logo section
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated logo
                      AnimatedBuilder(
                        animation: _logoAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.terminal,
                                size: 60,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // App title
                      AnimatedBuilder(
                        animation: _textAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textAnimation.value,
                            child: Column(
                              children: [
                                Text(
                                  'Linux Learning',
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Chatbot',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 0.8,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '🐧 เรียนรู้ Linux อย่างสนุกสนาน',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Loading section
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Loading animation
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        backgroundColor: Colors.white.withOpacity(0.3),
                        strokeWidth: 3,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Status text
                    SlideTransition(
                      position: _slideAnimation,
                      child: AnimatedBuilder(
                        animation: _textAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textAnimation.value,
                            child: Text(
                              _statusText,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Version info
                    AnimatedBuilder(
                      animation: _textAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textAnimation.value * 0.7,
                          child: Text(
                            'เวอร์ชัน 1.0.0',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Bottom section
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedBuilder(
                      animation: _textAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textAnimation.value * 0.6,
                          child: Text(
                            'พัฒนาโดย AI Learning Team',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}