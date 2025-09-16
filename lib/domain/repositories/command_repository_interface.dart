import '../entities/command.dart';

abstract class CommandRepositoryInterface {
  // Command Retrieval
  Future<List<Command>> getAllCommands();
  Future<List<Command>> getCommandsByCategory(String category);
  Future<List<Command>> getCommandsByDifficulty(String difficulty);
  Future<Command?> getCommandById(String commandId);
  Future<Command?> getCommandByName(String name);

  // Search & Filter
  Future<List<Command>> searchCommands(String query);
  Future<List<Command>> getCommandsByTags(List<String> tags);
  Future<List<Command>> getPopularCommands({int limit = 20});

  // User-specific Data
  Future<List<Command>> getRecentCommands(String userId, {int limit = 10});
  Future<List<Command>> getFavoriteCommands(String userId);
  Future<void> addToFavorites(String userId, String commandId);
  Future<void> removeFromFavorites(String userId, String commandId);
  Future<void> recordCommandUsage(String userId, String commandId);

  // Learning & Recommendations
  Future<List<Command>> getCommandsForLearningPath(String pathId);
  Future<List<Command>> getRecommendedCommands(
      String userId, {
        String? category,
        String? difficulty,
        int limit = 10,
      });

  // Analytics
  Future<Map<String, int>> getCommandUsageStats(String userId);
  Future<Map<String, dynamic>> getCommandStatistics();

  // Metadata
  Future<List<String>> getAvailableCategories();
  Future<List<String>> getAvailableTags();

  // Data Management
  Future<void> syncWithRemote();
  Future<void> clearCache();
  Future<bool> isOfflineDataAvailable();
}