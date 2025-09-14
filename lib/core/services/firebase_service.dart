import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../models/learning_progress.dart';
import '../models/chat_message.dart';
import '../models/achievement.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  FirebaseService._();

  // Firebase instances
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;
  FirebaseMessaging get messaging => FirebaseMessaging.instance;

  // Collections
  CollectionReference get usersCollection => firestore.collection('users');
  CollectionReference get progressCollection => firestore.collection('progress');
  CollectionReference get chatHistoryCollection => firestore.collection('chat_history');
  CollectionReference get achievementsCollection => firestore.collection('achievements');
  CollectionReference get leaderboardCollection => firestore.collection('leaderboard');

  // Initialize Firebase
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();

      // Initialize messaging
      await _initializeMessaging();

      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }

  // Initialize Firebase Messaging
  Future<void> _initializeMessaging() async {
    try {
      // Request permission for iOS
      if (Platform.isIOS) {
        await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
      }

      // Get FCM token
      final token = await messaging.getToken();
      print('FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    } catch (e) {
      print('Error initializing messaging: $e');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    // Handle foreground notification
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Received background message: ${message.messageId}');
    // Handle background notification
  }

  // Handle notification taps
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    // Navigate to appropriate screen
  }

  // Authentication Methods

  // Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    try {
      final credential = await auth.signInAnonymously();
      await _createUserProfile(credential.user!);
      return credential;
    } catch (e) {
      print('Error signing in anonymously: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }

  // Create account with email and password
  Future<UserCredential> createAccountWithEmail(String email, String password, String displayName) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user!.updateDisplayName(displayName);

      // Create user profile
      await _createUserProfile(credential.user!);

      return credential;
    } catch (e) {
      print('Error creating account: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(User user) async {
    try {
      final userDoc = usersCollection.doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'ผู้ใช้งาน',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          level: 1,
          xp: 0,
          streak: 0,
          totalLessonsCompleted: 0,
          currentDifficulty: 'beginner',
          preferredLanguage: 'th',
          isAnonymous: user.isAnonymous,
        );

        await userDoc.set(userModel.toMap());
      } else {
        // Update last login
        await userDoc.update({'lastLoginAt': DateTime.now()});
      }
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // User Data Methods

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await usersCollection.doc(uid).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Learning Progress Methods

  // Save learning progress
  Future<void> saveLearningProgress(String uid, LearningProgress progress) async {
    try {
      await progressCollection.doc('${uid}_${progress.commandName}').set(progress.toMap());

      // Update user stats
      await _updateUserStats(uid, progress);

      // Track analytics event
      await analytics.logEvent(
        name: 'lesson_completed',
        parameters: {
          'command_name': progress.commandName,
          'difficulty': progress.difficulty,
          'accuracy': progress.accuracy,
          'completion_time': progress.completionTimeInSeconds,
        },
      );
    } catch (e) {
      print('Error saving learning progress: $e');
      rethrow;
    }
  }

  // Get learning progress
  Future<List<LearningProgress>> getLearningProgress(String uid) async {
    try {
      final query = await progressCollection
          .where('userId', isEqualTo: uid)
          .orderBy('completedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => LearningProgress.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting learning progress: $e');
      return [];
    }
  }

  // Update user stats based on progress
  Future<void> _updateUserStats(String uid, LearningProgress progress) async {
    try {
      final userDoc = usersCollection.doc(uid);
      final userSnapshot = await userDoc.get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;
        final currentXP = userData['xp'] ?? 0;
        final currentLevel = userData['level'] ?? 1;
        final completedLessons = userData['totalLessonsCompleted'] ?? 0;

        // Calculate XP gain based on difficulty and accuracy
        int xpGain = _calculateXPGain(progress.difficulty, progress.accuracy);
        final newXP = currentXP + xpGain;
        final newLevel = _calculateLevel(newXP);

        await userDoc.update({
          'xp': newXP,
          'level': newLevel,
          'totalLessonsCompleted': completedLessons + 1,
          'lastActivity': DateTime.now(),
        });

        // Check for achievements
        await _checkAchievements(uid, newLevel, completedLessons + 1, progress);
      }
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  // Calculate XP gain
  int _calculateXPGain(String difficulty, double accuracy) {
    int baseXP = switch (difficulty) {
      'beginner' => 10,
      'intermediate' => 20,
      'advanced' => 30,
      'expert' => 50,
      _ => 10,
    };

    return (baseXP * accuracy).round();
  }

  // Calculate level from XP
  int _calculateLevel(int xp) {
    return (xp / 100).floor() + 1;
  }

  // Check for achievements
  Future<void> _checkAchievements(String uid, int level, int completedLessons, LearningProgress progress) async {
    try {
      List<Achievement> newAchievements = [];

      // Level-based achievements
      if (level == 5) {
        newAchievements.add(Achievement(
          id: 'level_5',
          title: 'ผู้เรียนรู้ขั้นพื้นฐาน',
          description: 'ขึ้นถึงระดับ 5',
          iconPath: 'assets/icons/achievements/level_5.png',
          unlockedAt: DateTime.now(),
        ));
      }

      // Lesson completion achievements
      if (completedLessons == 10) {
        newAchievements.add(Achievement(
          id: 'lessons_10',
          title: 'ผู้ขยัน',
          description: 'เรียนจบ 10 บทเรียน',
          iconPath: 'assets/icons/achievements/lessons_10.png',
          unlockedAt: DateTime.now(),
        ));
      }

      // Accuracy achievements
      if (progress.accuracy >= 0.95) {
        newAchievements.add(Achievement(
          id: 'perfect_accuracy',
          title: 'ผู้เก่งกาจ',
          description: 'ทำคะแนนได้ 95% ขึ้นไป',
          iconPath: 'assets/icons/achievements/perfect.png',
          unlockedAt: DateTime.now(),
        ));
      }

      // Save achievements
      for (final achievement in newAchievements) {
        await achievementsCollection.doc('${uid}_${achievement.id}').set({
          ...achievement.toMap(),
          'userId': uid,
        });
      }

    } catch (e) {
      print('Error checking achievements: $e');
    }
  }

  // Chat History Methods

  // Save chat message
  Future<void> saveChatMessage(String uid, ChatMessage message) async {
    try {
      await chatHistoryCollection.add({
        ...message.toMap(),
        'userId': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving chat message: $e');
    }
  }

  // Get chat history
  Future<List<ChatMessage>> getChatHistory(String uid, {int limit = 50}) async {
    try {
      final query = await chatHistoryCollection
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => ChatMessage.fromMap(doc.data() as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      print('Error getting chat history: $e');
      return [];
    }
  }

  // Analytics Methods

  // Log custom event
  Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      print('Error logging event: $e');
    }
  }

  // Log screen view
  Future<void> logScreenView(String screenName) async {
    try {
      await analytics.logScreenView(screenName: screenName);
    } catch (e) {
      print('Error logging screen view: $e');
    }
  }

  // Leaderboard Methods

  // Update leaderboard
  Future<void> updateLeaderboard(String uid, int xp, int level) async {
    try {
      await leaderboardCollection.doc(uid).set({
        'uid': uid,
        'xp': xp,
        'level': level,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating leaderboard: $e');
    }
  }

  // Get leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 20}) async {
    try {
      final query = await leaderboardCollection
          .orderBy('xp', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  // Get current user
  User? get currentUser => auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Listen to auth state changes
  Stream<User?> get authStateChanges => auth.authStateChanges();
}