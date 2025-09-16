import '../entities/user.dart';

abstract class UserRepositoryInterface {
  // User CRUD Operations
  Future<User?> getCurrentUser();
  Future<User?> getUserById(String userId);
  Future<User> createUser({
    required String name,
    required String email,
    String? avatar,
    String skillLevel = 'beginner',
  });
  Future<User> updateUser(String userId, Map<String, dynamic> updates);
  Future<void> deleteUser(String userId);

  // Authentication
  Future<User> signInAnonymously();
  Future<void> signOut();

  // Progress & Gamification
  Future<User> addXP(String userId, int xp);
  Future<User> updateStreak(String userId);
  Future<User> completeLesson(String userId, String lessonId);
  Future<User> unlockAchievement(String userId, String achievementId);

  // User Preferences
  Future<User> updateCategoryProgress(String userId, String category, int score);
  Future<User> addFavoriteCommand(String userId, String command);
  Future<User> removeFavoriteCommand(String userId, String command);
  Future<User> updateStats(String userId, Map<String, dynamic> stats);

  // Data Management
  Future<Map<String, dynamic>> exportUserData(String userId);
  Future<void> syncWithRemote(String userId);
  Stream<User?> getUserStream(String userId);

  // Utility
  Future<bool> isConnected();
  Future<List<User>> getAllUsers(); // Admin function
}