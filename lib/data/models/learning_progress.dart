import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'learning_progress.g.dart';

@HiveType(typeId: 2)
class LearningProgress extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String commandName;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String difficulty;

  @HiveField(5)
  final DateTime startedAt;

  @HiveField(6)
  final DateTime? completedAt;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final double accuracy;

  @HiveField(9)
  final int attempts;

  @HiveField(10)
  final int correctAnswers;

  @HiveField(11)
  final int totalQuestions;

  @HiveField(12)
  final int completionTimeInSeconds;

  @HiveField(13)
  final int xpEarned;

  @HiveField(14)
  final List<String> mistakesMade;

  @HiveField(15)
  final Map<String, dynamic> metadata;

  @HiveField(16)
  final String progressType;

  @HiveField(17)
  final List<ProgressStep> steps;

  @HiveField(18)
  final int currentStepIndex;

  @HiveField(19)
  final double overallProgress;

  @HiveField(20)
  final List<String> hintsUsed;

  @HiveField(21)
  final bool needsReview;

  @HiveField(22)
  final DateTime? lastReviewedAt;

  @HiveField(23)
  final int reviewCount;

  const LearningProgress({
    required this.id,
    required this.userId,
    required this.commandName,
    required this.category,
    required this.difficulty,
    required this.startedAt,
    this.completedAt,
    this.isCompleted = false,
    this.accuracy = 0.0,
    this.attempts = 0,
    this.correctAnswers = 0,
    this.totalQuestions = 0,
    this.completionTimeInSeconds = 0,
    this.xpEarned = 0,
    this.mistakesMade = const [],
    this.metadata = const {},
    this.progressType = 'lesson',
    this.steps = const [],
    this.currentStepIndex = 0,
    this.overallProgress = 0.0,
    this.hintsUsed = const [],
    this.needsReview = false,
    this.lastReviewedAt,
    this.reviewCount = 0,
  });

  // Factory constructor from Map (Firebase)
  factory LearningProgress.fromMap(Map<String, dynamic> map) {
    return LearningProgress(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      commandName: map['commandName'] ?? '',
      category: map['category'] ?? '',
      difficulty: map['difficulty'] ?? 'beginner',
      startedAt: (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      isCompleted: map['isCompleted'] ?? false,
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
      attempts: map['attempts'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      completionTimeInSeconds: map['completionTimeInSeconds'] ?? 0,
      xpEarned: map['xpEarned'] ?? 0,
      mistakesMade: List<String>.from(map['mistakesMade'] ?? []),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      progressType: map['progressType'] ?? 'lesson',
      steps: (map['steps'] as List<dynamic>?)
          ?.map((e) => ProgressStep.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      currentStepIndex: map['currentStepIndex'] ?? 0,
      overallProgress: (map['overallProgress'] ?? 0.0).toDouble(),
      hintsUsed: List<String>.from(map['hintsUsed'] ?? []),
      needsReview: map['needsReview'] ?? false,
      lastReviewedAt: (map['lastReviewedAt'] as Timestamp?)?.toDate(),
      reviewCount: map['reviewCount'] ?? 0,
    );
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'commandName': commandName,
      'category': category,
      'difficulty': difficulty,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isCompleted': isCompleted,
      'accuracy': accuracy,
      'attempts': attempts,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'completionTimeInSeconds': completionTimeInSeconds,
      'xpEarned': xpEarned,
      'mistakesMade': mistakesMade,
      'metadata': metadata,
      'progressType': progressType,
      'steps': steps.map((e) => e.toMap()).toList(),
      'currentStepIndex': currentStepIndex,
      'overallProgress': overallProgress,
      'hintsUsed': hintsUsed,
      'needsReview': needsReview,
      'lastReviewedAt': lastReviewedAt != null ? Timestamp.fromDate(lastReviewedAt!) : null,
      'reviewCount': reviewCount,
    };
  }

  // JSON serialization (for local storage)
  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      commandName: json['commandName'] ?? '',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'beginner',
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      isCompleted: json['isCompleted'] ?? false,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      attempts: json['attempts'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      completionTimeInSeconds: json['completionTimeInSeconds'] ?? 0,
      xpEarned: json['xpEarned'] ?? 0,
      mistakesMade: List<String>.from(json['mistakesMade'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      progressType: json['progressType'] ?? 'lesson',
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => ProgressStep.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      currentStepIndex: json['currentStepIndex'] ?? 0,
      overallProgress: (json['overallProgress'] ?? 0.0).toDouble(),
      hintsUsed: List<String>.from(json['hintsUsed'] ?? []),
      needsReview: json['needsReview'] ?? false,
      lastReviewedAt: json['lastReviewedAt'] != null ? DateTime.parse(json['lastReviewedAt']) : null,
      reviewCount: json['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'commandName': commandName,
      'category': category,
      'difficulty': difficulty,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'accuracy': accuracy,
      'attempts': attempts,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'completionTimeInSeconds': completionTimeInSeconds,
      'xpEarned': xpEarned,
      'mistakesMade': mistakesMade,
      'metadata': metadata,
      'progressType': progressType,
      'steps': steps.map((e) => e.toJson()).toList(),
      'currentStepIndex': currentStepIndex,
      'overallProgress': overallProgress,
      'hintsUsed': hintsUsed,
      'needsReview': needsReview,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'reviewCount': reviewCount,
    };
  }

  // Copy with method
  LearningProgress copyWith({
    String? id,
    String? userId,
    String? commandName,
    String? category,
    String? difficulty,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? isCompleted,
    double? accuracy,
    int? attempts,
    int? correctAnswers,
    int? totalQuestions,
    int? completionTimeInSeconds,
    int? xpEarned,
    List<String>? mistakesMade,
    Map<String, dynamic>? metadata,
    String? progressType,
    List<ProgressStep>? steps,
    int? currentStepIndex,
    double? overallProgress,
    List<String>? hintsUsed,
    bool? needsReview,
    DateTime? lastReviewedAt,
    int? reviewCount,
  }) {
    return LearningProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      commandName: commandName ?? this.commandName,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      accuracy: accuracy ?? this.accuracy,
      attempts: attempts ?? this.attempts,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      completionTimeInSeconds: completionTimeInSeconds ?? this.completionTimeInSeconds,
      xpEarned: xpEarned ?? this.xpEarned,
      mistakesMade: mistakesMade ?? this.mistakesMade,
      metadata: metadata ?? this.metadata,
      progressType: progressType ?? this.progressType,
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      overallProgress: overallProgress ?? this.overallProgress,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      needsReview: needsReview ?? this.needsReview,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  // Helper methods
  String get categoryDisplayName {
    switch (category) {
      case 'file_management':
        return 'การจัดการไฟล์';
      case 'system_administration':
        return 'การจัดการระบบ';
      case 'networking':
        return 'เครือข่าย';
      case 'text_processing':
        return 'การประมวลผลข้อความ';
      case 'package_management':
        return 'การจัดการแพ็กเกจ';
      case 'security':
        return 'ความปลอดภัย';
      case 'shell_scripting':
        return 'สคริปต์เชลล์';
      default:
        return 'ทั่วไป';
    }
  }

  String get difficultyDisplayName {
    switch (difficulty) {
      case 'beginner':
        return 'ผู้เริ่มต้น';
      case 'intermediate':
        return 'ระดับกลาง';
      case 'advanced':
        return 'ระดับสูง';
      case 'expert':
        return 'ผู้เชี่ยวชาญ';
      default:
        return 'ไม่ระบุ';
    }
  }

  String get progressTypeDisplayName {
    switch (progressType) {
      case 'lesson':
        return 'บทเรียน';
      case 'quiz':
        return 'แบบทดสอบ';
      case 'practice':
        return 'การฝึกฝน';
      case 'terminal':
        return 'เทอร์มินัล';
      case 'challenge':
        return 'ความท้าทาย';
      default:
        return 'การเรียนรู้';
    }
  }

  // Calculate completion percentage
  double get completionPercentage {
    if (totalQuestions == 0) return overallProgress * 100;
    return (correctAnswers / totalQuestions) * 100;
  }

  // Get completion status
  String get completionStatus {
    if (isCompleted) return 'เสร็จสมบูรณ์';
    if (overallProgress > 0.5) return 'กำลังดำเนินการ';
    if (attempts > 0) return 'เริ่มแล้ว';
    return 'ยังไม่เริ่ม';
  }

  // Get performance level
  String get performanceLevel {
    if (accuracy >= 0.9) return 'ยอดเยี่ยม';
    if (accuracy >= 0.8) return 'ดีมาก';
    if (accuracy >= 0.7) return 'ดี';
    if (accuracy >= 0.6) return 'ปานกลาง';
    return 'ต้องปรับปรุง';
  }

  // Get time spent display
  String get timeSpentDisplay {
    if (completionTimeInSeconds < 60) {
      return '$completionTimeInSeconds วินาที';
    } else if (completionTimeInSeconds < 3600) {
      final minutes = (completionTimeInSeconds / 60).floor();
      final seconds = completionTimeInSeconds % 60;
      return '$minutes นาที $seconds วินาที';
    } else {
      final hours = (completionTimeInSeconds / 3600).floor();
      final minutes = ((completionTimeInSeconds % 3600) / 60).floor();
      return '$hours ชั่วโมง $minutes นาที';
    }
  }

  // Check if needs review based on time and performance
  bool get shouldReview {
    if (needsReview) return true;
    if (!isCompleted) return false;
    if (accuracy < 0.7) return true;

    final now = DateTime.now();
    final daysSinceCompletion = completedAt != null
        ? now.difference(completedAt!).inDays
        : 0;

    // Review after 7 days for excellent performance, 3 days for poor performance
    final reviewDays = accuracy >= 0.9 ? 7 : 3;
    return daysSinceCompletion >= reviewDays;
  }

  // Get next step to complete
  ProgressStep? get nextStep {
    if (currentStepIndex >= steps.length) return null;
    return steps[currentStepIndex];
  }

  // Get current step
  ProgressStep? get currentStep {
    if (steps.isEmpty || currentStepIndex >= steps.length) return null;
    return steps[currentStepIndex];
  }

  // Check if all steps are completed
  bool get allStepsCompleted {
    return steps.every((step) => step.isCompleted);
  }

  // Get completed steps count
  int get completedStepsCount {
    return steps.where((step) => step.isCompleted).length;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    commandName,
    category,
    difficulty,
    startedAt,
    completedAt,
    isCompleted,
    accuracy,
    attempts,
    correctAnswers,
    totalQuestions,
    completionTimeInSeconds,
    xpEarned,
    mistakesMade,
    metadata,
    progressType,
    steps,
    currentStepIndex,
    overallProgress,
    hintsUsed,
    needsReview,
    lastReviewedAt,
    reviewCount,
  ];
}

@HiveType(typeId: 7)
class ProgressStep extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String type;

  @HiveField(4)
  final bool isCompleted;

  @HiveField(5)
  final DateTime? completedAt;

  @HiveField(6)
  final double progress;

  @HiveField(7)
  final Map<String, dynamic> data;

  @HiveField(8)
  final List<String> requirements;

  @HiveField(9)
  final int order;

  const ProgressStep({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.isCompleted = false,
    this.completedAt,
    this.progress = 0.0,
    this.data = const {},
    this.requirements = const [],
    this.order = 0,
  });

  factory ProgressStep.fromMap(Map<String, dynamic> map) {
    return ProgressStep(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'lesson',
      isCompleted: map['isCompleted'] ?? false,
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      progress: (map['progress'] ?? 0.0).toDouble(),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      requirements: List<String>.from(map['requirements'] ?? []),
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'progress': progress,
      'data': data,
      'requirements': requirements,
      'order': order,
    };
  }

  factory ProgressStep.fromJson(Map<String, dynamic> json) {
    return ProgressStep(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'lesson',
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      progress: (json['progress'] ?? 0.0).toDouble(),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      requirements: List<String>.from(json['requirements'] ?? []),
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'progress': progress,
      'data': data,
      'requirements': requirements,
      'order': order,
    };
  }

  ProgressStep copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    bool? isCompleted,
    DateTime? completedAt,
    double? progress,
    Map<String, dynamic>? data,
    List<String>? requirements,
    int? order,
  }) {
    return ProgressStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      progress: progress ?? this.progress,
      data: data ?? this.data,
      requirements: requirements ?? this.requirements,
      order: order ?? this.order,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case 'lesson':
        return 'บทเรียน';
      case 'quiz':
        return 'แบบทดสอบ';
      case 'practice':
        return 'การฝึกฝน';
      case 'terminal':
        return 'เทอร์มินัล';
      case 'reading':
        return 'การอ่าน';
      case 'video':
        return 'วิดีโอ';
      default:
        return 'กิจกรรม';
    }
  }

  String get statusIcon {
    if (isCompleted) return '✅';
    if (progress > 0) return '🔄';
    return '⭕';
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    type,
    isCompleted,
    completedAt,
    progress,
    data,
    requirements,
    order,
  ];
}