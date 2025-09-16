import 'dart:async';

import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository_interface.dart';
import '../models/user_model.dart';
import '../datasources/local/hive_datasource.dart';
import '../datasources/local/shared_prefs_datasource.dart';
import '../datasources/remote/firebase_datasource.dart';

class UserRepository implements UserRepositoryInterface {
  final HiveDatasource _localDataSource;
  final SharedPrefsDatasource _prefsDataSource;
  final FirebaseDatasource _remoteDataSource;

  UserRepository({
    required HiveDatasource localDataSource,
    required SharedPrefsDatasource prefsDataSource,
    required FirebaseDatasource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _prefsDataSource = prefsDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<User?> getCurrentUser() async {
    try {
      // First try to get current user ID from preferences
      final currentUserId = _prefsDataSource.getCurrentUserId();

      if (currentUserId != null) {
        // Get user from local storage first
        final localUser = await _localDataSource.getUser(currentUserId);

        if (localUser != null) {
          return localUser;
        }

        // If not in local storage, try remote
        if (_remoteDataSource.isAuthenticated) {
          final remoteUser = await _remoteDataSource.getUser(currentUserId);
          if (remoteUser != null) {
            // Save to local storage for offline access
            await _localDataSource.saveUser(remoteUser);
            return remoteUser;
          }
        }
      }

      return null;
    } catch (error) {
      throw Exception('Failed to get current user: $error');
    }
  }

  @override
  Future<User?> getUserById(String userId) async {
    try {
      // Try local first
      final localUser = await _localDataSource.getUser(userId);
      if (localUser != null) {
        return localUser;
      }

      // Try remote
      if (_remoteDataSource.isAuthenticated) {
        final remoteUser = await _remoteDataSource.getUser(userId);
        if (remoteUser != null) {
          // Cache locally
          await _localDataSource.saveUser(remoteUser);
          return remoteUser;
        }
      }

      return null;
    } catch (error) {
      throw Exception('Failed to get user by ID: $error');
    }
  }

  @override
  Future<User> createUser({
    required String name,
    required String email,
    String? avatar,
    String skillLevel = 'beginner',
  }) async {
    try {
      // Create new user model
      final newUser = UserModel.defaultUser().copyWith(
        name: name,
        email: email,
        avatar: avatar,
        skillLevel: skillLevel,
      );

      // Save to local storage
      await _localDataSource.saveUser(newUser);

      // Set as current user
      await _prefsDataSource.setCurrentUserId(newUser.id);
      await _prefsDataSource.setLastLoginTime(DateTime.now());

      // Save to remote if connected
      if (_remoteDataSource.isAuthenticated) {
        try {
          await _remoteDataSource.saveUser(newUser);
        } catch (remoteError) {
          // Don't fail if remote save fails, user is still created locally
          print('Warning: Failed to save user to remote: $remoteError');
        }
      }

      return newUser;
    } catch (error) {
      throw Exception('Failed to create user: $error');
    }
  }

  @override
  Future<User> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final currentUser = await getUserById(userId);
      if (currentUser == null) {
        throw Exception('User not found');
      }

      final userModel = currentUser is UserModel
          ? currentUser
          : UserModel.fromEntity(currentUser);

      // Create updated user
      final updatedUser = userModel.copyWith(
        name: updates['name'],
        email: updates['email'],
        avatar: updates['avatar'],
        skillLevel: updates['skillLevel'],
        currentXP: updates['currentXP'],
        currentLevel: updates['currentLevel'],
        totalPoints: updates['totalPoints'],
        streakDays: updates['streakDays'],
        lastActivityDate: updates['lastActivityDate'],
        completedLessons: updates['completedLessons'],
        unlockedAchievements: updates['unlockedAchievements'],
        preferences: updates['preferences'],
        categoryProgress: updates['categoryProgress'],
        favoriteCommands: updates['favoriteCommands'],
        stats: updates['stats'],
        lastLoginAt: DateTime.now(),
      );

      // Save to local storage
      await _localDataSource.saveUser(updatedUser);

      // Update remote if connected
      if (_remoteDataSource.isAuthenticated) {
        try {
          await _remoteDataSource.updateUser(userId, {
            ...updates,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
        } catch (remoteError) {
          print('Warning: Failed to update user on remote: $remoteError');
        }
      }

      return updatedUser;
    } catch (error) {
      throw Exception('Failed to update user: $error');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      // Delete from local storage
      await _localDataSource.deleteUser(userId);

      // Clear from preferences if it's the current user
      final currentUserId = _prefsDataSource.getCurrentUserId();
      if (currentUserId == userId) {
        await _prefsDataSource.clearUserSpecificData();
      }

      // Delete from remote
      if (_remoteDataSource.isAuthenticated) {
        try {
          await _remoteDataSource.deleteUser(userId);
        } catch (remoteError) {
          print('Warning: Failed to delete user from remote: $remoteError');
        }
      }
    } catch (error) {
      throw Exception('Failed to delete user: $error');
    }
  }

  @override
  Future<User> signInAnonymously() async {
    try {
      // Sign in with Firebase
      final credential = await _remoteDataSource.signInAnonymously();

      if (credential?.user == null) {
        throw Exception('Failed to sign in anonymously');
      }

      final firebaseUser = credential!.user!;

      // Check if user already exists
      final existingUser = await _remoteDataSource.getUser(firebaseUser.uid);

      if (existingUser != null) {
        // User exists, save locally and set as current
        await _localDataSource.saveUser(existingUser);
        await _prefsDataSource.setCurrentUserId(existingUser.id);
        return existingUser;
      } else {
        // Create new user
        final newUser = UserModel.defaultUser().copyWith(
          id: firebaseUser.uid,
          name: 'ผู้เรียนใหม่',
          email: firebaseUser.email ?? '',
        );

        // Save to both local and remote
        await _localDataSource.saveUser(newUser);
        await _remoteDataSource.saveUser(newUser);
        await _prefsDataSource.setCurrentUserId(newUser.id);

        return newUser;
      }
    } catch (error) {
      throw Exception('Failed to sign in anonymously: $error');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Clear local user preferences
      await _prefsDataSource.clearUserSpecificData();

      // Sign out from remote
      await _remoteDataSource.signOut();
    } catch (error) {
      throw Exception('Failed to sign out: $error');
    }
  }

  @override
  Future<User> addXP(String userId, int xp) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      final userModel = user is UserModel
          ? user
          : UserModel.fromEntity(user);

      final newXP = userModel.currentXP + xp;
      final newTotalPoints = userModel.totalPoints + xp;

      // Calculate new level
      int newLevel = userModel.currentLevel;
      const levelRequirements = {
        1: 0, 2: 100, 3: 250, 4: 500, 5: 1000,
        6: 1750, 7: 2750, 8: 4000, 9: 5500, 10: 7250,
      };

      for (int level = 10; level >= 1; level--) {
        if (newXP >= (levelRequirements[level] ?? 0)) {
          newLevel = level;
          break;
        }
      }

      return await updateUser(userId, {
        'currentXP': newXP,
        'currentLevel': newLevel,
        'totalPoints': newTotalPoints,
        'lastActivityDate': DateTime.now(),
      });
    } catch (error) {
      throw Exception('Failed to add XP: $error');
    }
  }

