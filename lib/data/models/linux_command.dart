import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/command.dart';

part 'linux_command.g.dart';

@JsonSerializable()
class LinuxCommand extends Command {
  @override
  final String id;

  @override
  final String name;

  @override
  final String description;

  @override
  final String usage;

  @override
  final String category;

  @override
  final String difficulty;

  @override
  final List<String> tags;

  @override
  final List<String> examples;

  @override
  final List<String> relatedCommands;

  @override
  final Map<String, dynamic> metadata;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  // Additional Linux-specific properties
  final String? manPage;
  final List<String> options;
  final List<String> parameters;
  final String? syntax;
  final List<Map<String, String>> commonUseCases;
  final List<String> warnings;
  final String? shortDescription;
  final bool requiresRoot;
  final List<String> supportedShells;

  const LinuxCommand({
    required this.id,
    required this.name,
    required this.description,
    required this.usage,
    required this.category,
    required this.difficulty,
    required this.tags,
    required this.examples,
    required this.relatedCommands,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.manPage,
    required this.options,
    required this.parameters,
    this.syntax,
    required this.commonUseCases,
    required this.warnings,
    this.shortDescription,
    required this.requiresRoot,
    required this.supportedShells,
  });

  // JSON serialization
  factory LinuxCommand.fromJson(Map<String, dynamic> json) =>
      _$LinuxCommandFromJson(json);

  Map<String, dynamic> toJson() => _$LinuxCommandToJson(this);

