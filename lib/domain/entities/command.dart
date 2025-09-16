abstract class Command {
  const Command();

  String get id;
  String get name;
  String get description;
  String get usage;
  String get category;
  String get difficulty;
  List<String> get tags;
  List<String> get examples;
  List<String> get relatedCommands;
  Map<String, dynamic> get metadata;
  DateTime get createdAt;
  DateTime get updatedAt;

  // Helper methods
  bool get isBasic => difficulty.toLowerCase() == 'beginner';
  bool get isAdvanced => difficulty.toLowerCase() == 'advanced' || difficulty.toLowerCase() == 'expert';
  bool get isPopular => (metadata['popularityScore'] as num? ?? 0) > 70;
  bool get hasExamples => examples.isNotEmpty;

  String get difficultyDisplayName {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 'เริ่มต้น';
      case 'intermediate':
        return 'กลาง';
      case 'advanced':
        return 'ขั้นสูง';
      case 'expert':
        return 'ผู้เชี่ยวชาญ';
      default:
        return 'ไม่ระบุ';
    }
  }

  String get categoryDisplayName {
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
}