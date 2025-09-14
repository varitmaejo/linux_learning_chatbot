import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'chat_message.g.dart';

enum MessageType {
  text,
  voice,
  linuxCommand,
  quiz,
  quizResult,
  learningPath,
  suggestions,
  error,
  system,
  image,
  file
}

@HiveType(typeId: 1)
class ChatMessage extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final bool isUser;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final MessageType messageType;

  @HiveField(5)
  final Map<String, dynamic>? metadata;

  @HiveField(6)
  final String? imageUrl;

  @HiveField(7)
  final String? fileUrl;

  @HiveField(8)
  final bool isRead;

  @HiveField(9)
  final bool isFavorite;

  @HiveField(10)
  final String? replyToMessageId;

  @HiveField(11)
  final double? confidence;

  @HiveField(12)
  final List<String>? quickReplies;

  @HiveField(13)
  final Duration? voiceDuration;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.messageType = MessageType.text,
    this.metadata,
    this.imageUrl,
    this.fileUrl,
    this.isRead = false,
    this.isFavorite = false,
    this.replyToMessageId,
    this.confidence,
    this.quickReplies,
    this.voiceDuration,
  });

  // Factory constructor from Map (Firebase)
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageType: MessageType.values.firstWhere(
            (e) => e.toString() == map['messageType'],
        orElse: () => MessageType.text,
      ),
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
      imageUrl: map['imageUrl'],
      fileUrl: map['fileUrl'],
      isRead: map['isRead'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
      replyToMessageId: map['replyToMessageId'],
      confidence: map['confidence']?.toDouble(),
      quickReplies: map['quickReplies'] != null ? List<String>.from(map['quickReplies']) : null,
      voiceDuration: map['voiceDurationMs'] != null
          ? Duration(milliseconds: map['voiceDurationMs'])
          : null,
    );
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'messageType': messageType.toString(),
      'metadata': metadata,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'isRead': isRead,
      'isFavorite': isFavorite,
      'replyToMessageId': replyToMessageId,
      'confidence': confidence,
      'quickReplies': quickReplies,
      'voiceDurationMs': voiceDuration?.inMilliseconds,
    };
  }

  // JSON serialization (for local storage)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      messageType: MessageType.values.firstWhere(
            (e) => e.toString() == json['messageType'],
        orElse: () => MessageType.text,
      ),
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
      imageUrl: json['imageUrl'],
      fileUrl: json['fileUrl'],
      isRead: json['isRead'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      replyToMessageId: json['replyToMessageId'],
      confidence: json['confidence']?.toDouble(),
      quickReplies: json['quickReplies'] != null ? List<String>.from(json['quickReplies']) : null,
      voiceDuration: json['voiceDurationMs'] != null
          ? Duration(milliseconds: json['voiceDurationMs'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType.toString(),
      'metadata': metadata,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'isRead': isRead,
      'isFavorite': isFavorite,
      'replyToMessageId': replyToMessageId,
      'confidence': confidence,
      'quickReplies': quickReplies,
      'voiceDurationMs': voiceDuration?.inMilliseconds,
    };
  }

  // Copy with method
  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    MessageType? messageType,
    Map<String, dynamic>? metadata,
    String? imageUrl,
    String? fileUrl,
    bool? isRead,
    bool? isFavorite,
    String? replyToMessageId,
    double? confidence,
    List<String>? quickReplies,
    Duration? voiceDuration,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      isRead: isRead ?? this.isRead,
      isFavorite: isFavorite ?? this.isFavorite,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      confidence: confidence ?? this.confidence,
      quickReplies: quickReplies ?? this.quickReplies,
      voiceDuration: voiceDuration ?? this.voiceDuration,
    );
  }

  // Helper methods
  bool get hasMetadata => metadata != null && metadata!.isNotEmpty;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;

  bool get hasVoice => voiceDuration != null;

  bool get hasQuickReplies => quickReplies != null && quickReplies!.isNotEmpty;

  bool get isCommand => messageType == MessageType.linuxCommand;

  bool get isQuiz => messageType == MessageType.quiz;

  bool get isQuizResult => messageType == MessageType.quizResult;

  bool get isError => messageType == MessageType.error;

  bool get isSuggestion => messageType == MessageType.suggestions;

  bool get isSystemMessage => messageType == MessageType.system;

  // Get formatted timestamp
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // Get command details from metadata
  LinuxCommandDetails? get commandDetails {
    if (!isCommand || !hasMetadata) return null;

    return LinuxCommandDetails(
      name: metadata!['command'] ?? '',
      syntax: metadata!['syntax'] ?? '',
      description: text,
      examples: List<String>.from(metadata!['examples'] ?? []),
      options: List<String>.from(metadata!['options'] ?? []),
    );
  }

  // Get quiz details from metadata
  QuizDetails? get quizDetails {
    if (!isQuiz || !hasMetadata) return null;

    return QuizDetails(
      question: text,
      options: List<String>.from(metadata!['options'] ?? []),
      correctAnswer: metadata!['correctAnswer'] ?? '',
      explanation: metadata!['explanation'] ?? '',
      quizId: metadata!['quizId'] ?? '',
    );
  }

  // Get quiz result details from metadata
  QuizResultDetails? get quizResultDetails {
    if (!isQuizResult || !hasMetadata) return null;

    return QuizResultDetails(
      isCorrect: metadata!['isCorrect'] ?? false,
      correctAnswer: metadata!['correctAnswer'] ?? '',
      userAnswer: metadata!['userAnswer'] ?? '',
      explanation: text,
    );
  }

  // Get suggestions from metadata
  List<String> get suggestions {
    if (!isSuggestion || !hasMetadata) return [];
    return List<String>.from(metadata!['suggestions'] ?? []);
  }

  // Get learning path details from metadata
  LearningPathDetails? get learningPathDetails {
    if (messageType != MessageType.learningPath || !hasMetadata) return null;

    return LearningPathDetails(
      recommendedCommands: List<String>.from(metadata!['recommendedCommands'] ?? []),
      explanation: text,
      nextTopic: metadata!['nextTopic'] ?? '',
    );
  }

  // Check if message is from today
  bool get isFromToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  // Get confidence level as string
  String get confidenceLevel {
    if (confidence == null) return '';

    if (confidence! >= 0.8) return 'สูง';
    if (confidence! >= 0.6) return 'กลาง';
    if (confidence! >= 0.4) return 'ต่ำ';
    return 'ต่ำมาก';
  }

  @override
  List<Object?> get props => [
    id,
    text,
    isUser,
    timestamp,
    messageType,
    metadata,
    imageUrl,
    fileUrl,
    isRead,
    isFavorite,
    replyToMessageId,
    confidence,
    quickReplies,
    voiceDuration,
  ];
}

