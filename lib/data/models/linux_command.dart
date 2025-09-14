import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'linux_command.g.dart';

@HiveType(typeId: 4)
class LinuxCommand extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String syntax;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String difficulty;

  @HiveField(6)
  final List<String> examples;

  @HiveField(7)
  final List<CommandOption> options;

  @HiveField(8)
  final List<String> relatedCommands;

  @HiveField(9)
  final List<String> tags;

  @HiveField(10)
  final String iconPath;

  @HiveField(11)
  final bool isPopular;

  @HiveField(12)
  final int usageCount;

  @HiveField(13)
  final double averageRating;

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
  final DateTime updatedAt;

  @HiveField(16)
  final String longDescription;

  @HiveField(17)
  final List<CommandUseCase> useCases;

  @HiveField(18)
  final List<String> prerequisites;

  @HiveField(19)
  final String manualUrl;

  const LinuxCommand({
    required this.id,
    required this.name,
    required this.description,
    required this.syntax,
    required this.category,
    required this.difficulty,
    this.examples = const [],
    this.options = const [],
    this.relatedCommands = const [],
    this.tags = const [],
    this.iconPath = '',
    this.isPopular = false,
    this.usageCount = 0,
    this.averageRating = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.longDescription = '',
    this.useCases = const [],
    this.prerequisites = const [],
    this.manualUrl = '',
  });

  // Factory constructor from Map (Firebase/JSON)
  factory LinuxCommand.fromMap(Map<String, dynamic> map) {
    return LinuxCommand(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      syntax: map['syntax'] ?? '',
      category: map['category'] ?? '',
      difficulty: map['difficulty'] ?? 'beginner',
      examples: List<String>.from(map['examples'] ?? []),
      options: (map['options'] as List<dynamic>?)
          ?.map((e) => CommandOption.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      relatedCommands: List<String>.from(map['relatedCommands'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      iconPath: map['iconPath'] ?? '',
      isPopular: map['isPopular'] ?? false,
      usageCount: map['usageCount'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      longDescription: map['longDescription'] ?? '',
      useCases: (map['useCases'] as List<dynamic>?)
          ?.map((e) => CommandUseCase.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      prerequisites: List<String>.from(map['prerequisites'] ?? []),
      manualUrl: map['manualUrl'] ?? '',
    );
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'syntax': syntax,
      'category': category,
      'difficulty': difficulty,
      'examples': examples,
      'options': options.map((e) => e.toMap()).toList(),
      'relatedCommands': relatedCommands,
      'tags': tags,
      'iconPath': iconPath,
      'isPopular': isPopular,
      'usageCount': usageCount,
      'averageRating': averageRating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'longDescription': longDescription,
      'useCases': useCases.map((e) => e.toMap()).toList(),
      'prerequisites': prerequisites,
      'manualUrl': manualUrl,
    };
  }

  // Copy with method
  LinuxCommand copyWith({
    String? id,
    String? name,
    String? description,
    String? syntax,
    String? category,
    String? difficulty,
    List<String>? examples,
    List<CommandOption>? options,
    List<String>? relatedCommands,
    List<String>? tags,
    String? iconPath,
    bool? isPopular,
    int? usageCount,
    double? averageRating,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? longDescription,
    List<CommandUseCase>? useCases,
    List<String>? prerequisites,
    String? manualUrl,
  }) {
    return LinuxCommand(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      syntax: syntax ?? this.syntax,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      examples: examples ?? this.examples,
      options: options ?? this.options,
      relatedCommands: relatedCommands ?? this.relatedCommands,
      tags: tags ?? this.tags,
      iconPath: iconPath ?? this.iconPath,
      isPopular: isPopular ?? this.isPopular,
      usageCount: usageCount ?? this.usageCount,
      averageRating: averageRating ?? this.averageRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      longDescription: longDescription ?? this.longDescription,
      useCases: useCases ?? this.useCases,
      prerequisites: prerequisites ?? this.prerequisites,
      manualUrl: manualUrl ?? this.manualUrl,
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

  String get difficultyIcon {
    switch (difficulty) {
      case 'beginner':
        return '🌱';
      case 'intermediate':
        return '🌿';
      case 'advanced':
        return '🌳';
      case 'expert':
        return '🚀';
      default:
        return '❓';
    }
  }

  String get categoryIcon {
    switch (category) {
      case 'file_management':
        return '📁';
      case 'system_administration':
        return '⚙️';
      case 'networking':
        return '🌐';
      case 'text_processing':
        return '📝';
      case 'package_management':
        return '📦';
      case 'security':
        return '🔒';
      case 'shell_scripting':
        return '🔧';
      default:
        return '💻';
    }
  }

  bool get hasExamples => examples.isNotEmpty;
  bool get hasOptions => options.isNotEmpty;
  bool get hasRelatedCommands => relatedCommands.isNotEmpty;
  bool get hasUseCases => useCases.isNotEmpty;
  bool get hasPrerequisites => prerequisites.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    syntax,
    category,
    difficulty,
    examples,
    options,
    relatedCommands,
    tags,
    iconPath,
    isPopular,
    usageCount,
    averageRating,
    createdAt,
    updatedAt,
    longDescription,
    useCases,
    prerequisites,
    manualUrl,
  ];
}

@HiveType(typeId: 5)
class CommandOption extends Equatable {
  @HiveField(0)
  final String flag;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final String? example;

  @HiveField(3)
  final bool isRequired;

  const CommandOption({
    required this.flag,
    required this.description,
    this.example,
    this.isRequired = false,
  });

  factory CommandOption.fromMap(Map<String, dynamic> map) {
    return CommandOption(
      flag: map['flag'] ?? '',
      description: map['description'] ?? '',
      example: map['example'],
      isRequired: map['isRequired'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'flag': flag,
      'description': description,
      'example': example,
      'isRequired': isRequired,
    };
  }

  @override
  List<Object?> get props => [flag, description, example, isRequired];
}

@HiveType(typeId: 6)
class CommandUseCase extends Equatable {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final String example;

  @HiveField(3)
  final String expectedOutput;

  const CommandUseCase({
    required this.title,
    required this.description,
    required this.example,
    this.expectedOutput = '',
  });

  factory CommandUseCase.fromMap(Map<String, dynamic> map) {
    return CommandUseCase(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      example: map['example'] ?? '',
      expectedOutput: map['expectedOutput'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'example': example,
      'expectedOutput': expectedOutput,
    };
  }

  @override
  List<Object?> get props => [title, description, example, expectedOutput];
}