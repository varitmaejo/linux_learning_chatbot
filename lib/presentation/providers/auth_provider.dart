import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../constants/firebase_constants.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  // User state
  UserModel? _currentUser;
  User? _firebaseUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  // App settings
  bool _isDarkMode = false;
  Locale _currentLocale = const Locale('th', 'TH');
  double _textScale = 1.0;
  bool _notificationsEnabled = true;
  bool _voiceEnabled = true;
  bool _analyticsEnabled = true;
  bool _offlineMode = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _isDarkMode;
  Locale get currentLocale => _currentLocale;
  double get textScale => _textScale;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get voiceEnabled => _voiceEnabled;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get offlineMode => _offlineMode;

  // Initialize authentication
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Load settings from SharedPreferences
      await _loadSettings();

      // Listen to auth state changes
      _firebaseService.authStateChanges.listen(_onAuthStateChanged);

      // Check current user
      _firebaseUser = _firebaseService.currentUser;
      if (_firebaseUser != null) {
        await _loadUserProfile(_firebaseUser!.uid);
        _isAuthenticated = true;
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handle auth state changes
  void _onAuthStateChanged(User? user) async {
    try {
      _firebaseUser = user;

      if (user != null) {
        // User signed in
        await _loadUserProfile(user.uid);
        _isAuthenticated = true;

        // Log analytics
        await _analyticsService.logEvent('user_signed_in', {
          'user_id': user.uid,
          'is_anonymous': user.isAnonymous,
          'sign_in_method': user.providerData.isNotEmpty
              ? user.providerData.first.providerId
              : 'anonymous',
        });
      } else {
        // User signed out
        _currentUser = null;
        _isAuthenticated = false;

        await _analyticsService.logEvent('user_signed_out', {});
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling auth state change: $e');
    }
  }

  // Load user profile from Firebase
  Future<void> _loadUserProfile(String uid) async {
    try {
      final userProfile = await _firebaseService.getUserProfile(uid);
      if (userProfile != null) {
        _currentUser = userProfile;
      } else {
        // Create new user profile if doesn't exist
        await _createUserProfile();
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  // Create new user profile
  Future<void> _createUserProfile() async {
    if (_firebaseUser == null) return;

    try {
      _currentUser = UserModel(
        uid: _firebaseUser!.uid,
        email: _firebaseUser!.email ?? '',
        displayName: _firebaseUser!.displayName ?? 'ผู้ใช้งาน',
        photoURL: _firebaseUser!.photoURL,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isAnonymous: _firebaseUser!.isAnonymous,
      );

      // Save to Firebase
      await _firebaseService.usersCollection
          .doc(_firebaseUser!.uid)
          .set(_currentUser!.toMap());
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  // Sign in anonymously
  Future<bool> signInAnonymously() async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _firebaseService.signInAnonymously();

      // User profile will be created automatically in _onAuthStateChanged

      return credential.user != null;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _firebaseService.signInWithEmail(email, password);

      return AuthResult(
        success: true,
        user: credential.user,
        message: 'เข้าสู่ระบบสำเร็จ',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: e.code,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'unknown',
        message: 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create account with email and password
  Future<AuthResult> createAccountWithEmail(
      String email,
      String password,
      String displayName,
      ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _firebaseService.createAccountWithEmail(
        email,
        password,
        displayName,
      );

      return AuthResult(
        success: true,
        user: credential.user,
        message: 'สร้างบัญชีสำเร็จ',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: e.code,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'unknown',
        message: 'เกิดข้อผิดพลาดในการสร้างบัญชี',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.signOut();

      // Clear local data
      _currentUser = null;
      _firebaseUser = null;
      _isAuthenticated = false;
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? photoURL,
    String? currentDifficulty,
    String? preferredLanguage,
    Map<String, dynamic>? settings,
  }) async {
    if (_currentUser == null) return false;

    try {
      final updatedUser = _currentUser!.copyWith(
        displayName: displayName ?? _currentUser!.displayName,
        photoURL: photoURL ?? _currentUser!.photoURL,
        currentDifficulty: currentDifficulty ?? _currentUser!.currentDifficulty,
        preferredLanguage: preferredLanguage ?? _currentUser!.preferredLanguage,
        settings: settings ?? _currentUser!.settings,
        lastActivity: DateTime.now(),
      );

      await _firebaseService.updateUserProfile(
        _currentUser!.uid,
        updatedUser.toMap(),
      );

      _currentUser = updatedUser;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  // Settings methods

  // Toggle dark mode
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveSettings();
    notifyListeners();
  }

  // Set dark mode
  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    _saveSettings();
    notifyListeners();
  }

  // Change language
  void changeLanguage(String languageCode) {
    _currentLocale = Locale(languageCode, languageCode == 'th' ? 'TH' : 'US');
    _saveSettings();

    // Update user profile if authenticated
    if (_isAuthenticated) {
      updateUserProfile(preferredLanguage: languageCode);
    }

    notifyListeners();
  }

  // Set text scale
  void setTextScale(double scale) {
    _textScale = scale.clamp(0.8, 1.4);
    _saveSettings();
    notifyListeners();
  }

  // Toggle notifications
  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    _saveSettings();
    notifyListeners();
  }

  // Toggle voice
  void toggleVoice() {
    _voiceEnabled = !_voiceEnabled;
    _saveSettings();
    notifyListeners();
  }

  // Toggle analytics
  void toggleAnalytics() {
    _analyticsEnabled = !_analyticsEnabled;
    _saveSettings();
    notifyListeners();
  }

  // Toggle offline mode
  void toggleOfflineMode() {
    _offlineMode = !_offlineMode;
    _saveSettings();
    notifyListeners();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isDarkMode = prefs.getBool(FirebaseConstants.settingsDarkMode) ?? false;
      _textScale = prefs.getDouble(FirebaseConstants.settingsTextScale) ?? 1.0;
      _notificationsEnabled = prefs.getBool(FirebaseConstants.settingsNotificationsEnabled) ?? true;
      _voiceEnabled = prefs.getBool(FirebaseConstants.settingsVoiceEnabled) ?? true;
      _analyticsEnabled = prefs.getBool(FirebaseConstants.settingsAnalyticsEnabled) ?? true;
      _offlineMode = prefs.getBool(FirebaseConstants.settingsOfflineMode) ?? false;

      final languageCode = prefs.getString(FirebaseConstants.settingsLanguage) ?? 'th';
      _currentLocale = Locale(languageCode, languageCode == 'th' ? 'TH' : 'US');
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(FirebaseConstants.settingsDarkMode, _isDarkMode);
      await prefs.setDouble(FirebaseConstants.settingsTextScale, _textScale);
      await prefs.setBool(FirebaseConstants.settingsNotificationsEnabled, _notificationsEnabled);
      await prefs.setBool(FirebaseConstants.settingsVoiceEnabled, _voiceEnabled);
      await prefs.setBool(FirebaseConstants.settingsAnalyticsEnabled, _analyticsEnabled);
      await prefs.setBool(FirebaseConstants.settingsOfflineMode, _offlineMode);
      await prefs.setString(FirebaseConstants.settingsLanguage, _currentLocale.languageCode);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  // Get authentication error message in Thai
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'ไม่พบผู้ใช้งานนี้';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว';
      case 'weak-password':
        return 'รหัสผ่านง่ายเกินไป';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีผู้ใช้ถูกปิดใช้งาน';
      case 'too-many-requests':
        return 'มีการเข้าสู่ระบบมากเกินไป กรุณาลองใหม่ภายหลัง';
      case 'network-request-failed':
        return 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';
      default:
        return 'เกิดข้อผิดพลาดในการยืนยันตัวตน';
    }
  }

  // Check if user needs onboarding
  bool get needsOnboarding {
    return _currentUser == null ||
        _currentUser!.totalLessonsCompleted == 0;
  }

  // Get user experience level
  String get userExperienceLevel {
    if (_currentUser == null) return 'ผู้เริ่มต้น';
    return _currentUser!.experienceTitle;
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Authentication result class
class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  final String message;

  AuthResult({
    required this.success,
    this.user,
    this.error,
    required this.message,
  });
}