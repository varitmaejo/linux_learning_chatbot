import 'dart:convert';
import 'package:flutter/services.dart';

import '../../domain/entities/command.dart';
import '../../domain/repositories/command_repository_interface.dart';
import '../models/linux_command.dart';
import '../datasources/local/hive_datasource.dart';
import '../datasources/local/shared_prefs_datasource.dart';
import '../datasources/remote/firebase_datasource.dart';

class CommandRepository implements CommandRepositoryInterface {
  final HiveDatasource _localDataSource;
  final SharedPrefsDatasource _prefsDataSource;
  final FirebaseDatasource _remoteDataSource;

  List<LinuxCommand>? _cachedCommands;
  DateTime? _cacheTime;
  static const Duration _cacheValidDuration = Duration(hours: 24);

  CommandRepository({
    required HiveDatasource localDataSource,
    required SharedPrefsDatasource prefsDataSource,
    required FirebaseDatasource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _prefsDataSource = prefsDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<List<Command>> getAllCommands() async {
    try {
      // Check if we have valid cached commands
      if (_isCacheValid()) {
        return _cachedCommands!.cast<Command>();
      }

      // Try to load from assets first (bundled data)
      List<LinuxCommand> commands = await _loadCommandsFromAssets();

      // Try to get updated commands from remote
      if (_remoteDataSource.isAuthenticated) {
        try {
          final remoteCommands = await _remoteDataSource.getLinuxCommands();
          if (remoteCommands.isNotEmpty) {
            commands = remoteCommands
                .map((data) => LinuxCommand.fromJson(data))
                .toList();
          }
        } catch (remoteError) {
          print('Warning: Failed to load commands from remote: $remoteError');
        }
      }

      // Cache the commands
      _cachedCommands = commands;
      _cacheTime = DateTime.now();

      // Save to local preferences for offline access
      await _prefsDataSource.setCacheExpiryTime(
        'linux_commands',
        DateTime.now().add(_cacheValidDuration),
      );

      return commands.cast<Command>();
    } catch (error) {
      throw Exception('Failed to get all commands: $error');
    }
  }

  @override
  Future<List<Command>> getCommandsByCategory(String category) async {
    try {
      final allCommands = await getAllCommands();
      return allCommands
          .where((command) => command.category.toLowerCase() == category.toLowerCase())
          .toList();
    } catch (error) {
      throw Exception('Failed to get commands by category: $error');
    }
  }

  @override
  Future<List<Command>> getCommandsByDifficulty(String difficulty) async {
    try {
      final allCommands = await getAllCommands();
      return allCommands
          .where((command) => command.difficulty.toLowerCase() == difficulty.toLowerCase())
          .toList();
    } catch (error) {
      throw Exception('Failed to get commands by difficulty: $error');
    }
  }

  @override
  Future<Command?> getCommandById(String commandId) async {
    try {
      final allCommands = await getAllCommands();
      final commands = allCommands
          .where((command) => command.id == commandId)
          .toList();

      return commands.isNotEmpty ? commands.first : null;
    } catch (error) {
      throw Exception('Failed to get command by ID: $error');
    }
  }

  @override
  Future<Command?> getCommandByName(String name) async {
    try {
      final allCommands = await getAllCommands();
      final commands = allCommands
          .where((command) => command.name.toLowerCase() == name.toLowerCase())
          .toList();

      return commands.isNotEmpty ? commands.first : null;
    } catch (error) {
      throw Exception('Failed to get command by name: $error');
    }
  }

  @override
  Future<List<Command>> searchCommands(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final allCommands = await getAllCommands();
      final lowercaseQuery = query.toLowerCase();

      return allCommands.where((command) {
        return command.name.toLowerCase().contains(lowercaseQuery) ||
            command.description.toLowerCase().contains(lowercaseQuery) ||
            command.usage.toLowerCase().contains(lowercaseQuery) ||
            command.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
    } catch (error) {
      throw Exception('Failed to search commands: $error');
    }
  }

  @override
  Future<List<Command>> getCommandsByTags(List<String> tags) async {
    try {
      if (tags.isEmpty) return [];

      final allCommands = await getAllCommands();
      final lowercaseTags = tags.map((tag) => tag.toLowerCase()).toSet();

      return allCommands.where((command) {
        final commandTags = command.tags.map((tag) => tag.toLowerCase()).toSet();
        return commandTags.intersection(lowercaseTags).isNotEmpty;
      }).toList();
    } catch (error) {
      throw Exception('Failed to get commands by tags: $error');
    }
  }

  @override
  Future<List<Command>> getPopularCommands({int limit = 20}) async {
    try {
      final allCommands = await getAllCommands();

      // Sort by popularity (usage count in metadata)
      final sortedCommands = List<Command>.from(allCommands)
        ..sort((a, b) {
          final aPopularity = (a.metadata['popularityScore'] as num?) ?? 0;
          final bPopularity = (b.metadata['popularityScore'] as num?) ?? 0;
          return bPopularity.compareTo(aPopularity);
        });

      return sortedCommands.take(limit).toList();
    } catch (error) {
      throw Exception('Failed to get popular commands: $error');
    }
  }

  @override
  Future<List<Command>> getRecentCommands(String userId, {int limit = 10}) async {
    try {
      // Get recent command usage from user preferences or local storage
      final recentCommandIds = _prefsDataSource.getUserPreference<List<String>>(
        'recent_commands_$userId',
        defaultValue: [],
      ) ?? [];

      if (recentCommandIds.isEmpty) return [];

      final allCommands = await getAllCommands();
      final recentCommands = <Command>[];

      // Get commands in order of recent usage
      for (final commandId in recentCommandIds.take(limit)) {
        final command = allCommands
            .where((c) => c.id == commandId)
            .firstOrNull;
        if (command != null) {
          recentCommands.add(command);
        }
      }

      return recentCommands;
    } catch (error) {
      throw Exception('Failed to get recent commands: $error');
    }
  }

  @override
  Future<List<Command>> getFavoriteCommands(String userId) async {
    try {
      final favoriteIds = _prefsDataSource.getUserPreference<List<String>>(
        'favorite_commands_$userId',
        defaultValue: [],
      ) ?? [];

      if (favoriteIds.isEmpty) return [];

      final allCommands = await getAllCommands();
      return allCommands
          .where((command) => favoriteIds.contains(command.id))
          .toList();
    } catch (error) {
      throw Exception('Failed to get favorite commands: $error');
    }
  }

  @override
  Future<void> addToFavorites(String userId, String commandId) async {
    try {
      final currentFavorites = _prefsDataSource.getUserPreference<List<String>>(
        'favorite_commands_$userId',
        defaultValue: [],
      ) ?? [];

      if (!currentFavorites.contains(commandId)) {
        final updatedFavorites = List<String>.from(currentFavorites)
          ..add(commandId);

        await _prefsDataSource.setUserPreference(
          'favorite_commands_$userId',
          updatedFavorites,
        );
      }
    } catch (error) {
      throw Exception('Failed to add to favorites: $error');
    }
  }

  @override
  Future<void> removeFromFavorites(String userId, String commandId) async {
    try {
      final currentFavorites = _prefsDataSource.getUserPreference<List<String>>(
        'favorite_commands_$userId',
        defaultValue: [],
      ) ?? [];

      final updatedFavorites = List<String>.from(currentFavorites)
        ..remove(commandId);

      await _prefsDataSource.setUserPreference(
        'favorite_commands_$userId',
        updatedFavorites,
      );
    } catch (error) {
      throw Exception('Failed to remove from favorites: $error');
    }
  }

  @override
  Future<void> recordCommandUsage(String userId, String commandId) async {
    try {
      // Update recent commands
      final recentCommands = _prefsDataSource.getUserPreference<List<String>>(
        'recent_commands_$userId',
        defaultValue: [],
      ) ?? [];

      final updatedRecent = List<String>.from(recentCommands)
        ..remove(commandId) // Remove if exists
        ..insert(0, commandId); // Add to beginning

      // Keep only last 50 recent commands
      final trimmedRecent = updatedRecent.take(50).toList();

      await _prefsDataSource.setUserPreference(
        'recent_commands_$userId',
        trimmedRecent,
      );

      // Update usage statistics
      final usageKey = 'command_usage_${userId}_$commandId';
      final currentUsage = _prefsDataSource.getUserPreference<int>(
        usageKey,
        defaultValue: 0,
      ) ?? 0;

      await _prefsDataSource.setUserPreference(
        usageKey,
        currentUsage + 1,
      );

      // Update last used timestamp
      await _prefsDataSource.setUserPreference(
        'command_last_used_${userId}_$commandId',
        DateTime.now().toIso8601String(),
      );

    } catch (error) {
      throw Exception('Failed to record command usage: $error');
    }
  }

  @override
  Future<List<Command>> getCommandsForLearningPath(String pathId) async {
    try {
      // Load learning paths from assets
      final learningPathsJson = await rootBundle.loadString('assets/data/learning_paths.json');
      final learningPaths = jsonDecode(learningPathsJson) as List;

      // Find the specific path
      final path = learningPaths
          .where((p) => p['id'] == pathId)
          .firstOrNull;

      if (path == null) {
        throw Exception('Learning path not found: $pathId');
      }

      // Get command IDs for this path
      final commandIds = (path['commandIds'] as List?)?.cast<String>() ?? [];

      if (commandIds.isEmpty) return [];

      // Get all commands and filter by IDs
      final allCommands = await getAllCommands();
      return allCommands
          .where((command) => commandIds.contains(command.id))
          .toList();

    } catch (error) {
      throw Exception('Failed to get commands for learning path: $error');
    }
  }

  @override
  Future<List<Command>> getRecommendedCommands(
      String userId, {
        String? category,
        String? difficulty,
        int limit = 10,
      }) async {
    try {
      // Get user's learning history
      final recentCommands = await getRecentCommands(userId, limit: 20);
      final favoriteCommands = await getFavoriteCommands(userId);

      // Get user's skill level and preferences
      final userLevel = _prefsDataSource.getPreferredDifficulty();
      final preferredCategories = _prefsDataSource.getPreferredCategories();

      final allCommands = await getAllCommands();
      List<Command> candidates = List.from(allCommands);

      // Filter by category if specified
      if (category != null) {
        candidates = candidates
            .where((cmd) => cmd.category.toLowerCase() == category.toLowerCase())
            .toList();
      }

      // Filter by difficulty if specified
      if (difficulty != null) {
        candidates = candidates
            .where((cmd) => cmd.difficulty.toLowerCase() == difficulty.toLowerCase())
            .toList();
      } else {
        // Use user's preferred difficulty
        candidates = candidates
            .where((cmd) => cmd.difficulty.toLowerCase() == userLevel.toLowerCase())
            .toList();
      }

      // Remove already known commands (recent + favorites)
      final knownCommandIds = {
        ...recentCommands.map((c) => c.id),
        ...favoriteCommands.map((c) => c.id),
      };

      candidates = candidates
          .where((cmd) => !knownCommandIds.contains(cmd.id))
          .toList();

      // Score commands based on relevance
      final scoredCommands = candidates.map((command) {
        double score = 0;

        // Boost score for preferred categories
        if (preferredCategories.contains(command.category)) {
          score += 2.0;
        }

        // Boost score for popular commands
        final popularity = (command.metadata['popularityScore'] as num?) ?? 0;
        score += popularity * 0.1;

        // Boost score for commands with good tags
        if (command.tags.any((tag) => ['basic', 'essential', 'important'].contains(tag.toLowerCase()))) {
          score += 1.0;
        }

        // Reduce score for very advanced commands if user is beginner
        if (userLevel == 'beginner' && command.difficulty == 'expert') {
          score -= 1.0;
        }

        return {'command': command, 'score': score};
      }).toList();

      // Sort by score and return top results
      scoredCommands.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      return scoredCommands
          .take(limit)
          .map((item) => item['command'] as Command)
          .toList();

    } catch (error) {
      throw Exception('Failed to get recommended commands: $error');
    }
  }

  @override
  Future<Map<String, int>> getCommandUsageStats(String userId) async {
    try {
      final stats = <String, int>{};

      // Get all commands to iterate through
      final allCommands = await getAllCommands();

      for (final command in allCommands) {
        final usageKey = 'command_usage_${userId}_${command.id}';
        final usage = _prefsDataSource.getUserPreference<int>(
          usageKey,
          defaultValue: 0,
        ) ?? 0;

        if (usage > 0) {
          stats[command.name] = usage;
        }
      }

      return stats;
    } catch (error) {
      throw Exception('Failed to get command usage stats: $error');
    }
  }

  @override
  Future<List<String>> getAvailableCategories() async {
    try {
      final allCommands = await getAllCommands();
      final categories = allCommands
          .map((command) => command.category)
          .toSet()
          .toList();

      categories.sort();
      return categories;
    } catch (error) {
      throw Exception('Failed to get available categories: $error');
    }
  }

  @override
  Future<List<String>> getAvailableTags() async {
    try {
      final allCommands = await getAllCommands();
      final tags = <String>{};

      for (final command in allCommands) {
        tags.addAll(command.tags);
      }

      final sortedTags = tags.toList()..sort();
      return sortedTags;
    } catch (error) {
      throw Exception('Failed to get available tags: $error');
    }
  }

  @override
  Future<void> syncWithRemote() async {
    try {
      if (!_remoteDataSource.isAuthenticated) {
        return; // Skip sync if not authenticated
      }

      // Get latest commands from remote
      final remoteCommands = await _remoteDataSource.getLinuxCommands();

      if (remoteCommands.isNotEmpty) {
        // Convert to LinuxCommand objects
        _cachedCommands = remoteCommands
            .map((data) => LinuxCommand.fromJson(data))
            .toList();
        _cacheTime = DateTime.now();

        // Update cache expiry
        await _prefsDataSource.setCacheExpiryTime(
          'linux_commands',
          DateTime.now().add(_cacheValidDuration),
        );
      }

    } catch (error) {
      print('Warning: Failed to sync commands with remote: $error');
    }
  }

  // Private helper methods
  Future<List<LinuxCommand>> _loadCommandsFromAssets() async {
    try {
      final commandsJson = await rootBundle.loadString('assets/data/linux_commands.json');
      final commandsList = jsonDecode(commandsJson) as List;

      return commandsList
          .map((json) => LinuxCommand.fromJson(json))
          .toList();
    } catch (error) {
      // Return empty list if assets file doesn't exist
      print('Warning: Could not load commands from assets: $error');
      return [];
    }
  }

  bool _isCacheValid() {
    if (_cachedCommands == null || _cacheTime == null) {
      return false;
    }

    final now = DateTime.now();
    return now.difference(_cacheTime!).compareTo(_cacheValidDuration) < 0;
  }

  @override
  Future<void> clearCache() async {
    try {
      _cachedCommands = null;
      _cacheTime = null;

      await _prefsDataSource.removeUserPreference('linux_commands_cache');
    } catch (error) {
      throw Exception('Failed to clear cache: $error');
    }
  }

  @override
  Future<bool> isOfflineDataAvailable() async {
    try {
      // Check if we have cached commands or can load from assets
      if (_cachedCommands != null && _cachedCommands!.isNotEmpty) {
        return true;
      }

      // Try to load from assets
      try {
        final commands = await _loadCommandsFromAssets();
        return commands.isNotEmpty;
      } catch (error) {
        return false;
      }
    } catch (error) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getCommandStatistics() async {
    try {
      final allCommands = await getAllCommands();

      if (allCommands.isEmpty) {
        return {
          'totalCommands': 0,
          'categoriesCount': 0,
          'difficultiesCount': 0,
          'tagsCount': 0,
          'categoriesBreakdown': <String, int>{},
          'difficultiesBreakdown': <String, int>{},
        };
      }

      // Count by category
      final categoryCount = <String, int>{};
      for (final command in allCommands) {
        categoryCount[command.category] = (categoryCount[command.category] ?? 0) + 1;
      }

      // Count by difficulty
      final difficultyCount = <String, int>{};
      for (final command in allCommands) {
        difficultyCount[command.difficulty] = (difficultyCount[command.difficulty] ?? 0) + 1;
      }

      // Count unique tags
      final allTags = <String>{};
      for (final command in allCommands) {
        allTags.addAll(command.tags);
      }

      return {
        'totalCommands': allCommands.length,
        'categoriesCount': categoryCount.length,
        'difficultiesCount': difficultyCount.length,
        'tagsCount': allTags.length,
        'categoriesBreakdown': categoryCount,
        'difficultiesBreakdown': difficultyCount,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (error) {
      throw Exception('Failed to get command statistics: $error');
    }
  }
}