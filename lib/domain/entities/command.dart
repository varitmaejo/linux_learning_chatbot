class Command {
  final String id;
  final String name;
  final String description;
  final String syntax;
  final List<String> examples;
  final String category;
  final String difficulty;
  final List<CommandOption> options;
  final List<String> tags;
  final bool isInteractive;
  final bool requiresSudo;
  final String manualUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Command({
    required this.id,
    required this.name,
    required this.description,
    required this.syntax,
    required this.examples,
    required this.category,
    required this.difficulty,
    required this.options,
    required this.tags,
    required this.isInteractive,
    required this.requiresSudo,
    required this.manualUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Command copyWith({
    String? id,
    String? name,
    String? description,
    String? syntax,
    List<String>? examples,
    String? category,
    String? difficulty,
    List<CommandOption>? options,
    List<String>? tags,
    bool? isInteractive,
    bool? requiresSudo,
    String? manualUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Command(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      syntax: syntax ?? this.syntax,
      examples: examples ?? this.examples,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      options: options ?? this.options,
      tags: tags ?? this.tags,
      isInteractive: isInteractive ?? this.isInteractive,
      requiresSudo: requiresSudo ?? this.requiresSudo,
      manualUrl: manualUrl ?? this.manualUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Command &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.syntax == syntax;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    name.hashCode ^
    description.hashCode ^
    syntax.hashCode;
  }

  @override
  String toString() {
    return 'Command(id: $id, name: $name, description: $description, syntax: $syntax)';
  }
}

class CommandOption {
  final String name;
  final String shortForm;
  final String description;
  final bool required;
  final String? defaultValue;

  const CommandOption({
    required this.name,
    required this.shortForm,
    required this.description,
    required this.required,
    this.defaultValue,
  });

  CommandOption copyWith({
    String? name,
    String? shortForm,
    String? description,
    bool? required,
    String? defaultValue,
  }) {
    return CommandOption(
      name: name ?? this.name,
      shortForm: shortForm ?? this.shortForm,
      description: description ?? this.description,
      required: required ?? this.required,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CommandOption &&
        other.name == name &&
        other.shortForm == shortForm &&
        other.description == description &&
        other.required == required &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode {
    return name.hashCode ^
    shortForm.hashCode ^
    description.hashCode ^
    required.hashCode ^
    defaultValue.hashCode;
  }

  @override
  String toString() {
    return 'CommandOption(name: $name, shortForm: $shortForm, description: $description, required: $required, defaultValue: $defaultValue)';
  }
}