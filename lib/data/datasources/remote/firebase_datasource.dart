import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/user.dart' as domain;
import '../../../domain/entities/message.dart';
import '../../../domain/entities/progress.dart';
import '../../models/user_model.dart';
import '../../models/chat_message.dart';
import '../../models/learning_progress.dart';
import '../../models/achievement.dart';

class FirebaseDatasource {
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Singleton pattern
  static final FirebaseDatasource _instance = FirebaseDatasource._internal();
  factory FirebaseDatasource() => _instance;
  FirebaseDatasource._internal();

  // Collection references
  CollectionReference get _usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference get _chatCollection =>
      _firestore.collection(AppConstants.chatCollection);

  CollectionReference get _commandsCollection =>
      _firestore.collection(AppConstants.commandsCollection);

  CollectionReference get _progressCollection =>
      _firestore.collection(AppConstants.progressCollection);

  CollectionReference get _achievementsCollection =>
      _firestore.collection(AppConstants.achievementsCollection);

  // Authentication
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isAuthenticated => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();

      // Log analytics event
      await _analytics.logLogin(loginMethod: 'anonymous');

      return credential;
    } catch (error) {
      await _crashlytics.recordError(error, null, information: 'Anonymous sign in failed');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _analytics.logEvent(name: 'user_logout');
    } catch (error) {
      await _crashlytics.recordError(error, null, information: 'Sign out failed');
      rethrow;
    }
  }

  // User Management
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromJson({...data, 'id': doc.id});
      }
      return null;
    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to get user: $userId');
      throw Exception('Failed to get user: $error');
    }
  }

  Future<void> saveUser(UserModel user) async {
    try {
      final data = user.toJson();
      data.remove('id'); // Remove id from data as it's used as document ID

      await _usersCollection.doc(user.id).set(data, SetOptions(merge: true));

      // Set user properties for analytics
      await _analytics.setUserId(id: user.id);
      await _analytics.setUserProperty(name: 'skill_level', value: user.skillLevel);
      await _analytics.setUserProperty(name: 'user_level', value: user.currentLevel.toString());

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to save user: ${user.id}');
      throw Exception('Failed to save user: $error');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _usersCollection.doc(userId).update({
        ...updates,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to update user: $userId');
      throw Exception('Failed to update user: $error');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Delete user document and all related data
      await _firestore.runTransaction((transaction) async {
        // Delete user document
        transaction.delete(_usersCollection.doc(userId));

        // Delete chat history
        final chatQuery = await _chatCollection.where('userId', isEqualTo: userId).get();
        for (final doc in chatQuery.docs) {
          transaction.delete(doc.reference);
        }

        // Delete progress
        final progressQuery = await _progressCollection.where('userId', isEqualTo: userId).get();
        for (final doc in progressQuery.docs) {
          transaction.delete(doc.reference);
        }

        // Delete achievements
        final achievementsQuery = await _achievementsCollection.where('userId', isEqualTo: userId).get();
        for (final doc in achievementsQuery.docs) {
          transaction.delete(doc.reference);
        }
      });

      await _analytics.logEvent(name: 'user_deleted', parameters: {'user_id': userId});

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to delete user: $userId');
      throw Exception('Failed to delete user: $error');
    }
  }

  // Chat Management
  Future<List<Message>> getChatHistory(String userId, {int limit = 50}) async {
    try {
      final query = await _chatCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatMessage.fromJson({...data, 'id': doc.id});
      }).cast<Message>().toList();

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to get chat history for user: $userId');
      throw Exception('Failed to get chat history: $error');
    }
  }

  Future<void> saveChatMessage(Message message) async {
    try {
      final chatMessage = ChatMessage.fromEntity(message);
      final data = chatMessage.toJson();
      data.remove('id'); // Remove id as it will be auto-generated

      await _chatCollection.add({
        ...data,
        'userId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Log analytics event
      await _analytics.logEvent(
        name: 'message_sent',
        parameters: {
          'message_type': message.messageType.toString(),
          'is_from_user': message.isFromUser,
          'user_id': currentUserId,
        },
      );

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to save chat message');
      throw Exception('Failed to save chat message: $error');
    }
  }

  Future<void> clearChatHistory(String userId) async {
    try {
      final query = await _chatCollection.where('userId', isEqualTo: userId).get();

      // Delete in batches to avoid timeout
      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await _analytics.logEvent(name: 'chat_history_cleared',
          parameters: {'user_id': userId});

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to clear chat history for user: $userId');
      throw Exception('Failed to clear chat history: $error');
    }
  }

  // Learning Progress Management
  Future<LearningProgress?> getProgress(String userId, String category) async {
    try {
      final query = await _progressCollection
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return LearningProgress.fromJson({...data, 'id': doc.id});
      }
      return null;

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to get progress for user: $userId, category: $category');
      throw Exception('Failed to get progress: $error');
    }
  }

  Future<List<LearningProgress>> getAllProgress(String userId) async {
    try {
      final query = await _progressCollection
          .where('userId', isEqualTo: userId)
          .get();

      return query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return LearningProgress.fromJson({...data, 'id': doc.id});
      }).toList();

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to get all progress for user: $userId');
      throw Exception('Failed to get all progress: $error');
    }
  }

  Future<void> saveProgress(LearningProgress progress) async {
    try {
      final data = progress.toJson();
      data.remove('id');

      await _progressCollection.doc(progress.id).set(data, SetOptions(merge: true));

      // Log analytics event
      await _analytics.logEvent(
        name: 'progress_updated',
        parameters: {
          'user_id': progress.userId,
          'category': progress.category,
          'progress_percentage': progress.progressPercentage,
          'current_level': progress.currentLevel,
        },
      );

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to save progress: ${progress.id}');
      throw Exception('Failed to save progress: $error');
    }
  }

  // Achievement Management
  Future<List<Achievement>> getAchievements(String userId) async {
    try {
      final query = await _achievementsCollection
          .where('userId', isEqualTo: userId)
          .get();

      return query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Achievement.fromJson({...data, 'id': doc.id});
      }).toList();

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to get achievements for user: $userId');
      throw Exception('Failed to get achievements: $error');
    }
  }

  Future<void> saveAchievement(Achievement achievement) async {
    try {
      final data = achievement.toJson();
      data.remove('id');

      await _achievementsCollection.doc(achievement.id).set(data, SetOptions(merge: true));

      // Log analytics event for achievement unlock
      if (achievement.isUnlocked) {
        await _analytics.logEvent(
          name: 'achievement_unlocked',
          parameters: {
            'achievement_id': achievement.id,
            'achievement_title': achievement.title,
            'user_id': achievement.userId,
            'xp_reward': achievement.xpReward,
            'rarity': achievement.rarity.toString(),
          },
        );
      }

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to save achievement: ${achievement.id}');
      throw Exception('Failed to save achievement: $error');
    }
  }

  // Linux Commands Data
  Future<List<Map<String, dynamic>>> getLinuxCommands({
    String? category,
    String? difficulty,
    int? limit,
  }) async {
    try {
      Query query = _commandsCollection;

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final result = await query.get();

      return result.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to get Linux commands');
      throw Exception('Failed to get Linux commands: $error');
    }
  }

  Future<Map<String, dynamic>?> getLinuxCommand(String commandId) async {
    try {
      final doc = await _commandsCollection.doc(commandId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }
      return null;

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to get Linux command: $commandId');
      throw Exception('Failed to get Linux command: $error');
    }
  }

  Future<List<Map<String, dynamic>>> searchCommands(String query) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a simple implementation using array-contains
      final result = await _commandsCollection
          .where('searchTerms', arrayContains: query.toLowerCase())
          .limit(20)
          .get();

      return result.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to search commands with query: $query');
      throw Exception('Failed to search commands: $error');
    }
  }

  // File Storage
  Future<String> uploadFile(String filePath, String fileName, String folder) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref().child('$folder/$fileName');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _analytics.logEvent(
        name: 'file_uploaded',
        parameters: {
          'file_name': fileName,
          'folder': folder,
          'user_id': currentUserId,
        },
      );

      return downloadUrl;

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to upload file: $fileName');
      throw Exception('Failed to upload file: $error');
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to delete file: $fileUrl');
      throw Exception('Failed to delete file: $error');
    }
  }

  // Analytics and Tracking
  Future<void> logEvent(String eventName, Map<String, dynamic>? parameters) async {
    try {
      await _analytics.logEvent(name: eventName, parameters: parameters);
    } catch (error) {
      // Don't throw error for analytics, just log it
      await _crashlytics.recordError(error, null,
          information: 'Failed to log analytics event: $eventName');
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to log screen view: $screenName');
    }
  }

  Future<void> logUserAction(String action, Map<String, dynamic>? parameters) async {
    await logEvent('user_action', {
      'action': action,
      'user_id': currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
      ...?parameters,
    });
  }

  Future<void> logLearningActivity(String activity, {
    String? category,
    String? commandId,
    int? duration,
    bool? success,
  }) async {
    await logEvent('learning_activity', {
      'activity': activity,
      'category': category,
      'command_id': commandId,
      'duration_seconds': duration,
      'success': success,
      'user_id': currentUserId,
    });
  }

  // Error Reporting
  Future<void> recordError(dynamic error, StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? information,
  }) async {
    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        information: information ?? <String, dynamic>{},
        fatal: false,
      );
    } catch (e) {
      // If crashlytics fails, at least print to console
      print('Failed to record error to Crashlytics: $e');
      print('Original error: $error');
    }
  }

  Future<void> recordFlutterError(FlutterErrorDetails errorDetails) async {
    try {
      await _crashlytics.recordFlutterError(errorDetails);
    } catch (e) {
      print('Failed to record Flutter error: $e');
    }
  }

  // App Configuration
  Future<Map<String, dynamic>> getAppConfig() async {
    try {
      final doc = await _firestore.collection('config').doc('app').get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to get app config');
      return {};
    }
  }

  Future<Map<String, dynamic>> getFeatureFlags() async {
    try {
      final doc = await _firestore.collection('config').doc('features').get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to get feature flags');
      return {};
    }
  }

  // Real-time Updates
  Stream<UserModel?> getUserStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromJson({...data, 'id': doc.id});
      }
      return null;
    });
  }

  Stream<List<Message>> getChatStream(String userId, {int limit = 20}) {
    return _chatCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatMessage.fromJson({...data, 'id': doc.id});
      }).cast<Message>().toList();
    });
  }

  Stream<List<LearningProgress>> getProgressStream(String userId) {
    return _progressCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return LearningProgress.fromJson({...data, 'id': doc.id});
      }).toList();
    });
  }

  // Batch Operations
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        final type = operation['type'] as String;
        final collection = operation['collection'] as String;
        final docId = operation['docId'] as String?;
        final data = operation['data'] as Map<String, dynamic>?;

        final collectionRef = _firestore.collection(collection);
        final docRef = docId != null ? collectionRef.doc(docId) : collectionRef.doc();

        switch (type) {
          case 'set':
            batch.set(docRef, data!);
            break;
          case 'update':
            batch.update(docRef, data!);
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to execute batch write');
      throw Exception('Failed to execute batch write: $error');
    }
  }

  // Data Export
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final user = await getUser(userId);
      final chatHistory = await getChatHistory(userId, limit: 1000);
      final progress = await getAllProgress(userId);
      final achievements = await getAchievements(userId);

      return {
        'user': user?.toJson(),
        'chatHistory': chatHistory.map((m) => (m as ChatMessage).toJson()).toList(),
        'progress': progress.map((p) => p.toJson()).toList(),
        'achievements': achievements.map((a) => a.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to export user data: $userId');
      throw Exception('Failed to export user data: $error');
    }
  }

  // Connection Status
  Future<bool> checkConnection() async {
    try {
      // Try to read a small document to test connection
      await _firestore.collection('test').doc('connection').get();
      return true;
    } catch (error) {
      return false;
    }
  }

  // Offline Support
  Future<void> enableOfflineSupport() async {
    try {
      await _firestore.enablePersistence();
    } catch (error) {
      // Persistence may already be enabled
      print('Firestore persistence already enabled or failed: $error');
    }
  }

  Future<void> disableOfflineSupport() async {
    try {
      await _firestore.disablePersistence();
    } catch (error) {
      print('Failed to disable Firestore persistence: $error');
    }
  }

  // Admin Functions (if user has admin role)
  Future<List<Map<String, dynamic>>> getAllUsers({int limit = 100}) async {
    try {
      final query = await _usersCollection.limit(limit).get();

      return query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to get all users (admin function)');
      throw Exception('Failed to get all users: $error');
    }
  }

  Future<Map<String, dynamic>> getAppStatistics() async {
    try {
      // This would typically be implemented using Firebase Functions
      // for better performance and security
      final usersSnapshot = await _usersCollection.count().get();
      final chatSnapshot = await _chatCollection.count().get();
      final progressSnapshot = await _progressCollection.count().get();

      return {
        'totalUsers': usersSnapshot.count,
        'totalMessages': chatSnapshot.count,
        'totalProgress': progressSnapshot.count,
        'generatedAt': DateTime.now().toIso8601String(),
      };

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to get app statistics');
      throw Exception('Failed to get app statistics: $error');
    }
  }

  // Cleanup old data
  Future<void> cleanupOldData() async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: 90));
      final timestamp = Timestamp.fromDate(cutoffDate);

      // Clean up old chat messages
      final oldChatQuery = await _chatCollection
          .where('timestamp', isLessThan: timestamp)
          .get();

      // Delete in batches
      const batchSize = 500;
      final docs = oldChatQuery.docs;

      for (int i = 0; i < docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final batchDocs = docs.skip(i).take(batchSize);

        for (final doc in batchDocs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }

      await _analytics.logEvent(name: 'data_cleanup_completed',
          parameters: {'deleted_messages': docs.length});

    } catch (error) {
      await _crashlytics.recordError(error, null,
          information: 'Failed to cleanup old data');
      throw Exception('Failed to cleanup old data: $error');
    }
  }
}