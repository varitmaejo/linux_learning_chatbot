import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'achievement.g.dart';

@HiveType(typeId: 3)
@JsonSerializable()
class Achievement {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String iconPath;

  @HiveField(5)
  final AchievementType type;

  @HiveField(6)
  final AchievementRarity rarity;

  @HiveField(7)
  final int xpReward;

  @HiveField(8)
  final DateTime? unlockedAt;

  @HiveField(9)
  final bool isUnlocked;

  @HiveField(10)
  final Map<String, dynamic> criteria;

  @HiveField(11)
  final Map<String, dynamic>? progress;

  @HiveField(12)
  final String category;

  @HiveField(13)
  final int sortOrder;

  @HiveField(14)
  final bool isHidden;

  const Achievement({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.type,
    required this.rarity,
    required this.xpReward,
    this.unlockedAt,
    this.isUnlocked = false,
    required this.criteria,
    this.progress,
    required this.category,
    this.sortOrder = 0,
    this.isHidden = false,
  });

  // JSON serialization
  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);

  Map<String, dynamic> toJson() => _$AchievementToJson(this);

  // Factory constructors for different achievement types
  factory Achievement.firstLogin(String userId) {
    return Achievement(
      id: 'first_login',
      userId: userId,
      title: 'ยินดีต้อนรับ!',
      description: 'เข้าใช้งานระบบครั้งแรก',
      iconPath: 'assets/icons/achievements/first_login.svg',
      type: AchievementType.milestone,
      rarity: AchievementRarity.common,
      xpReward: 50,
      criteria: {'loginCount': 1},
      category: 'getting_started',
      sortOrder: 1,
    );
  }

  factory Achievement.firstCommand(String userId) {
    return Achievement(
      id: 'first_command',
      userId: userId,
      title: 'คำสั่งแรก',
      description: 'เรียนรู้คำสั่ง Linux คำสั่งแรก',
      iconPath: 'assets/icons/achievements/first_command.svg',
      type: AchievementType.learning,
      rarity: AchievementRarity.common,
      xpReward: 25,
      criteria: {'commandsLearned': 1},
      category: 'learning',
      sortOrder: 2,
    );
  }

  factory Achievement.weekStreak(String userId) {
    return Achievement(
      id: 'week_streak',
      userId: userId,
      title: 'นักเรียนขยัน',
      description: 'เรียนรู้ต่อเนื่อง 7 วันแล้ว!',
      iconPath: 'assets/icons/achievements/week_streak.svg',
      type: AchievementType.streak,
      rarity: AchievementRarity.uncommon,
      xpReward: 100,
      criteria: {'streakDays': 7},
      category: 'consistency',
      sortOrder: 10,
    );
  }

  factory Achievement.monthStreak(String userId) {
    return Achievement(
      id: 'month_streak',
      userId: userId,
      title: 'นักเรียนตัวจริง',
      description: 'เรียนรู้ต่อเนื่อง 30 วันแล้ว!',
      iconPath: 'assets/icons/achievements/month_streak.svg',
      type: AchievementType.streak,
      rarity: AchievementRarity.rare,
      xpReward: 500,
      criteria: {'streakDays': 30},
      category: 'consistency',
      sortOrder: 11,
    );
  }

  factory Achievement.perfectQuiz(String userId) {
    return Achievement(
      id: 'perfect_quiz',
      userId: userId,
      title: 'คะแนนเต็ม!',
      description: 'ทำแบบทดสอบได้คะแนนเต็ม',
      iconPath: 'assets/icons/achievements/perfect_quiz.svg',
      type: AchievementType.performance,
      rarity: AchievementRarity.uncommon,
      xpReward: 75,
      criteria: {'perfectQuizzes': 1},
      category: 'performance',
      sortOrder: 20,
    );
  }

  factory Achievement.commandMaster(String userId, String category) {
    return Achievement(
      id: 'master_$category',
      userId: userId,
      title: 'เซียนคำสั่ง ${_getCategoryName(category)}',
      description: 'เรียนรู้คำสั่ง $category ครบทุกคำสั่งแล้ว!',
      iconPath: 'assets/icons/achievements/command_master_$category.svg',
      type: AchievementType.mastery,
      rarity: AchievementRarity.epic,
      xpReward: 200,
      criteria: {'categoryMastery': category},
      category: 'mastery',
      sortOrder: 30,
    );
  }

  factory Achievement.speedLearner(String userId) {
    return Achievement(
      id: 'speed_learner',
      userId: userId,
      title: 'เรียนรู้เร็ว',
      description: 'เรียนจบบทเรียนภายใน 5 นาที',
      iconPath: 'assets/icons/achievements/speed_learner.svg',
      type: AchievementType.special,
      rarity: AchievementRarity.rare,
      xpReward: 150,
      criteria: {'fastCompletion': 300}, // 5 minutes in seconds
      category: 'special',
      sortOrder: 40,
    );
  }

  factory Achievement.nightOwl(String userId) {
    return Achievement(
      id: 'night_owl',
      userId: userId,
      title: 'นกฮูกดึก',
      description: 'เรียนรู้ในช่วงดึก (22:00-04:00)',
      iconPath: 'assets/icons/achievements/night_owl.svg',
      type: AchievementType.special,
      rarity: AchievementRarity.uncommon,
      xpReward: 50,
      criteria: {'nightStudy': 1},
      category: 'special',
      sortOrder: 50,
      isHidden: true,
    );
  }

  factory Achievement.earlyBird(String userId) {
    return Achievement(
      id: 'early_bird',
      userId: userId,
      title: 'นกตื่นเช้า',
      description: 'เรียนรู้ในตอนเช้าตรู่ (05:00-08:00)',
      iconPath: 'assets/icons/achievements/early_bird.svg',
      type: AchievementType.special,
      rarity: AchievementRarity.uncommon,
      xpReward: 50,
      criteria: {'earlyStudy': 1},
      category: 'special',
      sortOrder: 51,
      isHidden: true,
    );
  }

  factory Achievement.terminalExplorer(String userId) {
    return Achievement(
      id: 'terminal_explorer',
      userId: userId,
      title: 'นักสำรวจ Terminal',
      description: 'ใช้งาน Virtual Terminal ครั้งแรก',
      iconPath: 'assets/icons/achievements/terminal_explorer.svg',
      type: AchievementType.feature,
      rarity: AchievementRarity.common,
      xpReward: 25,
      criteria: {'terminalUsage': 1},
      category: 'features',
      sortOrder: 60,
    );
  }

  factory Achievement.voiceInteraction(String userId) {
    return Achievement(
      id: 'voice_interaction',
      userId: userId,
      title: 'นักสนทนา',
      description: 'ใช้ฟีเจอร์เสียงในการสนทนา',
      iconPath: 'assets/icons/achievements/voice_interaction.svg',
      type: AchievementType.feature,
      rarity: AchievementRarity.uncommon,
      xpReward: 75,
      criteria: {'voiceUsage': 1},
      category: 'features',
      sortOrder: 61,
    );
  }

  factory Achievement.socialSharer(String userId) {
    return Achievement(
      id: 'social_sharer',
      userId: userId,
      title: 'นักแชร์',
      description: 'แชร์ความสำเร็จไปยัง Social Media',
      iconPath: 'assets/icons/achievements/social_sharer.svg',
      type: AchievementType.social,
      rarity: AchievementRarity.rare,
      xpReward: 100,
      criteria: {'socialShares': 1},
      category: 'social',
      sortOrder: 70,
    );
  }

  factory Achievement.legendary(String userId) {
    return Achievement(
      id: 'legendary',
      userId: userId,
      title: 'ตำนาน Linux',
      description: 'เรียนจบทุกหมวดหมู่และได้คะแนนเฉลี่ย 95% ขึ้นไป',
      iconPath: 'assets/icons/achievements/legendary.svg',
      type: AchievementType.ultimate,
      rarity: AchievementRarity.legendary,
      xpReward: 1000,
      criteria: {
        'allCategoriesCompleted': true,
        'averageScore': 95,
      },
      category: 'ultimate',
      sortOrder: 100,
    );
  }

  static String _getCategoryName(String category) {
    const categories = {
      'file_management': 'การจัดการไฟล์',
      'system_admin': 'การจัดการระบบ',
      'network': 'เครือข่าย',
      'text_processing': 'การประมวลผลข้อความ',
      'package_management': 'การจัดการแพ็กเกจ',
      'security': 'ความปลอดภัย',
      'process_management': 'การจัดการโปรเซส',
      'archive': 'การจัดการไฟล์บีบอัด',
    };
    return categories[category] ?? category;
  }

  // Copy with method
  Achievement copyWith({
    DateTime? unlockedAt,
    bool? isUnlocked,
    Map<String, dynamic>? progress,
  }) {
    return Achievement(
      id: id,
      userId: userId,
      title: title,
      description: description,
      iconPath: iconPath,
      type: type,
      rarity: rarity,
      xpReward: xpReward,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      criteria: criteria,
      progress: progress ?? this.progress,
      category: category,
      sortOrder: sortOrder,
      isHidden: isHidden,
    );
  }

  // Unlock this achievement
  Achievement unlock() {
    return copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
  }

  // Update progress towards achievement
  Achievement updateProgress(Map<String, dynamic> newProgress) {
    return copyWith(progress: newProgress);
  }

  // Check if achievement criteria are met
  bool checkCriteria(Map<String, dynamic> userStats) {
    for (final criterion in criteria.entries) {
      final key = criterion.key;
      final requiredValue = criterion.value;
      final currentValue = userStats[key];

      if (currentValue == null) return false;

      switch (requiredValue.runtimeType) {
        case int:
          if (currentValue < requiredValue) return false;
          break;
        case double:
          if (currentValue < requiredValue) return false;
          break;
        case String:
          if (currentValue != requiredValue) return false;
          break;
        case bool:
          if (currentValue != requiredValue) return false;
          break;
        default:
        // Handle complex criteria
          if (!_checkComplexCriteria(key, requiredValue, currentValue)) {
            return false;
          }
      }
    }
    return true;
  }

  bool _checkComplexCriteria(String key, dynamic required, dynamic current) {
    switch (key) {
      case 'categoryMastery':
      // Check if specific category is mastered
        if (current is Map<String, dynamic>) {
          final categoryScore = current[required as String] as int? ?? 0;
          return categoryScore >= 100;
        }
        return false;
      case 'allCategoriesCompleted':
        if (current is Map<String, dynamic>) {
          return current.values.every((score) => (score as int) >= 100);
        }
        return false;
      default:
        return current == required;
    }
  }

  // Calculate progress percentage towards unlocking
  double getProgressPercentage(Map<String, dynamic> userStats) {
    if (isUnlocked) return 100.0;

    double totalProgress = 0.0;
    int criteriaCount = criteria.length;

    for (final criterion in criteria.entries) {
      final key = criterion.key;
      final requiredValue = criterion.value;
      final currentValue = userStats[key];

      if (currentValue == null) continue;

      double criterionProgress = 0.0;

      switch (requiredValue.runtimeType) {
        case int:
          criterionProgress = ((currentValue as int) / (requiredValue as int))
              .clamp(0.0, 1.0);
          break;
        case double:
          criterionProgress = ((currentValue as double) / (requiredValue as double))
              .clamp(0.0, 1.0);
          break;
        case bool:
          criterionProgress = (currentValue as bool) == (requiredValue as bool) ? 1.0 : 0.0;
          break;
        default:
          criterionProgress = _calculateComplexProgress(key, requiredValue, currentValue);
      }

      totalProgress += criterionProgress;
    }

    return criteriaCount > 0 ? (totalProgress / criteriaCount) * 100 : 0.0;
  }

  double _calculateComplexProgress(String key, dynamic required, dynamic current) {
    switch (key) {
      case 'categoryMastery':
        if (current is Map<String, dynamic>) {
          final categoryScore = current[required as String] as int? ?? 0;
          return (categoryScore / 100).clamp(0.0, 1.0);
        }
        return 0.0;
      case 'allCategoriesCompleted':
        if (current is Map<String, dynamic>) {
          final completedCategories = current.values.where((score) => (score as int) >= 100).length;
          return (completedCategories / current.length).clamp(0.0, 1.0);
        }
        return 0.0;
      default:
        return current == required ? 1.0 : 0.0;
    }
  }

  // Get display information
  String get rarityDisplayName {
    switch (rarity) {
      case AchievementRarity.common:
        return 'ทั่วไป';
      case AchievementRarity.uncommon:
        return 'ไม่ธรรมดา';
      case AchievementRarity.rare:
        return 'หายาก';
      case AchievementRarity.epic:
        return 'ยิ่งใหญ่';
      case AchievementRarity.legendary:
        return 'ตำนาน';
      default:
        return 'ไม่ระบุ';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case AchievementType.milestone:
        return 'เหตุการณ์สำคัญ';
      case AchievementType.learning:
        return 'การเรียนรู้';
      case AchievementType.streak:
        return 'ความต่อเนื่อง';
      case AchievementType.performance:
        return 'ผลงาน';
      case AchievementType.mastery:
        return 'ความเชี่ยวชาญ';
      case AchievementType.special:
        return 'พิเศษ';
      case AchievementType.feature:
        return 'ฟีเจอร์';
      case AchievementType.social:
        return 'สังคม';
      case AchievementType.ultimate:
        return 'สูงสุด';
      default:
        return 'ไม่ระบุ';
    }
  }

  String get categoryDisplayName {
    const categories = {
      'getting_started': 'เริ่มต้นใช้งาน',
      'learning': 'การเรียนรู้',
      'consistency': 'ความสม่ำเสมอ',
      'performance': 'ผลงาน',
      'mastery': 'ความเชี่ยวชาญ',
      'special': 'พิเศษ',
      'features': 'ฟีเจอร์',
      'social': 'สังคม',
      'ultimate': 'สูงสุด',
    };
    return categories[category] ?? category;
  }

  // Get rarity color
  String get rarityColorHex {
    switch (rarity) {
      case AchievementRarity.common:
        return '#9E9E9E'; // Grey
      case AchievementRarity.uncommon:
        return '#4CAF50'; // Green
      case AchievementRarity.rare:
        return '#2196F3'; // Blue
      case AchievementRarity.epic:
        return '#9C27B0'; // Purple
      case AchievementRarity.legendary:
        return '#FF9800'; // Orange
      default:
        return '#9E9E9E';
    }
  }

  // Time since unlock
  String get timeSinceUnlock {
    if (!isUnlocked || unlockedAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(unlockedAt!);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months เดือนที่แล้ว';
    }
  }

  // Check if can be displayed (not hidden or already unlocked)
  bool get canDisplay => !isHidden || isUnlocked;

  // Get achievement difficulty score
  int get difficultyScore {
    int score = 0;

    // Base score from rarity
    switch (rarity) {
      case AchievementRarity.common:
        score += 1;
        break;
      case AchievementRarity.uncommon:
        score += 3;
        break;
      case AchievementRarity.rare:
        score += 5;
        break;
      case AchievementRarity.epic:
        score += 8;
        break;
      case AchievementRarity.legendary:
        score += 10;
        break;
    }

    // Add complexity from criteria
    score += criteria.length;

    // Add bonus for hidden achievements
    if (isHidden) score += 2;

    return score;
  }

  @override
  String toString() {
    return 'Achievement(id: $id, title: $title, unlocked: $isUnlocked, rarity: $rarity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement && other.id == id && other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(id, userId);
}

// Hive Adapters for Enums
@HiveType(typeId: 6)
enum AchievementType {
  @HiveField(0)
  milestone,

  @HiveField(1)
  learning,

  @HiveField(2)
  streak,

  @HiveField(3)
  performance,

  @HiveField(4)
  mastery,

  @HiveField(5)
  special,

  @HiveField(6)
  feature,

  @HiveField(7)
  social,

  @HiveField(8)
  ultimate,
}

@HiveType(typeId: 7)
enum AchievementRarity {
  @HiveField(0)
  common,

  @HiveField(1)
  uncommon,

  @HiveField(2)
  rare,

  @HiveField(3)
  epic,

  @HiveField(4)
  legendary,
}