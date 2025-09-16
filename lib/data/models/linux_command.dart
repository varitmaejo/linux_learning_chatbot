import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'linux_command.g.dart';

enum CommandDifficulty {
  beginner,
  intermediate,
  advanced,
  expert
}

enum CommandCategory {
  fileSystem,
  textProcessing,
  systemInfo,
  network,
  process,
  permission,
  archive,
  search,
  ioRedirection,
  environment
}

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
  final CommandDifficulty difficulty;

  @HiveField(5)
  final CommandCategory category;

  @HiveField(6)
  final List<CommandExample> examples;

  @HiveField(7)
  final List<CommandParameter> parameters;

  @HiveField(8)
  final List<String> relatedCommands;

  @HiveField(9)
  final List<String> tags;

  @HiveField(10)
  final String? manualUrl;

  @HiveField(11)
  final String? videoUrl;

  @HiveField(12)
  final int usageCount;

  @HiveField(13)
  final double averageRating;

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
  final DateTime updatedAt;

  @HiveField(16)
  final List<String>? prerequisites;

  @HiveField(17)
  final String? warningMessage;

  @HiveField(18)
  final bool isDestructive;

  @HiveField(19)
  final Map<String, dynamic>? metadata;

  const LinuxCommand({
    required this.id,
    required this.name,
    required this.description,
    required this.syntax,
    required this.difficulty,
    required this.category,
    required this.examples,
    required this.parameters,
    required this.relatedCommands,
    required this.tags,
    this.manualUrl,
    this.videoUrl,
    this.usageCount = 0,
    this.averageRating = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.prerequisites,
    this.warningMessage,
    this.isDestructive = false,
    this.metadata,
  });

  // Factory constructor from Map (Firebase)
  factory LinuxCommand.fromMap(Map<String, dynamic> map) {
    return LinuxCommand(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      syntax: map['syntax'] ?? '',
      difficulty: CommandDifficulty.values.firstWhere(
            (e) => e.toString() == 'CommandDifficulty.${map['difficulty']}',
        orElse: () => CommandDifficulty.beginner,
      ),
      category: CommandCategory.values.firstWhere(
            (e) => e.toString() == 'CommandCategory.${map['category']}',
        orElse: () => CommandCategory.fileSystem,
      ),
      examples: (map['examples'] as List?)
          ?.map((e) => CommandExample.fromMap(Map<String, dynamic>.from(e)))
          .toList() ?? [],
      parameters: (map['parameters'] as List?)
          ?.map((e) => CommandParameter.fromMap(Map<String, dynamic>.from(e)))
          .toList() ?? [],
      relatedCommands: List<String>.from(map['relatedCommands'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      manualUrl: map['manualUrl'],
      videoUrl: map['videoUrl'],
      usageCount: map['usageCount'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      prerequisites: map['prerequisites'] != null
          ? List<String>.from(map['prerequisites'])
          : null,
      warningMessage: map['warningMessage'],
      isDestructive: map['isDestructive'] ?? false,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  // Convert to Map (Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'syntax': syntax,
      'difficulty': difficulty.toString().split('.').last,
      'category': category.toString().split('.').last,
      'examples': examples.map((e) => e.toMap()).toList(),
      'parameters': parameters.map((e) => e.toMap()).toList(),
      'relatedCommands': relatedCommands,
      'tags': tags,
      'manualUrl': manualUrl,
      'videoUrl': videoUrl,
      'usageCount': usageCount,
      'averageRating': averageRating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'prerequisites': prerequisites,
      'warningMessage': warningMessage,
      'isDestructive': isDestructive,
      'metadata': metadata,
    };
  }

  // Copy with method
  LinuxCommand copyWith({
    String? id,
    String? name,
    String? description,
    String? syntax,
    CommandDifficulty? difficulty,
    CommandCategory? category,
    List<CommandExample>? examples,
    List<CommandParameter>? parameters,
    List<String>? relatedCommands,
    List<String>? tags,
    String? manualUrl,
    String? videoUrl,
    int? usageCount,
    double? averageRating,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? prerequisites,
    String? warningMessage,
    bool? isDestructive,
    Map<String, dynamic>? metadata,
  }) {
    return LinuxCommand(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      syntax: syntax ?? this.syntax,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      examples: examples ?? this.examples,
      parameters: parameters ?? this.parameters,
      relatedCommands: relatedCommands ?? this.relatedCommands,
      tags: tags ?? this.tags,
      manualUrl: manualUrl ?? this.manualUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      usageCount: usageCount ?? this.usageCount,
      averageRating: averageRating ?? this.averageRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      prerequisites: prerequisites ?? this.prerequisites,
      warningMessage: warningMessage ?? this.warningMessage,
      isDestructive: isDestructive ?? this.isDestructive,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  String get difficultyDisplayText {
    switch (difficulty) {
      case CommandDifficulty.beginner:
        return 'ง่าย';
      case CommandDifficulty.intermediate:
        return 'ปานกลาง';
      case CommandDifficulty.advanced:
        return 'ยาก';
      case CommandDifficulty.expert:
        return 'ผู้เชี่ยวชาญ';
    }
  }

  String get categoryDisplayText {
    switch (category) {
      case CommandCategory.fileSystem:
        return 'ระบบไฟล์';
      case CommandCategory.textProcessing:
        return 'ประมวลผลข้อความ';
      case CommandCategory.systemInfo:
        return 'ข้อมูลระบบ';
      case CommandCategory.network:
        return 'เครือข่าย';
      case CommandCategory.process:
        return 'โปรเซส';
      case CommandCategory.permission:
        return 'สิทธิ์การเข้าถึง';
      case CommandCategory.archive:
        return 'บีบอัดและแตกไฟล์';
      case CommandCategory.search:
        return 'ค้นหา';
      case CommandCategory.ioRedirection:
        return 'เปลี่ยนทิศทาง I/O';
      case CommandCategory.environment:
        return 'สภาพแวดล้อม';
    }
  }

  String get categoryIcon {
    switch (category) {
      case CommandCategory.fileSystem:
        return '📁';
      case CommandCategory.textProcessing:
        return '📄';
      case CommandCategory.systemInfo:
        return '💻';
      case CommandCategory.network:
        return '🌐';
      case CommandCategory.process:
        return '⚙️';
      case CommandCategory.permission:
        return '🔐';
      case CommandCategory.archive:
        return '📦';
      case CommandCategory.search:
        return '🔍';
      case CommandCategory.ioRedirection:
        return '↗️';
      case CommandCategory.environment:
        return '🌿';
    }
  }

  bool get hasExamples => examples.isNotEmpty;
  bool get hasParameters => parameters.isNotEmpty;
  bool get hasRelatedCommands => relatedCommands.isNotEmpty;
  bool get hasPrerequisites => prerequisites != null && prerequisites!.isNotEmpty;
  bool get hasWarning => warningMessage != null && warningMessage!.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    syntax,
    difficulty,
    category,
    examples,
    parameters,
    relatedCommands,
    tags,
    manualUrl,
    videoUrl,
    usageCount,
    averageRating,
    createdAt,
    updatedAt,
    prerequisites,
    warningMessage,
    isDestructive,
    metadata,
  ];
}

@HiveType(typeId: 5)
class CommandExample extends Equatable {
  @HiveField(0)
  final String command;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final String? expectedOutput;

  @HiveField(3)
  final String? explanation;

  @HiveField(4)
  final bool isInteractive;

  @HiveField(5)
  final List<String>? prerequisites;

  const CommandExample({
    required this.command,
    required this.description,
    this.expectedOutput,
    this.explanation,
    this.isInteractive = false,
    this.prerequisites,
  });

  factory CommandExample.fromMap(Map<String, dynamic> map) {
    return CommandExample(
      command: map['command'] ?? '',
      description: map['description'] ?? '',
      expectedOutput: map['expectedOutput'],
      explanation: map['explanation'],
      isInteractive: map['isInteractive'] ?? false,
      prerequisites: map['prerequisites'] != null
          ? List<String>.from(map['prerequisites'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'command': command,
      'description': description,
      'expectedOutput': expectedOutput,
      'explanation': explanation,
      'isInteractive': isInteractive,
      'prerequisites': prerequisites,
    };
  }

  @override
  List<Object?> get props => [
    command,
    description,
    expectedOutput,
    explanation,
    isInteractive,
    prerequisites,
  ];
}

@HiveType(typeId: 6)
class CommandParameter extends Equatable {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String shortForm;

  @HiveField(2)
  final String longForm;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final bool isRequired;

  @HiveField(5)
  final String? defaultValue;

  @HiveField(6)
  final List<String>? validValues;

  @HiveField(7)
  final String? example;

  const CommandParameter({
    required this.name,
    required this.shortForm,
    required this.longForm,
    required this.description,
    this.isRequired = false,
    this.defaultValue,
    this.validValues,
    this.example,
  });

  factory CommandParameter.fromMap(Map<String, dynamic> map) {
    return CommandParameter(
      name: map['name'] ?? '',
      shortForm: map['shortForm'] ?? '',
      longForm: map['longForm'] ?? '',
      description: map['description'] ?? '',
      isRequired: map['isRequired'] ?? false,
      defaultValue: map['defaultValue'],
      validValues: map['validValues'] != null
          ? List<String>.from(map['validValues'])
          : null,
      example: map['example'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shortForm': shortForm,
      'longForm': longForm,
      'description': description,
      'isRequired': isRequired,
      'defaultValue': defaultValue,
      'validValues': validValues,
      'example': example,
    };
  }

  @override
  List<Object?> get props => [
    name,
    shortForm,
    longForm,
    description,
    isRequired,
    defaultValue,
    validValues,
    example,
  ];
}