  // From domain entity
  factory LinuxCommand.fromEntity(Command command) {
    return LinuxCommand(
      id: command.id,
      name: command.name,
      description: command.description,
      usage: command.usage,
      category: command.category,
      difficulty: command.difficulty,
      tags: command.tags,
      examples: command.examples,
      relatedCommands: command.relatedCommands,
      metadata: command.metadata,
      createdAt: command.createdAt,
      updatedAt: command.updatedAt,
      manPage: command.metadata['manPage'] as String?,
      options: (command.metadata['options'] as List?)?.cast<String>() ?? [],
      parameters: (command.metadata['parameters'] as List?)?.cast<String>() ?? [],
      syntax: command.metadata['syntax'] as String?,
      commonUseCases: (command.metadata['commonUseCases'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((case) => case.cast<String, String>())
          .toList() ?? [],
      warnings: (command.metadata['warnings'] as List?)?.cast<String>() ?? [],
      shortDescription: command.metadata['shortDescription'] as String?,
      requiresRoot: command.metadata['requiresRoot'] as bool? ?? false,
      supportedShells: (command.metadata['supportedShells'] as List?)?.cast<String>() ?? ['bash'],
    );
  }

  // Factory constructors for common Linux commands
  factory LinuxCommand.ls() {
    return LinuxCommand(
      id: 'cmd_ls',
      name: 'ls',
      description: 'แสดงรายการไฟล์และโฟลเดอร์ในไดเรกทอรี',
      shortDescription: 'แสดงรายการไฟล์',
      usage: 'ls [options] [directory]',
      syntax: 'ls [-alFd] [path]',
      category: 'file_management',
      difficulty: 'beginner',
      tags: ['file', 'directory', 'list', 'basic', 'essential'],
      examples: [
        'ls',
        'ls -l',
        'ls -la',
        'ls -lh /home',
        'ls *.txt',
      ],
      options: [
        '-l: แสดงรายละเอียดแบบยาว',
        '-a: แสดงไฟล์ที่ซ่อนด้วย',
        '-h: แสดงขนาดไฟล์ในรูปแบบที่อ่านง่าย',
        '-t: เรียงตามเวลาแก้ไข',
        '-r: เรียงแบบย้อนกลับ',
      ],
      parameters: ['directory: ไดเรกทอรีที่ต้องการแสดง (ไม่บังคับ)'],
      relatedCommands: ['dir', 'find', 'tree', 'stat'],
      commonUseCases: [
        {'case': 'แสดงไฟล์ทั้งหมดรวมทั้งที่ซ่อน', 'command': 'ls -la'},
        {'case': 'แสดงขนาดไฟล์ในรูปแบบที่อ่านง่าย', 'command': 'ls -lh'},
        {'case': 'เรียงไฟล์ตามเวลาแก้ไข', 'command': 'ls -lt'},
      ],
      warnings: [],
      requiresRoot: false,
      supportedShells: ['bash', 'zsh', 'sh', 'fish'],
      metadata: {
        'popularityScore': 95,
        'learningPriority': 1,
        'manPageUrl': 'https://man7.org/linux/man-pages/man1/ls.1.html',
        'tutorialLevel': 'basic',
        'estimatedLearningTime': 15, // minutes
      },
      createdAt: DateTime(2023, 1, 1),
      updatedAt: DateTime.now(),
    );
  }

  factory LinuxCommand.cd() {
    return LinuxCommand(
      id: 'cmd_cd',
      name: 'cd',
      description: 'เปลี่ยนไดเรกทอรีปัจจุบัน (Change Directory)',
      shortDescription: 'เปลี่ยนไดเรกทอรี',
      usage: 'cd [directory]',
      syntax: 'cd [path]',
      category: 'file_management',
      difficulty: 'beginner',
      tags: ['directory', 'navigation', 'basic', 'essential'],
      examples: [
        'cd',
        'cd ~',
        'cd ..',
        'cd /home/user',
        'cd Documents',
        'cd -',
      ],
      options: [],
      parameters: ['directory: ไดเรกทอรีปลายทางที่ต้องการไป (ไม่บังคับ)'],
      relatedCommands: ['pwd', 'ls', 'mkdir', 'rmdir'],
      commonUseCases: [
        {'case': 'กลับไป home directory', 'command': 'cd ~'},
        {'case': 'ย้อนกลับไปไดเรกทอรีก่อนหน้า', 'command': 'cd ..'},
        {'case': 'กลับไปไดเรกทอรีที่เพิ่งอยู่', 'command': 'cd -'},
      ],
      warnings: [],
      requiresRoot: false,
      supportedShells: ['bash', 'zsh', 'sh', 'fish'],
      metadata: {
        'popularityScore': 98,
        'learningPriority': 1,
        'builtin': true,
        'tutorialLevel': 'basic',
        'estimatedLearningTime': 10,
      },
      createdAt: DateTime(2023, 1, 1),
      updatedAt: DateTime.now(),
    );
  }

  factory LinuxCommand.grep() {
    return LinuxCommand(
      id: 'cmd_grep',
      name: 'grep',
      description: 'ค้นหาข้อความในไฟล์โดยใช้ regular expression',
      shortDescription: 'ค้นหาข้อความ',
      usage: 'grep [options] pattern [file...]',
      syntax: 'grep [-inrvE] "pattern" file',
      category: 'text_processing',
      difficulty: 'intermediate',
      tags: ['search', 'text', 'regex', 'filter', 'important'],
      examples: [
        'grep "hello" file.txt',
        'grep -i "error" log.txt',
        'grep -r "TODO" .',
        'grep -n "function" *.js',
        'ps aux | grep apache',
      ],
      options: [
        '-i: ไม่สนใจตัวพิมพ์เล็กใหญ่',
        '-n: แสดงหมายเลขบรรทัด',
        '-r: ค้นหาแบบ recursive',
        '-v: แสดงบรรทัดที่ไม่ตรงกับ pattern',
        '-E: ใช้ extended regex',
        '-l: แสดงเฉพาะชื่อไฟล์ที่พบ',
        '-c: นับจำนวนบรรทัดที่พบ',
      ],
      parameters: [
        'pattern: รูปแบบข้อความที่ต้องการค้นหา',
        'file: ไฟล์ที่ต้องการค้นหา (ไม่บังคับ)',
      ],
      relatedCommands: ['egrep', 'fgrep', 'sed', 'awk', 'find'],
      commonUseCases: [
        {'case': 'ค้นหาข้อความไม่สนใจตัวพิมพ์', 'command': 'grep -i "error" log.txt'},
        {'case': 'ค้นหาในทุกไฟล์ในโฟลเดอร์', 'command': 'grep -r "TODO" .'},
        {'case': 'ค้นหาพร้อมแสดงหมายเลขบรรทัด', 'command': 'grep -n "function" *.js'},
      ],
      warnings: [
        'ระวังการใช้ regex ที่ซับซ้อนเกินไปอาจทำให้ช้า',
        'ใช้ quotes เพื่อป้องกัน shell interpretation',
      ],
      requiresRoot: false,
      supportedShells: ['bash', 'zsh', 'sh', 'fish'],
      metadata: {
        'popularityScore': 85,
        'learningPriority': 3,
        'complexityLevel': 'medium',
        'tutorialLevel': 'intermediate',
        'estimatedLearningTime': 30,
        'regexSupport': true,
      },
      createdAt: DateTime(2023, 1, 1),
      updatedAt: DateTime.now(),
    );
  }

  factory LinuxCommand.sudo() {
    return LinuxCommand(
      id: 'cmd_sudo',
      name: 'sudo',
      description: 'รันคำสั่งด้วยสิทธิ์ของผู้ใช้อื่น (มักจะเป็น root)',
      shortDescription: 'รันคำสั่งด้วยสิทธิ์สูงสุด',
      usage: 'sudo [options] command',
      syntax: 'sudo [-u user] command',
      category: 'system_admin',
      difficulty: 'intermediate',
      tags: ['admin', 'privilege', 'security', 'root', 'important'],
      examples: [
        'sudo apt update',
        'sudo mkdir /etc/myconfig',
        'sudo -u www-data ls /var/www',
        'sudo !!',
        'sudo -s',
      ],
      options: [
        '-u: ระบุผู้ใช้ที่ต้องการรันคำสั่ง',
        '-s: เปิด shell ด้วยสิทธิ์ root',
        '-i: เปิด login shell',
        '-l: แสดงคำสั่งที่อนุญาตให้รัน',
        '-v: ขยายเวลา credential cache',
      ],
      parameters: [
        'user: ชื่อผู้ใช้ที่ต้องการสวมสิทธิ์ (default: root)',
        'command: คำสั่งที่ต้องการรัน',
      ],
      relatedCommands: ['su', 'visudo', 'whoami', 'id'],
      commonUseCases: [
        {'case': 'รันคำสั่งก่อนหน้าด้วย sudo', 'command': 'sudo !!'},
        {'case': 'เปิด root shell', 'command': 'sudo -s'},
        {'case': 'รันคำสั่งในฐานะผู้ใช้อื่น', 'command': 'sudo -u username command'},
      ],
      warnings: [
        'ระวังการใช้ sudo อาจเป็นอันตรายต่อระบบ',
        'อย่าแชร์รหัสผ่าน sudo กับใคร',
        'ตรวจสอบคำสั่งให้ดีก่อนรัน',
      ],
      requiresRoot: false,
      supportedShells: ['bash', 'zsh', 'sh', 'fish'],
      metadata: {
        'popularityScore': 90,
        'learningPriority': 4,
        'securitySensitive': true,
        'tutorialLevel': 'intermediate',
        'estimatedLearningTime': 25,
        'requiresConfiguration': true,
      },
      createdAt: DateTime(2023, 1, 1),
      updatedAt: DateTime.now(),
    );
  }

  // Copy with method
  LinuxCommand copyWith({
    String? description,
    String? usage,
    String? category,
    String? difficulty,
    List<String>? tags,
    List<String>? examples,
    List<String>? relatedCommands,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
    String? manPage,
    List<String>? options,
    List<String>? parameters,
    String? syntax,
    List<Map<String, String>>? commonUseCases,
    List<String>? warnings,
    String? shortDescription,
    bool? requiresRoot,
    List<String>? supportedShells,
  }) {
    return LinuxCommand(
      id: id,
      name: name,
      description: description ?? this.description,
      usage: usage ?? this.usage,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? List.from(this.tags),
      examples: examples ?? List.from(this.examples),
      relatedCommands: relatedCommands ?? List.from(this.relatedCommands),
      metadata: metadata ?? Map.from(this.metadata),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      manPage: manPage ?? this.manPage,
      options: options ?? List.from(this.options),
      parameters: parameters ?? List.from(this.parameters),
      syntax: syntax ?? this.syntax,
      commonUseCases: commonUseCases ?? List.from(this.commonUseCases),
      warnings: warnings ?? List.from(this.warnings),
      shortDescription: shortDescription ?? this.shortDescription,
      requiresRoot: requiresRoot ?? this.requiresRoot,
      supportedShells: supportedShells ?? List.from(this.supportedShells),
    );
  }

  // Helper methods
  bool hasOption(String option) => options.any((opt) => opt.startsWith(option));

  bool isInCategory(String categoryName) => category.toLowerCase() == categoryName.toLowerCase();

  bool matchesTag(String tag) => tags.any((t) => t.toLowerCase() == tag.toLowerCase());

  bool isSafeCommand() => !requiresRoot && !warnings.isNotEmpty;

  List<String> getFilteredExamples({String? difficulty}) {
    if (difficulty == null) return examples;

    // Filter examples based on difficulty
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return examples.take(3).toList();
      case 'intermediate':
        return examples.skip(1).take(4).toList();
      case 'advanced':
        return examples.skip(2).toList();
      default:
        return examples;
    }
  }

  Map<String, dynamic> getDisplayInfo() {
    return {
      'name': name,
      'shortDescription': shortDescription ?? description,
      'category': categoryDisplayName,
      'difficulty': difficultyDisplayName,
      'isPopular': isPopular,
      'requiresRoot': requiresRoot,
      'hasWarnings': warnings.isNotEmpty,
      'exampleCount': examples.length,
      'optionCount': options.length,
      'tags': tags,
    };
  }

  @override
  String toString() {
    return 'LinuxCommand(name: $name, category: $category, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LinuxCommand && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}