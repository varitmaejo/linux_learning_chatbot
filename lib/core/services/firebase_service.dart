import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../constants/firebase_constants.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  // Firebase instances
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseStorage _storage;
  late FirebaseMessaging _messaging;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  FirebaseMessaging get messaging => _messaging;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase services
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Initialize Firebase
      await Firebase.initializeApp();

      // Initialize services
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _messaging = FirebaseMessaging.instance;

      // Configure Firestore settings
      await _configureFirestore();

      // Setup messaging
      await _setupMessaging();

      _isInitialized = true;
      print('Firebase services initialized successfully');

    } catch (e) {
      print('Error initializing Firebase services: $e');
      rethrow;
    }
  }

  /// Configure Firestore settings
  Future<void> _configureFirestore() async {
    try {
      // Enable offline persistence
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Enable network (in case it was disabled)
      await _firestore.enableNetwork();

    } catch (e) {
      print('Error configuring Firestore: $e');
    }
  }

  /// Setup Firebase Messaging
  Future<void> _setupMessaging() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');

        // Get FCM token
        String? token = await _messaging.getToken();
        print('FCM Token: $token');

        // Handle token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          print('FCM Token refreshed: $newToken');
          // Update token in Firestore if user is authenticated
          _updateFCMToken(newToken);
        });

      } else {
        print('User declined or has not accepted notification permission');
      }

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    } catch (e) {
      print('Error setting up messaging: $e');
    }
  }

  /// Update FCM token in Firestore
  Future<void> _updateFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  /// Sign in anonymously
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Error signing in anonymously: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in with email and password: $e');
      rethrow;
    }
  }

  /// Create account with email and password
  Future<UserCredential?> createAccountWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error creating account: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Create or update user document
  Future<void> createUserDocument(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .set(userData, SetOptions(merge: true));
    } catch (e) {
      print('Error creating user document: $e');
      rethrow;
    }
  }

  /// Get user document
  Future<DocumentSnapshot?> getUserDocument(String uid) async {
    try {
      return await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .get();
    } catch (e) {
      print('Error getting user document: $e');
      return null;
    }
  }

  /// Save chat message
  Future<void> saveChatMessage(String userId, Map<String, dynamic> messageData) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.chatMessagesCollection)
          .add(messageData);
    } catch (e) {
      print('Error saving chat message: $e');
      rethrow;
    }
  }

  /// Get chat messages
  Stream<QuerySnapshot> getChatMessages(String userId) {
    return _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .collection(FirebaseConstants.chatMessagesCollection)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Save learning progress
  Future<void> saveLearningProgress(String userId, Map<String, dynamic> progressData) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.learningProgressCollection)
          .doc(progressData['id'])
          .set(progressData, SetOptions(merge: true));
    } catch (e) {
      print('Error saving learning progress: $e');
      rethrow;
    }
  }

  /// Get learning progress
  Future<DocumentSnapshot?> getLearningProgress(String userId, String progressId) async {
    try {
      return await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.learningProgressCollection)
          .doc(progressId)
          .get();
    } catch (e) {
      print('Error getting learning progress: $e');
      return null;
    }
  }

  /// Save achievement
  Future<void> saveAchievement(String userId, Map<String, dynamic> achievementData) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .collection(FirebaseConstants.achievementsCollection)
          .doc(achievementData['id'])
          .set(achievementData, SetOptions(merge: true));
    } catch (e) {
      print('Error saving achievement: $e');
      rethrow;
    }
  }

  /// Get user achievements
  Stream<QuerySnapshot> getUserAchievements(String userId) {
    return _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .collection(FirebaseConstants.achievementsCollection)
        .snapshots();
  }

  /// Upload file to Firebase Storage
  Future<String?> uploadFile(String filePath, String fileName) async {
    try {
      final file = await _storage.ref().child(filePath).child(fileName);
      final uploadTask = file.putData(await _getFileBytes(fileName));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  /// Get file bytes (placeholder - implement based on your file handling)
  Future<List<int>> _getFileBytes(String fileName) async {
    // Implement file reading logic based on your needs
    throw UnimplementedError('Implement file reading logic');
  }

  /// Delete file from Firebase Storage
  Future<void> deleteFile(String filePath) async {
    try {
      await _storage.ref().child(filePath).delete();
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  /// Get analytics data
  Future<Map<String, dynamic>?> getAnalyticsData(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.analyticsCollection)
          .doc(userId)
          .get();
      return doc.data();
    } catch (e) {
      print('Error getting analytics data: $e');
      return null;
    }
  }

  /// Save analytics data
  Future<void> saveAnalyticsData(String userId, Map<String, dynamic> analyticsData) async {
    try {
      await _firestore
          .collection(FirebaseConstants.analyticsCollection)
          .doc(userId)
          .set(analyticsData, SetOptions(merge: true));
    } catch (e) {
      print('Error saving analytics data: $e');
    }
  }

  /// Batch write operations
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (var operation in operations) {
        final docRef = _firestore.doc(operation['path']);
        if (operation['type'] == 'set') {
          batch.set(docRef, operation['data'], SetOptions(merge: operation['merge'] ?? false));
        } else if (operation['type'] == 'update') {
          batch.update(docRef, operation['data']);
        } else if (operation['type'] == 'delete') {
          batch.delete(docRef);
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error performing batch write: $e');
      rethrow;
    }
  }

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Dispose resources
  void dispose() {
    // Clean up any listeners or resources if needed
  }
}

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}