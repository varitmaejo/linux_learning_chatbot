import '../entities/progress.dart';
import '../entities/user.dart';
import '../repositories/progress_repository_interface.dart';
import '../repositories/user_repository_interface.dart';

class UpdateProgressUseCase {
  final ProgressRepositoryInterface _progressRepository;
  final UserRepositoryInterface _userRepository;

  UpdateProgressUseCase(
      this._progressRepository,
      this._userRepository,
      );

  /// Update progress for a specific item
  Future<UpdateProgressResult> execute({
    required String userId,
    required String itemId,
    required ProgressType type,
    int? currentStep,
    double? completionPercentage,
    int? score,
    ProgressStatus? status,
    Duration? additionalTimeSpent,
    List<String>? newSkillsLearned,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Validate inputs
      final validationResult = _validateInputs(
        userId: userId,
        itemId: itemId,
        completionPercentage: completionPercentage,
        score: score,
      );

      if (!validationResult.isValid) {
        return UpdateProgressResult.failure(
          error: validationResult.error!,
          errorCode: 'VALIDATION_ERROR',
        );
      }

      // Get existing progress
      final existingProgress = await _progressRepository.getProgressById(
        userId: userId,
        itemId: itemId,
        type: type,
      );

      Progress updatedProgress;

      if (existingProgress == null) {
        // Create new progress if it doesn't exist
        updatedProgress = await _progressRepository.startProgress(
          userId: userId,
          itemId: itemId,
          type: type,
          totalSteps: currentStep != null ? currentStep + 1 : 1,
          maxScore: score ?? 100,
          difficulty: 1.0,
        );
      } else {
        // Update existing progress
        updatedProgress = await _progressRepository.updateProgress(
          userId: userId,
          itemId: itemId,
          type: type,
          currentStep: currentStep,
          completionPercentage: completionPercentage,
          score: score,
          status: status,
          timeSpent: additionalTimeSpent,
          skillsLearned: newSkillsLearned,
          data: additionalData,
        );
      }

      // Check for completion and level up
      final completionResult = await _handleProgressCompletion(
        progress: updatedProgress,
        userId: userId,
      );

      // Update learning streak if item is completed
      if (updatedProgress.isCompleted) {
        await _progressRepository.updateLearningStreak(
          userId: userId,
          date: DateTime.now(),
        );
      }

      return UpdateProgressResult.success(
        progress: updatedProgress,
        levelUpResult: completionResult.levelUpResult,
        newAchievements: completionResult.newAchievements,
      );
    } catch (e) {
      return UpdateProgressResult.failure(
        error: e.toString(),
        errorCode: 'UPDATE_PROGRESS_ERROR',
      );
    }
  }

  /// Complete a progress item
  Future<UpdateProgressResult> completeItem({
    required String userId,
    required String itemId,
    required ProgressType type,
    int? finalScore,
    List<String>? skillsLearned,
  }) async {
    try {
      final completedProgress = await _progressRepository.completeProgress(
        userId: userId,
        itemId: itemId,
        type: type,
        finalScore: finalScore,
        skillsLearned: skillsLearned,
      );

      // Handle completion rewards and level up
      final completionResult = await _handleProgressCompletion(
        progress: completedProgress,
        userId: userId,
      );

      // Update learning streak
      await _progressRepository.updateLearningStreak(
        userId: userId,
        date: DateTime.now(),
      );

      return UpdateProgressResult.success(
        progress: completedProgress,
        levelUpResult: completionResult.levelUpResult,
        newAchievements: completionResult.newAchievements,
      );
    } catch (e) {
      return UpdateProgressResult.failure(
        error: e.toString(),
        errorCode: 'COMPLETE_ITEM_ERROR',
      );
    }
  }

