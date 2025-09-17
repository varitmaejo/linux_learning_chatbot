enum ProgressType {
  command,
  lesson,
  quiz,
  challenge,
  achievement,
}

enum ProgressStatus {
  notStarted,
  inProgress,
  completed,
  mastered,
  failed,
}

class Progress {
  final String id;
  final String userId;
  final String itemId;
  final ProgressType type;
  final ProgressStatus status;
  final double completionPercentage;
  final int currentStep;
  final int totalSteps;
  final int score;
  final int maxScore;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime lastUpdated;
  final Duration timeSpent;
  final int attempts;
  final Map<String, dynamic> data;
  final List<ProgressMilestone> milestones;
  final double difficulty;
  final List<String> skillsLearned;

  const Progress({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.type,
    required this.status,
    required this.completionPercentage,
    required this.currentStep,
    required this.totalSteps,
    required this.score,
    required this.maxScore,
    required this.startedAt,
    this.completedAt,
    required this.lastUpdated,
    required this.timeSpent,
    required this.attempts,
    required this.data,
    required this.milestones,
    required this.difficulty,
    required this.skillsLearned,
  });

  Progress copyWith({
    String? id,
    String? userId,
    String? itemId,
    ProgressType? type,
    ProgressStatus? status,
    double? completionPercentage,
    int? currentStep,
    int? totalSteps,
    int? score,
    int? maxScore,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastUpdated,
    Duration? timeSpent,
    int? attempts,
    Map<String, dynamic>? data,
    List<ProgressMilestone>? milestones,
    double? difficulty,
    List<String>? skillsLearned,
  }) {
    return Progress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      status: status ?? this.status,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      timeSpent: timeSpent ?? this.timeSpent,
      attempts: attempts ?? this.attempts,
      data: data ?? this.data,
      milestones: milestones ?? this.milestones,
      difficulty: difficulty ?? this.difficulty,
      skillsLearned: skillsLearned ?? this.skillsLearned,
    );
  }

  bool get isCompleted => status == ProgressStatus.completed || status == ProgressStatus.mastered;
  bool get isInProgress => status == ProgressStatus.inProgress;
  bool get isNotStarted => status == ProgressStatus.notStarted;
  bool get isFailed => status == ProgressStatus.failed;
  bool get isMastered => status == ProgressStatus.mastered;

  double get progressRatio => completionPercentage / 100.0;
  bool get isFullyCompleted => completionPercentage >= 100.0;

  int get remainingSteps => totalSteps - currentStep;
  double get scorePercentage => maxScore > 0 ? (score / maxScore) * 100.0 : 0.0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Progress &&
        other.id == id &&
        other.userId == userId &&
        other.itemId == itemId &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    userId.hashCode ^
    itemId.hashCode ^
    type.hashCode;
  }

  @override
  String toString() {
    return 'Progress(id: $id, userId: $userId, itemId: $itemId, type: $type, status: $status, completionPercentage: $completionPercentage%)';
  }
}

class ProgressMilestone {
  final String id;
  final String name;
  final String description;
  final int step;
  final bool isAchieved;
  final DateTime? achievedAt;
  final Map<String, dynamic> data;

  const ProgressMilestone({
    required this.id,
    required this.name,
    required this.description,
    required this.step,
    required this.isAchieved,
    this.achievedAt,
    required this.data,
  });

  ProgressMilestone copyWith({
    String? id,
    String? name,
    String? description,
    int? step,
    bool? isAchieved,
    DateTime? achievedAt,
    Map<String, dynamic>? data,
  }) {
    return ProgressMilestone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      step: step ?? this.step,
      isAchieved: isAchieved ?? this.isAchieved,
      achievedAt: achievedAt ?? this.achievedAt,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProgressMilestone &&
        other.id == id &&
        other.name == name &&
        other.step == step;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ step.hashCode;
  }

  @override
  String toString() {
    return 'ProgressMilestone(id: $id, name: $name, step: $step, isAchieved: $isAchieved)';
  }
}