// Helper classes for message details
class LinuxCommandDetails {
  final String name;
  final String syntax;
  final String description;
  final List<String> examples;
  final List<String> options;

  const LinuxCommandDetails({
    required this.name,
    required this.syntax,
    required this.description,
    required this.examples,
    required this.options,
  });
}

class QuizDetails {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String quizId;

  const QuizDetails({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.quizId,
  });
}

class QuizResultDetails {
  final bool isCorrect;
  final String correctAnswer;
  final String userAnswer;
  final String explanation;

  const QuizResultDetails({
    required this.isCorrect,
    required this.correctAnswer,
    required this.userAnswer,
    required this.explanation,
  });
}

class LearningPathDetails {
  final List<String> recommendedCommands;
  final String explanation;
  final String nextTopic;

  const LearningPathDetails({
    required this.recommendedCommands,
    required this.explanation,
    required this.nextTopic,
  });
}

// Extension for message type display names
extension MessageTypeExtension on MessageType {
  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'ข้อความ';
      case MessageType.voice:
        return 'ข้อความเสียง';
      case MessageType.linuxCommand:
        return 'คำสั่ง Linux';
      case MessageType.quiz:
        return 'แบบทดสอบ';
      case MessageType.quizResult:
        return 'ผลการทดสอบ';
      case MessageType.learningPath:
        return 'เส้นทางการเรียนรู้';
      case MessageType.suggestions:
        return 'คำแนะนำ';
      case MessageType.error:
        return 'ข้อผิดพลาด';
      case MessageType.system:
        return 'ระบบ';
      case MessageType.image:
        return 'รูปภาพ';
      case MessageType.file:
        return 'ไฟล์';
    }
  }

  String get icon {
    switch (this) {
      case MessageType.text:
        return '💬';
      case MessageType.voice:
        return '🎤';
      case MessageType.linuxCommand:
        return '⚡';
      case MessageType.quiz:
        return '❓';
      case MessageType.quizResult:
        return '✅';
      case MessageType.learningPath:
        return '🗺️';
      case MessageType.suggestions:
        return '💡';
      case MessageType.error:
        return '❌';
      case MessageType.system:
        return '🔧';
      case MessageType.image:
        return '🖼️';
      case MessageType.file:
        return '📁';
    }
  }
}