  /// Update multiple progress items
  Future<BatchUpdateResult> updateMultipleProgress({
    required String userId,
    required List<ProgressUpdateRequest> updates,
  }) async {
    final results = <String, UpdateProgressResult>{};
    final errors = <String, String>{};

    for (final update in updates) {
      try {
        final result = await execute(
          userId: userId,
          itemId: update.itemId,
          type: update.type,
          currentStep: update.currentStep,
          completionPercentage: update.completionPercentage,
          score: update.score,
          status: update.status,
          additionalTimeSpent: update.additionalTimeSpent,
          newSkillsLearned: update.newSkillsLearned,
          additionalData: update.additionalData,
        );
        results[update.itemId] = result;
      } catch (e) {
        errors[update.itemId] = e.toString();
      }
    }

    return BatchUpdateResult(
      results: results,
      errors: errors,
      totalUpdates: updates.length,
      successfulUpdates: results.length,
      failedUpdates: errors.length,
    );
  }

  /// Reset progress for an item
  Future<void> resetProgress({
    required String userId,
    required String itemId,
    required ProgressType type,
  }) async {
    await _progressRepository.resetProgress(
      userId: userId,
      itemId: itemId,
      type: type,
    );
  }

  /// Add milestone to progress
  Future<Progress> addMilestone({
    required String userId,
    required String itemId,
    required ProgressType type,
    required ProgressMilestone milestone,
  }) async {
    final progress = await _progressRepository.getProgressById(
      userId: userId,
      itemId: itemId,
      type: type,
    );

    if (progress == null) {
      throw Exception('Progress not found');
    }

    return await _progressRepository.addMilestone(
      progressId: progress.id,
      milestone: milestone,
    );
  }

  /// Complete milestone
  Future<Progress> completeMilestone({
    required String userId,
    required String itemId,
    required ProgressType type,
    required String milestoneId,
  }) async {
    final progress = await _progressRepository.getProgressById(
      userId: userId,
      itemId: itemId,
      type: type,
    );

    if (progress == null) {
      throw Exception('Progress not found');
    }

    return await _progressRepository.completeMilestone(
      progressId: progress.id,
      milestoneId: milestoneId,
    );
  }

  Future<CompletionResult> _handleProgressCompletion({
    required Progress progress,
    required String userId,
  }) async {
    LevelUpResult? levelUpResult;
    final newAchievements = <String>[];

    if (progress.isCompleted) {
      // Calculate experience reward
      final experienceReward = _calculateExperienceReward(progress);

      // Update user experience
      final user = await _userRepository.updateUserExperience(
        userId: userId,
        experienceGained: experienceReward,
      );

      // Check for level up
      levelUpResult = await _checkForLevelUp(user);

      // Check for new achievements (simplified)
      if (progress.score >= progress.maxScore * 0.9) {
        // Perfect score achievement logic would go here
      }

      // Update user stats
      await _userRepository.updateUserStats(
        userId: userId,
        lessonsCompleted: progress.type == ProgressType.lesson ? 1 : null,
        quizzesCompleted: progress.type == ProgressType.quiz ? 1 : null,
        commandsExecuted: progress.type == ProgressType.command ? 1 : null,
        newScore: progress.score.toDouble(),
        lastActivityDate: DateTime.now(),
      );
    }

    return CompletionResult(
      levelUpResult: levelUpResult,
      newAchievements: newAchievements,
    );
  }

  int _calculateExperienceReward(Progress progress) {
    int baseReward = 10;

    // Bonus for completion
    if (progress.isCompleted) {
      baseReward += 20;
    }

    // Bonus for high scores
    final scorePercentage = progress.scorePercentage;
    if (scorePercentage >= 90) {
      baseReward += 15;
    } else if (scorePercentage >= 75) {
      baseReward += 10;
    }

    // Bonus based on difficulty
    baseReward = (baseReward * progress.difficulty).round();

    return baseReward;
  }

  Future<LevelUpResult?> _checkForLevelUp(User user) async {
    UserLevel? newLevel;

    switch (user.level) {
      case UserLevel.beginner:
        if (user.experience >= 1000) {
          newLevel = UserLevel.intermediate;
        }
        break;
      case UserLevel.intermediate:
        if (user.experience >= 2500) {
          newLevel = UserLevel.advanced;
        }
        break;
      case UserLevel.advanced:
        if (user.experience >= 5000) {
          newLevel = UserLevel.expert;
        }
        break;
      case UserLevel.expert:
      // Already at max level
        break;
    }

    if (newLevel != null) {
      final updatedUser = await _userRepository.updateUserLevel(
        userId: user.id,
        newLevel: newLevel,
      );

      return LevelUpResult(
        oldLevel: user.level,
        newLevel: newLevel,
        experienceRequired: user.experience,
      );
    }

    return null;
  }

