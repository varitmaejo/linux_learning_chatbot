import '../entities/command.dart';
import '../entities/user.dart';
import '../entities/progress.dart';
import '../repositories/command_repository_interface.dart';
import '../repositories/user_repository_interface.dart';
import '../repositories/progress_repository_interface.dart';

class GetLearningPathUseCase {
  final CommandRepositoryInterface _commandRepository;
  final UserRepositoryInterface _userRepository;
  final ProgressRepositoryInterface _progressRepository;

  GetLearningPathUseCase(
      this._commandRepository,
      this._userRepository,
      this._progressRepository,
      );

  /// Get personalized learning path for user
  Future<LearningPathResult> execute({
    required String userId,
    String? targetSkill,
    String? difficulty,
    int? maxItems,
  }) async {
    try {
      // Get user information
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        return LearningPathResult.failure(
          error: 'User not found',
          errorCode: 'USER_NOT_FOUND',
        );
      }

      // Get user's current progress
      final userProgress = await _progressRepository.getUserProgressSummary(userId);

      // Get user's skill levels
      final skillLevels = await _progressRepository.getSkillProgress(userId);

      // Generate learning path based on user's level and progress
      final learningPath = await _generateLearningPath(
        user: user,
        progress: userProgress,
        skillLevels: skillLevels,
        targetSkill: targetSkill,
        difficulty: difficulty,
        maxItems: maxItems ?? 20,
      );

      return LearningPathResult.success(learningPath: learningPath);
    } catch (e) {
      return LearningPathResult.failure(
        error: e.toString(),
        errorCode: 'LEARNING_PATH_ERROR',
      );
    }
  }

  /// Get learning path for specific category
  Future<LearningPathResult> getPathForCategory({
    required String userId,
    required String category,
    int? maxItems,
  }) async {
    try {
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        return LearningPathResult.failure(
          error: 'User not found',
          errorCode: 'USER_NOT_FOUND',
        );
      }

      // Get commands in category
      final categoryCommands = await _commandRepository.getCommandsByCategory(category);

      // Get user progress for this category
      final categoryProgress = await _progressRepository.getProgressByCategory(
        userId: userId,
        category: category,
      );

      // Filter out completed commands and sort by difficulty
      final availableCommands = categoryCommands.where((command) {
        return !categoryProgress.any((progress) =>
        progress.itemId == command.id && progress.isCompleted
        );
      }).toList();

      // Sort by difficulty and user level
      availableCommands.sort((a, b) => _compareDifficulty(a.difficulty, b.difficulty));

      final limitedCommands = maxItems != null
          ? availableCommands.take(maxItems).toList()
          : availableCommands;

      final learningPath = LearningPath(
        id: _generatePathId(),
        userId: userId,
        title: 'Learning Path: ${category.toUpperCase()}',
        description: 'Personalized learning path for $category commands',
        items: limitedCommands.map((command) => LearningPathItem.fromCommand(command)).toList(),
        category: category,
        difficulty: _calculateAverageDifficulty(limitedCommands),
        estimatedDuration: _calculateEstimatedDuration(limitedCommands),
        prerequisites: [],
        skills: _extractSkills(limitedCommands),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return LearningPathResult.success(learningPath: learningPath);
    } catch (e) {
      return LearningPathResult.failure(
        error: e.toString(),
        errorCode: 'CATEGORY_PATH_ERROR',
      );
    }
  }

  /// Get recommended next steps
  Future<List<LearningPathItem>> getNextSteps({
    required String userId,
    int limit = 5,
  }) async {
    try {
      final user = await _userRepository.getUserById(userId);
      if (user == null) return [];

      // Get user's current progress
      final inProgressItems = await _progressRepository.getInProgressItems(userId: userId);

      // Get recommended commands
      final recommendedCommands = await _commandRepository.getRecommendedCommands(
        userId: userId,
        limit: limit,
      );

      return recommendedCommands
          .map((command) => LearningPathItem.fromCommand(command))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<LearningPath> _generateLearningPath({
    required User user,
    required UserProgressSummary progress,
    required Map<String, double> skillLevels,
    String? targetSkill,
    String? difficulty,
    required int maxItems,
  }) async {
    List<Command> pathCommands = [];

    if (targetSkill != null) {
      // Get commands for specific skill
      pathCommands = await _commandRepository.getCommandLearningPath(
        userId: user.id,
        targetSkill: targetSkill,
      );
    } else {
      // Get recommended commands based on user level
      final recommendedCommands = await _commandRepository.getRecommendedCommands(
        userId: user.id,
        limit: maxItems,
      );
      pathCommands = recommendedCommands;
    }

    // Filter by difficulty if specified
    if (difficulty != null) {
      pathCommands = pathCommands
          .where((command) => command.difficulty == difficulty)
          .toList();
    }

    // Limit results
    if (pathCommands.length > maxItems) {
      pathCommands = pathCommands.take(maxItems).toList();
    }

    return LearningPath(
      id: _generatePathId(),
      userId: user.id,
      title: targetSkill != null
          ? 'Learning Path: ${targetSkill.toUpperCase()}'
          : 'Personalized Learning Path',
      description: _generatePathDescription(user, targetSkill),
      items: pathCommands.map((command) => LearningPathItem.fromCommand(command)).toList(),
      category: targetSkill ?? 'mixed',
      difficulty: difficulty ?? _getDifficultyForUserLevel(user.level),
      estimatedDuration: _calculateEstimatedDuration(pathCommands),
      prerequisites: [],
      skills: _extractSkills(pathCommands),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  String _generatePathDescription(User user, String? targetSkill) {
    if (targetSkill != null) {
      return 'A curated learning path to master $targetSkill commands, tailored for your ${user.level.name} level.';
    }
    return 'A personalized learning journey based on your current progress and skill level.';
  }

  String _getDifficultyForUserLevel(UserLevel level) {
    switch (level) {
      case UserLevel.beginner:
        return 'easy';
      case UserLevel.intermediate:
        return 'medium';
      case UserLevel.advanced:
      case UserLevel.expert:
        return 'hard';
    }
  }

  int _compareDifficulty(String a, String b) {
    const difficultyOrder = {'easy': 0, 'medium': 1, 'hard': 2};
    return (difficultyOrder[a] ?? 0).compareTo(difficultyOrder[b] ?? 0);
  }

  String _calculateAverageDifficulty(List<Command> commands) {
    if (commands.isEmpty) return 'easy';

    const difficultyScores = {'easy': 1, 'medium': 2, 'hard': 3};
    final totalScore = commands.fold<int>(0, (sum, command) {
      return sum + (difficultyScores[command.difficulty] ?? 1);
    });

    final averageScore = totalScore / commands.length;

    if (averageScore <= 1.5) return 'easy';
    if (averageScore <= 2.5) return 'medium';
    return 'hard';
  }

  Duration _calculateEstimatedDuration(List<Command> commands) {
    // Estimate 10 minutes per command on average
    const averageMinutesPerCommand = 10;
    return Duration(minutes: commands.length * averageMinutesPerCommand);
  }

  List<String> _extractSkills(List<Command> commands) {
    final skills = <String>{};
    for (final command in commands) {
      skills.addAll(command.tags);
      skills.add(command.category);
    }
    return skills.toList();
  }

  String _generatePathId() {
    return 'path_${DateTime.now().millisecondsSinceEpoch}';
  }
}

class LearningPath {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<LearningPathItem> items;
  final String category;
  final String difficulty;
  final Duration estimatedDuration;
  final List<String> prerequisites;
  final List<String> skills;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LearningPath({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.items,
    required this.category,
    required this.difficulty,
    required this.estimatedDuration,
    required this.prerequisites,
    required this.skills,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalItems => items.length;
  int get completedItems => items.where((item) => item.isCompleted).length;
  double get completionPercentage => totalItems > 0 ? (completedItems / totalItems) * 100 : 0.0;
  bool get isCompleted => completedItems == totalItems && totalItems > 0;

  @override
  String toString() {
    return 'LearningPath(id: $id, title: $title, items: ${items.length}, completion: ${completionPercentage.toStringAsFixed(1)}%)';
  }
}

class LearningPathItem {
  final String id;
  final String title;
  final String description;
  final String type; // 'command', 'lesson', 'quiz', 'practice'
  final String difficulty;
  final Duration estimatedTime;
  final List<String> skills;
  final Map<String, dynamic> metadata;
  final bool isCompleted;
  final bool isLocked;
  final List<String> prerequisites;

  const LearningPathItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.estimatedTime,
    required this.skills,
    required this.metadata,
    required this.isCompleted,
    required this.isLocked,
    required this.prerequisites,
  });

  factory LearningPathItem.fromCommand(Command command) {
    return LearningPathItem(
      id: command.id,
      title: command.name,
      description: command.description,
      type: 'command',
      difficulty: command.difficulty,
      estimatedTime: const Duration(minutes: 10),
      skills: command.tags,
      metadata: {
        'syntax': command.syntax,
        'examples': command.examples,
        'category': command.category,
      },
      isCompleted: false,
      isLocked: false,
      prerequisites: [],
    );
  }

  @override
  String toString() {
    return 'LearningPathItem(id: $id, title: $title, type: $type, difficulty: $difficulty, isCompleted: $isCompleted)';
  }
}

class LearningPathResult {
  final bool isSuccess;
  final LearningPath? learningPath;
  final String? error;
  final String? errorCode;

  const LearningPathResult._({
    required this.isSuccess,
    this.learningPath,
    this.error,
    this.errorCode,
  });

  factory LearningPathResult.success({required LearningPath learningPath}) {
    return LearningPathResult._(
      isSuccess: true,
      learningPath: learningPath,
    );
  }

  factory LearningPathResult.failure({
    required String error,
    required String errorCode,
  }) {
    return LearningPathResult._(
      isSuccess: false,
      error: error,
      errorCode: errorCode,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'LearningPathResult.success(learningPath: ${learningPath?.title})';
    } else {
      return 'LearningPathResult.failure(error: $error, errorCode: $errorCode)';
    }
  }
}