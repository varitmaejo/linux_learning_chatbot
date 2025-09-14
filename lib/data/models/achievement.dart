import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'achievement.g.dart';

@HiveType(typeId: 3)
class Achievement extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String iconPath;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String difficulty;

  @HiveField(6)
  final int xpReward;

  @HiveField(7)
  final DateTime? unlockedAt;

  @HiveField(8)
  final bool isUnlocked;

  @HiveField(9)
  final double progress;

  @HiveField(10)
  final double maxProgress;

  @HiveField(11)
  final Map<String, dynamic> requirements;

  @HiveField(12)
  final List<String> prerequisites;

  @HiveField(13)
  final bool isSecret;

  @HiveField(14)
  final String badgeColor;

  @HiveField(15)
  final int rarity;

  @HiveField(16)
  final List<AchievementStep> steps;

  @HiveField(17)
  final Map<String, dynamic> metadata;

  @HiveField(18)
  final DateTime createdAt;

  @HiveField(19)
  final bool isActive;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    this.category = 'general',
    this.difficulty = 'easy',
    this.xpReward = 0,
    this.unlockedAt,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.maxProgress = 1.0,
    this.requirements = const {},
    this.prerequisites = const [],
    this.isSecret = false,
    this.badgeColor = 'bronze',
    this.rarity = 1,
    this.steps = const [],
    this.metadata = const {},
    required this.createdAt,
    this.isActive = true,
  });

  // Factory constructor from Map (Firebase)
  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      iconPath: map['iconPath'] ?? '',
      category: map['category'] ?? 'general',
      difficulty: map['difficulty'] ?? 'easy',
      xpReward: map['xpReward'] ?? 0,
      unlockedAt: (map['unlockedAt'] as Timestamp?)?.toDate(),
      isUnlocked: map['isUnlocked'] ?? false,
      progress: (map['progress'] ?? 0.0).toDouble(),
      maxProgress: (map['maxProgress'] ?? 1.0).toDouble(),
      requirements: Map<String, dynamic>.from(map['requirements'] ?? {}),
      prerequisites: List<String>.from(map['prerequisites'] ?? []),
      isSecret: map['isSecret'] ?? false,
      badgeColor: map['badgeColor'] ?? 'bronze',
      rarity: map['rarity'] ?? 1,
      steps: (map['steps'] as List<dynamic>?)
          ?.map((e) => AchievementStep.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'category': category,
      'difficulty': difficulty,
      'xpReward': xpReward,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'isUnlocked': isUnlocked,
      'progress': progress,
      'maxProgress': maxProgress,
      'requirements': requirements,
      'prerequisites': prerequisites,
      'isSecret': isSecret,
      'badgeColor': badgeColor,
      'rarity': rarity,
      'steps': steps.map((e) => e.toMap()).toList(),
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  // JSON serialization (for local storage)
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconPath: json['iconPath'] ?? '',
      category: json['category'] ?? 'general',
      difficulty: json['difficulty'] ?? 'easy',
      xpReward: json['xpReward'] ?? 0,
      unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
      isUnlocked: json['isUnlocked'] ?? false,
      progress: (json['progress'] ?? 0.0).toDouble(),
      maxProgress: (json['maxProgress'] ?? 1.0).toDouble(),
      requirements: Map<String, dynamic>.from(json['requirements'] ?? {}),
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      isSecret: json['isSecret'] ?? false,
      badgeColor: json['badgeColor'] ?? 'bronze',
      rarity: json['rarity'] ?? 1,
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => AchievementStep.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'category': category,
      'difficulty': difficulty,
      'xpReward': xpReward,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isUnlocked': isUnlocked,
      'progress': progress,
      'maxProgress': maxProgress,
      'requirements': requirements,
      'prerequisites': prerequisites,
      'isSecret': isSecret,
      'badgeColor': badgeColor,
      'rarity': rarity,
      'steps': steps.map((e) => e.toJson()).toList(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Copy with method
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    String? category,
    String? difficulty,
    int? xpReward,
    DateTime? unlockedAt,
    bool? isUnlocked,
    double? progress,
    double? maxProgress,
    Map<String, dynamic>? requirements,
    List<String>? prerequisites,
    bool? isSecret,
    String? badgeColor,
    int? rarity,
    List<AchievementStep>? steps,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      maxProgress: maxProgress ?? this.maxProgress,
      requirements: requirements ?? this.requirements,
      prerequisites: prerequisites ?? this.prerequisites,
      isSecret: isSecret ?? this.isSecret,
      badgeColor: badgeColor ?? this.badgeColor,
      rarity: rarity ?? this.rarity,
      steps: steps ?? this.steps,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper methods
  String get categoryDisplayName {
    switch (category) {
      case 'learning':
        return 'การเรียนรู้';
      case 'practice':
        return 'การฝึกฝน';
      case 'terminal':
        return 'เทอร์มินัล';
      case 'social':
        return 'สังคม';
      case 'streak':
        return 'ความต่อเนื่อง';
      case 'mastery':
        return 'ความเชี่ยวชาญ';
      case 'special':
        return 'พิเศษ';
      default:
        return 'ทั่วไป';
    }
  }

  String get difficultyDisplayName {
    switch (difficulty) {
      case 'easy':
        return 'ง่าย';
      case 'medium':
        return 'ปานกลาง';
      case 'hard':
        return 'ยาก';
      case 'legendary':
        return 'ตำนาน';
      default:
        return 'ไม่ระบุ';
    }
  }

  String get rarityDisplayName {
    switch (rarity) {
      case 1:
        return 'ธรรมดา';
      case 2:
        return 'หายาก';
      case 3:
        return 'หายากมาก';
      case 4:
        return 'ตำนาน';
      case 5:
        return 'เทพ';
      default:
        return 'ธรรมดา';
    }
  }

  String get badgeColorDisplayName {
    switch (badgeColor) {
      case 'bronze':
        return 'ทองแดง';
      case 'silver':
        return 'เงิน';
      case 'gold':
        return 'ทอง';
      case 'diamond':
        return 'เพชร';
      default:
        return 'ทองแดง';
    }
  }

  // Calculate progress percentage
  double get progressPercentage {
    if (maxProgress == 0) return 0.0;
    return (progress / maxProgress).clamp(0.0, 1.0);
  }

  // Get progress display text
  String get progressDisplay {
    if (isUnlocked) return 'ปลดล็อกแล้ว';
    if (maxProgress == 1.0) {
      return '${(progressPercentage * 100).toInt()}%';
    }
    return '${progress.toInt()}/${maxProgress.toInt()}';
  }

  // Check if achievement can be unlocked
  bool get canUnlock {
    return !isUnlocked && progressPercentage >= 1.0;
  }

  // Get completion status
  String get statusDisplay {
    if (isUnlocked) return 'ปลดล็อกแล้ว';
    if (progress > 0) return 'กำลังดำเนินการ';
    return 'ยังไม่เริ่ม';
  }

  // Get rarity color
  String get rarityColor {
    switch (rarity) {
      case 1:
        return '#8E8E93'; // Gray
      case 2:
        return '#007AFF'; // Blue
      case 3:
        return '#AF52DE'; // Purple
      case 4:
        return '#FF9500'; // Orange
      case 5:
        return '#FF3B30'; // Red
      default:
        return '#8E8E93';
    }
  }

  // Get achievement icon
  String get icon {
    if (isSecret && !isUnlocked) return '❓';

    switch (category) {
      case 'learning':
        return '📚';
      case 'practice':
        return '💪';
      case 'terminal':
        return '⚡';
      case 'social':
        return '👥';
      case 'streak':
        return '🔥';
      case 'mastery':
        return '👑';
      case 'special':
        return '⭐';
      default:
        return '🏆';
    }
  }

  // Check if user meets prerequisites
  bool hasMetPrerequisites(List<String> unlockedAchievements) {
    return prerequisites.every((prereq) => unlockedAchievements.contains(prereq));
  }

  // Get steps progress
  double get stepsProgress {
    if (steps.isEmpty) return progressPercentage;
    final completedSteps = steps.where((step) => step.isCompleted).length;
    return completedSteps / steps.length;
  }

  // Get next uncompleted step
  AchievementStep? get nextStep {
    return steps.firstWhere(
          (step) => !step.isCompleted,
      orElse: () => steps.isNotEmpty ? steps.last : const AchievementStep(
        id: '',
        title: '',
        description: '',
        requirement: '',
        targetValue: 0,
        currentValue: 0,
        isCompleted: true,
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    iconPath,
    category,
    difficulty,
    xpReward,
    unlockedAt,
    isUnlocked,
    progress,
    maxProgress,
    requirements,
    prerequisites,
    isSecret,
    badgeColor,
    rarity,
    steps,
    metadata,
    createdAt,
    isActive,
  ];
}

@HiveType(typeId: 8)
class AchievementStep extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String requirement;

  @HiveField(4)
  final double targetValue;

  @HiveField(5)
  final double currentValue;

  @HiveField(6)
  final bool isCompleted;

  @HiveField(7)
  final DateTime? completedAt;

  @HiveField(8)
  final int order;

  const AchievementStep({
    required this.id,
    required this.title,
    required this.description,
    required this.requirement,
    required this.targetValue,
    this.currentValue = 0.0,
    this.isCompleted = false,
    this.completedAt,
    this.order = 0,
  });

  factory AchievementStep.fromMap(Map<String, dynamic> map) {
    return AchievementStep(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      requirement: map['requirement'] ?? '',
      targetValue: (map['targetValue'] ?? 0.0).toDouble(),
      currentValue: (map['currentValue'] ?? 0.0).toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requirement': requirement,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'order': order,
    };
  }

  factory AchievementStep.fromJson(Map<String, dynamic> json) {
    return AchievementStep(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requirement: json['requirement'] ?? '',
      targetValue: (json['targetValue'] ?? 0.0).toDouble(),
      currentValue: (json['currentValue'] ?? 0.0).toDouble(),
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requirement': requirement,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'order': order,
    };
  }

  AchievementStep copyWith({
    String? id,
    String? title,
    String? description,
    String? requirement,
    double? targetValue,
    double? currentValue,
    bool? isCompleted,
    DateTime? completedAt,
    int? order,
  }) {
    return AchievementStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      requirement: requirement ?? this.requirement,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      order: order ?? this.order,
    );
  }

  double get progressPercentage {
    if (targetValue == 0) return isCompleted ? 1.0 : 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  String get progressDisplay {
    if (targetValue == 1.0) {
      return isCompleted ? 'เสร็จสิ้น' : 'ยังไม่เสร็จ';
    }
    return '${currentValue.toInt()}/${targetValue.toInt()}';
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    requirement,
    targetValue,
    currentValue,
    isCompleted,
    completedAt,
    order,
  ];
}