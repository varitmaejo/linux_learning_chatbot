import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'achievement.g.dart';

enum AchievementType {
  streak,
  commandsLearned,
  quizCompleted,
  timeSpent,
  perfectScore,
  firstTime,
  milestone,
  challenge,
  consistency,
  mastery
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary
}

@HiveType(typeId: 10)
class Achievement extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String icon;

  @HiveField(4)
  final AchievementType type;

  @HiveField(5)
  final AchievementRarity rarity;

  @HiveField(6)
  final int points;

  @HiveField(7)
  final Map<String, dynamic> requirements;

  @HiveField(8)
  final bool isUnlocked;

  @HiveField(9)
  final DateTime? unlockedAt;

  @HiveField(10)
  final double progress;

  @HiveField(11)
  final String? category;

  @HiveField(12)
  final List<String>? prerequisites;

  @HiveField(13)
  final bool isHidden;

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
  final Map<String, dynamic>? metadata;

  @HiveField(16)
  final String? badgeUrl;

  @HiveField(17)
  final String? celebrationMessage;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.rarity,
    required this.points,
    required this.requirements,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0.0,
    this.category,
    this.prerequisites,
    this.isHidden = false,
    required this.createdAt,
    this.metadata,
    this.badgeUrl,
    this.celebrationMessage,
  });

  // Factory constructor from Map (Firebase)
  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🏆',
      type: AchievementType.values.firstWhere(
            (e) => e.toString() == 'AchievementType.${map['type']}',
        orElse: () => AchievementType.milestone,
      ),
      rarity: AchievementRarity.values.firstWhere(
            (e) => e.toString() == 'AchievementRarity.${map['rarity']}',
        orElse: () => AchievementRarity.common,
      ),
      points: map['points'] ?? 0,
      requirements: Map<String, dynamic>.from(map['requirements'] ?? {}),
      isUnlocked: map['isUnlocked'] ?? false,
      unlockedAt: map['unlockedAt'] != null
          ? (map['unlockedAt'] as Timestamp).toDate()
          : null,
      progress: (map['progress'] ?? 0.0).toDouble(),
      category: map['category'],
      prerequisites: map['prerequisites'] != null
          ? List<String>.from(map['prerequisites'])
          : null,
      isHidden: map['isHidden'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      badgeUrl: map['badgeUrl'],
      celebrationMessage: map['celebrationMessage'],
    );
  }

  // Convert to Map (Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'type': type.toString().split('.').last,
      'rarity': rarity.toString().split('.').last,
      'points': points,
      'requirements': requirements,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'progress': progress,
      'category': category,
      'prerequisites': prerequisites,
      'isHidden': isHidden,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
      'badgeUrl': badgeUrl,
      'celebrationMessage': celebrationMessage,
    };
  }

  // Copy with method
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    AchievementType? type,
    AchievementRarity? rarity,
    int? points,
    Map<String, dynamic>? requirements,
    bool? isUnlocked,
    DateTime? unlockedAt,
    double? progress,
    String? category,
    List<String>? prerequisites,
    bool? isHidden,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    String? badgeUrl,
    String? celebrationMessage,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      points: points ?? this.points,
      requirements: requirements ?? this.requirements,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      category: category ?? this.category,
      prerequisites: prerequisites ?? this.prerequisites,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      badgeUrl: badgeUrl ?? this.badgeUrl,
      celebrationMessage: celebrationMessage ?? this.celebrationMessage,
    );
  }

  // Helper methods
  String get typeDisplayText {
    switch (type) {
      case AchievementType.streak:
        return 'ความต่อเนื่อง';
      case AchievementType.commandsLearned:
        return 'คำสั่งที่เรียนรู้';
      case AchievementType.quizCompleted:
        return 'แบบทดสอบ';
      case AchievementType.timeSpent:
        return 'เวลาเรียนรู้';
      case AchievementType.perfectScore:
        return 'คะแนนเต็ม';
      case AchievementType.firstTime:
        return 'ครั้งแรก';
      case AchievementType.milestone:
        return 'เป้าหมาย';
      case AchievementType.challenge:
        return 'ความท้าทาย';
      case AchievementType.consistency:
        return 'ความสม่ำเสมอ';
      case AchievementType.mastery:
        return 'ความเชี่ยวชาญ';
    }
  }

  String get rarityDisplayText {
    switch (rarity) {
      case AchievementRarity.common:
        return 'ธรรมดา';
      case AchievementRarity.rare:
        return 'หายาก';
      case AchievementRarity.epic:
        return 'ยอดเยี่ยม';
      case AchievementRarity.legendary:
        return 'ตำนาน';
    }
  }

  String get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return '#9E9E9E'; // Gray
      case AchievementRarity.rare:
        return '#2196F3'; // Blue
      case AchievementRarity.epic:
        return '#9C27B0'; // Purple
      case AchievementRarity.legendary:
        return '#FF9800'; // Orange
    }
  }

  bool get isProgressBased => progress < 1.0 && !isUnlocked;
  bool get canBeUnlocked => progress >= 1.0 && !isUnlocked;
  bool get hasPrerequisites => prerequisites != null && prerequisites!.isNotEmpty;

  String get progressText {
    if (isUnlocked) return 'ปลดล็อกแล้ว';
    if (progress >= 1.0) return 'พร้อมรับรางวัล';
    return '${(progress * 100).toInt()}% สำเร็จ';
  }

  double get progressPercentage => (progress * 100).clamp(0.0, 100.0);

  String get formattedUnlockedDate {
    if (unlockedAt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(unlockedAt!);

    if (difference.inDays == 0) {
      return 'วันนี้';
    } else if (difference.inDays == 1) {
      return 'เมื่อวาน';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks สัปดาห์ที่แล้ว';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months เดือนที่แล้ว';
    }
  }

  // Check if achievement requirements are met
  bool checkRequirements(Map<String, dynamic> userStats) {
    for (final requirement in requirements.entries) {
      final key = requirement.key;
      final requiredValue = requirement.value;
      final userValue = userStats[key] ?? 0;

      if (requiredValue is int && userValue < requiredValue) {
        return false;
      } else if (requiredValue is double && userValue < requiredValue) {
        return false;
      }
    }
    return true;
  }

  // Calculate progress based on user stats
  double calculateProgress(Map<String, dynamic> userStats) {
    if (requirements.isEmpty) return isUnlocked ? 1.0 : 0.0;

    double totalProgress = 0.0;
    int requirementCount = 0;

    for (final requirement in requirements.entries) {
      final key = requirement.key;
      final requiredValue = requirement.value;
      final userValue = userStats[key] ?? 0;

      if (requiredValue is int) {
        totalProgress += (userValue / requiredValue).clamp(0.0, 1.0);
      } else if (requiredValue is double) {
        totalProgress += (userValue / requiredValue).clamp(0.0, 1.0);
      }

      requirementCount++;
    }

    return requirementCount > 0 ? totalProgress / requirementCount : 0.0;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    icon,
    type,
    rarity,
    points,
    requirements,
    isUnlocked,
    unlockedAt,
    progress,
    category,
    prerequisites,
    isHidden,
    createdAt,
    metadata,
    badgeUrl,
    celebrationMessage,
  ];

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, isUnlocked: $isUnlocked, progress: $progress)';
  }
}

