import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthStatus();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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

    // Slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _textController.forward();
      }
    });
  }

  void _checkAuthStatus() async {
    try {
      // Initialize auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();

      // Wait for animations to complete
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      // Navigate based on auth status
      if (authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } catch (e) {
      // Handle initialization error
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Section
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _logoAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
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
                ),
              ),

              // Text Section
              Expanded(
                flex: 2,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _textAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Linux Learning Chat',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'เรียนรู้คำสั่ง Linux ด้วย AI',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ฝึกฝนและทำความเข้าใจระบบปฏิบัติการ Linux',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Loading Section
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Linux Terminal Animation (if Lottie asset exists)
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          if (authProvider.status == AuthStatus.loading) {
                            return const LoadingWidget(
                              color: Colors.white,
                              size: 30,
                            );
                          }

                          // Terminal typing animation
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.terminalBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.terminalGreen,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: AnimatedBuilder(
                                animation: _textController,
                                builder: (context, child) {
                                  return Text(
                                    '> ${_getTypingText(_textController.value)}',
                                    style: const TextStyle(
                                      color: AppColors.terminalGreen,
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        String statusText = 'กำลังเตรียมความพร้อม...';

                        switch (authProvider.status) {
                          case AuthStatus.initial:
                            statusText = 'กำลังเริ่มต้น...';
                            break;
                          case AuthStatus.loading:
                            statusText = 'กำลังตรวจสอบสิทธิ์...';
                            break;
                          case AuthStatus.authenticated:
                            statusText = 'ยินดีต้อนรับ!';
                            break;
                          case AuthStatus.unauthenticated:
                            statusText = 'เตรียมความพร้อมเสร็จสิ้น';
                            break;
                          case AuthStatus.error:
                            statusText = 'เกิดข้อผิดพลาด';
                            break;
                        }

                        return Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Version Info
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'เวอร์ชัน 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypingText(double progress) {
    const text = 'ls -la';
    final length = (text.length * progress).round();
    return text.substring(0, length);
  }
}