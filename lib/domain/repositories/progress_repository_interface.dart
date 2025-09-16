import '../entities/progress.dart';
import '../../data/models/achievement.dart';

abstract class ProgressRepositoryInterface {
  // Progress Management
  Future<Progress?> getUserProgress(String userId, String category);
  Future<List<Progress>> getAllUserProgress(String userId);
  Future<Progress> createProgress({
    required String userId,
    required String category,
    required int totalLessons,
  });
  Future<Progress> updateProgress(
      String userId,
      String category,
      Map<String, dynamic> updates,
      );

  // Learning Activities
  Future<Progress> completeLesson(String userId, String category, String lessonId);
  Future<Progress> addXP(String userId, String category, int xp);
  Future<Progress> updateStreak(String userId, String category);
  Future<Progress> recordStudyTime(String userId, String category, Duration studyTime);

  // Command Tracking
  Future<Progress> addMasteredCommand(String userId, String category, String command);
  Future<Progress> addWeakCommand(String userId, String category, String command);
  Future<Progress> updateCategoryScore(String userId, String category, String scoreCategory, int score);

  // Assessment & Quizzes
  Future<Progress> recordQuizResult(
      String userId,
      String category, {
        required int score,
        required int totalQuestions,
        required bool passed,
        Map<String, dynamic>? quizMetadata,
      });

  // Achievements
  Future<List<Achievement>> getUserAchievements(String userId);
  Future<Achievement> unlockAchievement(String userId, String achievementId);

  // Analytics & Reporting
  Future<Map<String, dynamic>> getOverallProgress(String userId);
  Future<Map<String, dynamic>> getProgressAnalytics(String userId);

  // Data Management
  Future<void> syncWithRemote(String userId);
  Stream<List<Progress>> getProgressStream(String userId);
}