// Predefined achievements factory
class AchievementFactory {
  static List<Achievement> createDefaultAchievements() {
    return [
      // First Time Achievements
      Achievement(
        id: 'first_command',
        title: 'คำสั่งแรก',
        description: 'เรียนรู้คำสั่ง Linux คำสั่งแรกของคุณ',
        icon: '🚀',
        type: AchievementType.firstTime,
        rarity: AchievementRarity.common,
        points: 10,
        requirements: {'commandsLearned': 1},
        createdAt: DateTime.now(),
        celebrationMessage: 'ยินดีด้วย! คุณได้เรียนรู้คำสั่ง Linux คำสั่งแรกแล้ว',
      ),

      // Commands Learned Achievements
      Achievement(
        id: 'novice_learner',
        title: 'ผู้เรียนมือใหม่',
        description: 'เรียนรู้คำสั่ง Linux 10 คำสั่ง',
        icon: '📚',
        type: AchievementType.commandsLearned,
        rarity: AchievementRarity.common,
        points: 50,
        requirements: {'commandsLearned': 10},
        createdAt: DateTime.now(),
      ),

      Achievement(
        id: 'intermediate_learner',
        title: 'ผู้เรียนระดับกลาง',
        description: 'เรียนรู้คำสั่ง Linux 50 คำสั่ง',
        icon: '🎓',
        type: AchievementType.commandsLearned,
        rarity: AchievementRarity.rare,
        points: 200,
        requirements: {'commandsLearned': 50},
        createdAt: DateTime.now(),
      ),

      // Streak Achievements
      Achievement(
        id: 'week_streak',
        title: 'สัปดาห์แห่งการเรียนรู้',
        description: 'เรียนรู้ต่อเนื่อง 7 วัน',
        icon: '🔥',
        type: AchievementType.streak,
        rarity: AchievementRarity.rare,
        points: 100,
        requirements: {'longestStreak': 7},
        createdAt: DateTime.now(),
      ),

      // Perfect Score Achievements
      Achievement(
        id: 'perfect_quiz',
        title: 'คะแนนเต็มครั้งแรก',
        description: 'ได้คะแนนเต็มในแบบทดสอบ',
        icon: '⭐',
        type: AchievementType.perfectScore,
        rarity: AchievementRarity.common,
        points: 25,
        requirements: {'perfectScores': 1},
        createdAt: DateTime.now(),
      ),

      // Time Spent Achievements
      Achievement(
        id: 'dedicated_learner',
        title: 'ผู้เรียนผู้ทุ่มเท',
        description: 'ใช้เวลาเรียนรู้รวม 10 ชั่วโมง',
        icon: '⏰',
        type: AchievementType.timeSpent,
        rarity: AchievementRarity.epic,
        points: 300,
        requirements: {'totalTimeSpentHours': 10},
        createdAt: DateTime.now(),
      ),

      // Legendary Achievements
      Achievement(
        id: 'linux_master',
        title: 'เซียนลีนุกซ์',
        description: 'เรียนรู้คำสั่ง Linux ครบ 200 คำสั่ง',
        icon: '👑',
        type: AchievementType.mastery,
        rarity: AchievementRarity.legendary,
        points: 1000,
        requirements: {'commandsLearned': 200, 'perfectScores': 50},
        createdAt: DateTime.now(),
        celebrationMessage: 'ยอดเยี่ยม! คุณเป็นเซียนลีนุกซ์แล้ว! 🎉',
      ),
    ];
  }
}