  ValidationResult _validateInputs({
    required String userId,
    required String itemId,
    double? completionPercentage,
    int? score,
  }) {
    if (userId.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'User ID cannot be empty',
      );
    }

    if (itemId.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Item ID cannot be empty',
      );
    }

    if (completionPercentage != null) {
      if (completionPercentage < 0 || completionPercentage > 100) {
        return ValidationResult(
          isValid: false,
          error: 'Completion percentage must be between 0 and 100',
        );
      }
    }

    if (score != null && score < 0) {
      return ValidationResult(
        isValid: false,
        error: 'Score cannot be negative',
      );
    }

    return ValidationResult(isValid: true);
  }
}

class ProgressUpdateRequest {
  final String itemId;
  final ProgressType type;
  final int? currentStep;
  final double? completionPercentage;
  final int? score;
  final ProgressStatus? status;
  final Duration? additionalTimeSpent;
  final List<String>? newSkillsLearned;
  final Map<String, dynamic>? additionalData;

  const ProgressUpdateRequest({
    required this.itemId,
    required this.type,
    this.currentStep,
    this.completionPercentage,
    this.score,
    this.status,
    this.additionalTimeSpent,
    this.newSkillsLearned,
    this.additionalData,
  });
}

class UpdateProgressResult {
  final bool isSuccess;
  final Progress? progress;
  final LevelUpResult? levelUpResult;
  final List<String>? newAchievements;
  final String? error;
  final String? errorCode;

  const UpdateProgressResult._({
    required this.isSuccess,
    this.progress,
    this.levelUpResult,
    this.newAchievements,
    this.error,
    this.errorCode,
  });

  factory UpdateProgressResult.success({
    required Progress progress,
    LevelUpResult? levelUpResult,
    List<String>? newAchievements,
  }) {
    return UpdateProgressResult._(
      isSuccess: true,
      progress: progress,
      levelUpResult: levelUpResult,
      newAchievements: newAchievements,
    );
  }

  factory UpdateProgressResult.failure({
    required String error,
    required String errorCode,
  }) {
    return UpdateProgressResult._(
      isSuccess: false,
      error: error,
      errorCode: errorCode,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'UpdateProgressResult.success(progress: ${progress?.id}, levelUp: ${levelUpResult != null})';
    } else {
      return 'UpdateProgressResult.failure(error: $error, errorCode: $errorCode)';
    }
  }
}

class BatchUpdateResult {
  final Map<String, UpdateProgressResult> results;
  final Map<String, String> errors;
  final int totalUpdates;
  final int successfulUpdates;
  final int failedUpdates;

  const BatchUpdateResult({
    required this.results,
    required this.errors,
    required this.totalUpdates,
    required this.successfulUpdates,
    required this.failedUpdates,
  });

  double get successRate => totalUpdates > 0 ? (successfulUpdates / totalUpdates) * 100 : 0.0;

  @override
  String toString() {
    return 'BatchUpdateResult(total: $totalUpdates, successful: $successfulUpdates, failed: $failedUpdates, successRate: ${successRate.toStringAsFixed(1)}%)';
  }
}

class CompletionResult {
  final LevelUpResult? levelUpResult;
  final List<String> newAchievements;

  const CompletionResult({
    this.levelUpResult,
    required this.newAchievements,
  });
}

class LevelUpResult {
  final UserLevel oldLevel;
  final UserLevel newLevel;
  final int experienceRequired;

  const LevelUpResult({
    required this.oldLevel,
    required this.newLevel,
    required this.experienceRequired,
  });

  @override
  String toString() {
    return 'LevelUpResult(from: ${oldLevel.name}, to: ${newLevel.name}, experience: $experienceRequired)';
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult({
    required this.isValid,
    this.error,
  });

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, error: $error)';
  }
}