  @override
  Future<User> updateStreak(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      final userModel = user is UserModel
          ? user
          : UserModel.fromEntity(user);

      final now = DateTime.now();
      int newStreak = userModel.streakDays;

      if (userModel.lastActivityDate == null) {
        newStreak = 1;
      } else {
        final daysSinceLastActivity = now.difference(userModel.lastActivityDate!).inDays;

        if (daysSinceLastActivity == 1) {
          // Consecutive day
          newStreak = userModel.streakDays + 1;
        } else if (daysSinceLastActivity > 1) {
          // Streak broken
          newStreak = 1;
        }
        // If same day, keep current streak
      }

      return await updateUser(userId, {
        'streakDays': newStreak,
        'lastActivityDate': now,
      });
    } catch (error) {
      throw Exception('Failed to update streak: $error');
    }
  }

  @override
  Future<User> completeLesson(String userId, String lessonId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      final userModel = user is UserModel
          ? user
          : UserModel.fromEntity(user);

      if (!userModel.completedLessons.contains(lessonId)) {
        final updatedLessons = List<String>.from(userModel.completedLessons)
          ..add(lessonId);

        // Add XP for completing lesson
        final updatedUser = await updateUser(userId, {
          'completedLessons': updatedLessons,
        });

        // Add XP separately to trigger level calculation
        return await addXP(userId, 25); // 25 XP per lesson
      }

      return userModel;
    } catch (error) {
      throw Exception('Failed to complete lesson: $error');
    }
  }

  @override
  Future<User> unlockAchievement(String userId, String achievementId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      final userModel = user is UserModel
          ? user
          : UserModel.fromEntity(user);

      if (!userModel.unlockedAchievements.contains(achievementId)) {
        final updatedAchievements = List<String>.from(userModel.unlockedAchievements)
          ..add(achievementId);

        final updatedUser = await updateUser(userId, {
          'unlockedAchievements': updatedAchievements,
        });

        // Add XP for achievement
        return await addXP(userId, 100); // 100 XP per achievement
      }

      return userModel;
    } catch (error) {
      throw Exception('Failed to unlock achievement: $error');
    }
  }

  @override
  Future<User> updateCategoryProgress(String userId, String category, int score) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      final userModel = user is UserModel
          ? user
          : UserModel.fromEntity(user);

      final updatedCategoryProgress = Map<String, int>.from(userModel.categoryProgress);
      updatedCategoryProgress[category] = score;

      return await updateUser(userId, {
        'categoryProgress': updatedCategoryProgress,
      });
    } catch (error) {
      throw Exception('Failed to update category progress: $error');
    }
  }

  @override
  Future<User> addFavoriteCommand(String userId, String command) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      final userModel = user is UserModel
          ? user
          : UserModel.fromEntity(user);

      if (!userModel.favoriteCommands.contains(command)) {
        final updatedFavorites = List<String>.from(userModel.favoriteCommands)
          ..add(command);

        return await updateUser(userId, {
          'favoriteCommands': updatedFavorites,
        });
      }

      return userModel;
    } catch (error) {
      throw Exception('Failed to add favorite command: $error');
    }
  }

  @override
  Future<User> removeFavoriteCommand(String userId, String command) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      final userModel = user is UserModel
          ? user
          : UserModel.fromEntity(user);

      final updatedFavorites = List<String>.from(userModel.favoriteCommands)
        ..remove(command);

      return await updateUser(userId, {
        'favoriteCommands': updatedFavorites,
      });
    } catch (error) {
      throw Exception('Failed to remove favorite command: $error');
    }
  }

  @override
  Future<User> updateStats(String userId, Map<String, dynamic> stats) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      final userModel = user is UserModel
          ? user
          : UserModel.fromEntity(user);

      final updatedStats = Map<String, dynamic>.from(userModel.stats);
      updatedStats.addAll(stats);

      return await updateUser(userId, {
        'stats': updatedStats,
      });
    } catch (error) {
      throw Exception('Failed to update stats: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      // Get data from local storage
      final localData = await _localDataSource.exportUserData(userId);

      // Try to get data from remote if connected
      if (_remoteDataSource.isAuthenticated) {
        try {
          final remoteData = await _remoteDataSource.exportUserData(userId);

          // Merge local and remote data, preferring remote for user data
          return {
            ...localData,
            'user': remoteData['user'] ?? localData['user'],
            'remoteData': remoteData,
            'exportSource': 'merged',
          };
        } catch (remoteError) {
          print('Warning: Failed to export remote data: $remoteError');
          return {
            ...localData,
            'exportSource': 'local_only',
            'remoteError': remoteError.toString(),
          };
        }
      }

      return {
        ...localData,
        'exportSource': 'local_only',
      };
    } catch (error) {
      throw Exception('Failed to export user data: $error');
    }
  }

  @override
  Future<void> syncWithRemote(String userId) async {
    try {
      if (!_remoteDataSource.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      // Get local user
      final localUser = await _localDataSource.getUser(userId);
      if (localUser == null) {
        throw Exception('Local user not found');
      }

      // Get remote user
      final remoteUser = await _remoteDataSource.getUser(userId);

      if (remoteUser == null) {
        // Upload local user to remote
        await _remoteDataSource.saveUser(localUser);
      } else {
        // Compare timestamps and sync the latest
        if (localUser.lastLoginAt.isAfter(remoteUser.lastLoginAt)) {
          // Local is newer, update remote
          await _remoteDataSource.saveUser(localUser);
        } else if (remoteUser.lastLoginAt.isAfter(localUser.lastLoginAt)) {
          // Remote is newer, update local
          await _localDataSource.saveUser(remoteUser);
        }
        // If timestamps are equal, no sync needed
      }
    } catch (error) {
      throw Exception('Failed to sync with remote: $error');
    }
  }

  @override
  Stream<User?> getUserStream(String userId) {
    // Return Firebase real-time stream if connected, otherwise local stream
    if (_remoteDataSource.isAuthenticated) {
      return _remoteDataSource.getUserStream(userId);
    } else {
      // For local-only, we can't provide real-time updates
      // Return a stream that emits the current user once
      return Stream.fromFuture(getUserById(userId));
    }
  }

  @override
  Future<bool> isConnected() async {
    return await _remoteDataSource.checkConnection();
  }

  @override
  Future<List<User>> getAllUsers() async {
    try {
      // This method is typically for admin use
      if (_remoteDataSource.isAuthenticated) {
        final remoteUsers = await _remoteDataSource.getAllUsers();
        return remoteUsers.map((data) => UserModel.fromJson(data)).toList();
      } else {
        final localUsers = await _localDataSource.getAllUsers();
        return localUsers.cast<User>();
      }
    } catch (error) {
      throw Exception('Failed to get all users: $error');
    }
  }
}