import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firebase_service.dart';
import '../../core/constants/firebase_constants.dart';
import '../../data/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error
}

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;

  AuthStatus _status = AuthStatus.initial;
  User? _firebaseUser;
  UserModel? _userModel;
  String? _errorMessage;
  bool _isInitialized = false;

  // Getters
  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUser => _userModel;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isAnonymous => _firebaseUser?.isAnonymous ?? false;
  String? get uid => _firebaseUser?.uid;

  /// Initialize auth provider
  Future<void> initialize() async {
    try {
      _setStatus(AuthStatus.loading);

      // Listen to auth state changes
      _firebaseService.authStateChanges.listen(_onAuthStateChanged);

      // Check current user
      _firebaseUser = _firebaseService.getCurrentUser();

      if (_firebaseUser != null) {
        await _loadUserModel(_firebaseUser!.uid);
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }

      _isInitialized = true;
      notifyListeners();

    } catch (e) {
      _setError('Initialization failed: ${e.toString()}');
    }
  }

  /// Handle auth state changes
  void _onAuthStateChanged(User? user) async {
    _firebaseUser = user;

    if (user != null) {
      await _loadUserModel(user.uid);
      _setStatus(AuthStatus.authenticated);
    } else {
      _userModel = null;
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Sign in anonymously
  Future<bool> signInAnonymously() async {
    try {
      _setStatus(AuthStatus.loading);

      final userCredential = await _firebaseService.signInAnonymously();

      if (userCredential?.user != null) {
        await _createUserModel(userCredential!.user!, isAnonymous: true);
        return true;
      }

      _setError('Failed to sign in anonymously');
      return false;

    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Sign in failed: ${e.toString()}');
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setStatus(AuthStatus.loading);

      final userCredential = await _firebaseService.signInWithEmailAndPassword(
        email.trim(),
        password,
      );

      if (userCredential?.user != null) {
        await _loadUserModel(userCredential!.user!.uid);
        return true;
      }

      _setError('Failed to sign in');
      return false;

    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Sign in failed: ${e.toString()}');
      return false;
    }
  }

  /// Create account with email and password
  Future<bool> createAccountWithEmailAndPassword(
      String email,
      String password,
      String displayName,
      ) async {
    try {
      _setStatus(AuthStatus.loading);

      final userCredential = await _firebaseService.createAccountWithEmailAndPassword(
        email.trim(),
        password,
      );

      if (userCredential?.user != null) {
        // Update display name
        await userCredential!.user!.updateDisplayName(displayName);

        // Create user model
        await _createUserModel(
          userCredential.user!,
          displayName: displayName,
          isAnonymous: false,
        );

        return true;
      }

      _setError('Failed to create account');
      return false;

    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Account creation failed: ${e.toString()}');
      return false;
    }
  }

  /// Convert anonymous account to permanent account
  Future<bool> convertAnonymousAccount(String email, String password, String displayName) async {
    try {
      if (_firebaseUser == null || !_firebaseUser!.isAnonymous) {
        _setError('No anonymous user to convert');
        return false;
      }

      _setStatus(AuthStatus.loading);

      // Create email credential
      final credential = EmailAuthProvider.credential(email: email, password: password);

      // Link anonymous account with email credential
      final userCredential = await _firebaseUser!.linkWithCredential(credential);

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(displayName);

        // Update user model
        await _updateUserModel({
          FirebaseConstants.emailField: email,
          FirebaseConstants.displayNameField: displayName,
          FirebaseConstants.isAnonymousField: false,
          FirebaseConstants.updatedAtField: FieldValue.serverTimestamp(),
        });

        return true;
      }

      _setError('Failed to convert anonymous account');
      return false;

    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Account conversion failed: ${e.toString()}');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      if (_firebaseUser == null) return false;

      _setStatus(AuthStatus.loading);

      // Update Firebase Auth profile
      if (displayName != null) {
        await _firebaseUser!.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await _firebaseUser!.updatePhotoURL(photoUrl);
      }

      // Update Firestore document
      final updateData = <String, dynamic>{
        FirebaseConstants.updatedAtField: FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updateData[FirebaseConstants.displayNameField] = displayName;
      }
      if (photoUrl != null) {
        updateData[FirebaseConstants.photoUrlField] = photoUrl;
      }

      await _updateUserModel(updateData);

      _setStatus(AuthStatus.authenticated);
      return true;

    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Password reset failed: ${e.toString()}');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _setStatus(AuthStatus.loading);
      await _firebaseService.signOut();
      _userModel = null;
      _setStatus(AuthStatus.unauthenticated);
    } catch (e) {
      _setError('Sign out failed: ${e.toString()}');
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    try {
      if (_firebaseUser == null) return false;

      _setStatus(AuthStatus.loading);

      // Delete user data from Firestore
      await _deleteUserData(_firebaseUser!.uid);

      // Delete Firebase Auth account
      await _firebaseUser!.delete();

      _userModel = null;
      _setStatus(AuthStatus.unauthenticated);
      return true;

    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Account deletion failed: ${e.toString()}');
      return false;
    }
  }

  /// Create user model in Firestore
  Future<void> _createUserModel(
      User firebaseUser, {
        String? displayName,
        bool isAnonymous = true,
      }) async {
    final userModel = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: displayName ?? firebaseUser.displayName ?? 'ผู้ใช้งาน',
      photoUrl: firebaseUser.photoURL,
      isAnonymous: isAnonymous,
      level: FirebaseConstants.defaultLevel,
      xp: FirebaseConstants.defaultXp,
      streak: FirebaseConstants.defaultStreak,
      totalCommandsLearned: 0,
      totalQuizzesCompleted: 0,
      totalTimeSpent: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastActive: DateTime.now(),
      preferences: const UserPreferences(),
    );

    await _firebaseService.createUserDocument(
      firebaseUser.uid,
      userModel.toMap(),
    );

    _userModel = userModel;
  }

  /// Load user model from Firestore
  Future<void> _loadUserModel(String uid) async {
    try {
      final doc = await _firebaseService.getUserDocument(uid);
      if (doc?.exists == true && doc?.data() != null) {
        _userModel = UserModel.fromMap(doc!.data() as Map<String, dynamic>);

        // Update last active
        await _updateLastActive();
      }
    } catch (e) {
      print('Error loading user model: $e');
    }
  }

  /// Update user model in Firestore
  Future<void> _updateUserModel(Map<String, dynamic> data) async {
    if (_firebaseUser == null) return;

    try {
      await _firebaseService.createUserDocument(_firebaseUser!.uid, data);

      // Reload user model
      await _loadUserModel(_firebaseUser!.uid);

    } catch (e) {
      print('Error updating user model: $e');
    }
  }

  /// Update last active timestamp
  Future<void> _updateLastActive() async {
    if (_firebaseUser == null) return;

    try {
      await _firebaseService.createUserDocument(_firebaseUser!.uid, {
        FirebaseConstants.lastActiveField: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last active: $e');
    }
  }

  /// Delete user data from Firestore
  Future<void> _deleteUserData(String uid) async {
    try {
      // Delete user document and subcollections
      final batch = FirebaseFirestore.instance.batch();

      // Delete user document
      batch.delete(
          FirebaseFirestore.instance.collection(FirebaseConstants.usersCollection).doc(uid)
      );

      await batch.commit();

    } catch (e) {
      print('Error deleting user data: $e');
    }
  }

  /// Set status and notify listeners
  void _setStatus(AuthStatus status) {
    _status = status;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set error and notify listeners
  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get user-friendly error message
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'ไม่พบผู้ใช้งานนี้';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว';
      case 'weak-password':
        return 'รหัสผ่านไม่ปลอดภัย';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีผู้ใช้งานถูกปิดใช้งาน';
      case 'too-many-requests':
        return 'มีการพยายามเข้าสู่ระบบมากเกินไป กรุณาลองใหม่ในภายหลัง';
      case 'network-request-failed':
        return 'เชื่อมต่อเครือข่ายไม่ได้';
      case 'requires-recent-login':
        return 'กรุณาเข้าสู่ระบบใหม่';
      case 'credential-already-in-use':
        return 'ข้อมูลการตรวจสอบสิทธิ์นี้ถูกใช้แล้ว';
      case 'invalid-credential':
        return 'ข้อมูลการตรวจสอบสิทธิ์ไม่ถูกต้อง';
      default:
        return 'เกิดข้อผิดพลาดในการตรวจสอบสิทธิ์: ${e.message}';
    }
  }
}