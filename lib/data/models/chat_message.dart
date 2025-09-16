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

@HiveType(typeId: 3)
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

  @HiveField(14)
  final String? userId;

  @HiveField(15)
  final String? sessionId;

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
    this.userId,
    this.sessionId,
  });

  // Factory constructor from Map (Firebase)
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageType: MessageType.values.firstWhere(
            (e) => e.toString() == 'MessageType.${map['messageType']}',
        orElse: () => MessageType.text,
      ),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      imageUrl: map['imageUrl'],
      fileUrl: map['fileUrl'],
      isRead: map['isRead'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
      replyToMessageId: map['replyToMessageId'],
      confidence: map['confidence']?.toDouble(),
      quickReplies: map['quickReplies'] != null
          ? List<String>.from(map['quickReplies'])
          : null,
      voiceDuration: map['voiceDurationMs'] != null
          ? Duration(milliseconds: map['voiceDurationMs'])
          : null,
      userId: map['userId'],
      sessionId: map['sessionId'],
    );
  }

  // Convert to Map (Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'messageType': messageType.toString().split('.').last,
      'metadata': metadata,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'isRead': isRead,
      'isFavorite': isFavorite,
      'replyToMessageId': replyToMessageId,
      'confidence': confidence,
      'quickReplies': quickReplies,
      'voiceDurationMs': voiceDuration?.inMilliseconds,
      'userId': userId,
      'sessionId': sessionId,
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
    String? userId,
    String? sessionId,
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
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  // Helper methods
  bool get hasMetadata => metadata != null && metadata!.isNotEmpty;
  bool get hasQuickReplies => quickReplies != null && quickReplies!.isNotEmpty;
  bool get hasMedia => imageUrl != null || fileUrl != null;
  bool get isVoiceMessage => messageType == MessageType.voice;
  bool get isCommandMessage => messageType == MessageType.linuxCommand;
  bool get isQuizMessage => messageType == MessageType.quiz;
  bool get isSystemMessage => messageType == MessageType.system;

  // Get command name from metadata for linux command messages
  String? get commandName {
    if (messageType == MessageType.linuxCommand && hasMetadata) {
      return metadata!['commandName'] as String?;
    }
    return null;
  }

  // Get quiz data from metadata
  Map<String, dynamic>? get quizData {
    if ((messageType == MessageType.quiz || messageType == MessageType.quizResult) && hasMetadata) {
      return metadata!['quiz'] as Map<String, dynamic>?;
    }
    return null;
  }

  // Get learning path data from metadata
  List<String>? get recommendedCommands {
    if (messageType == MessageType.learningPath && hasMetadata) {
      return (metadata!['recommendedCommands'] as List?)?.cast<String>();
    }
    return null;
  }

  // Get voice transcription confidence
  double get voiceConfidence => confidence ?? 0.0;

  // Check if message needs user attention
  bool get needsAttention {
    return !isRead && !isUser;
  }

  // Format timestamp for display
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'เมื่อกี้นี้';
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

  // Get message type display text
  String get messageTypeDisplayText {
    switch (messageType) {
      case MessageType.text:
        return 'ข้อความ';
      case MessageType.voice:
        return 'เสียง';
      case MessageType.linuxCommand:
        return 'คำสั่ง Linux';
      case MessageType.quiz:
        return 'แบบทดสอบ';
      case MessageType.quizResult:
        return 'ผลแบบทดสอบ';
      case MessageType.learningPath:
        return 'เส้นทางการเรียน';
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
    userId,
    sessionId,
  ];

  @override
  String toString() {
    return 'ChatMessage(id: $id, text: $text, isUser: $isUser, messageType: $messageType)';
  }
}

// Extension for MessageType
extension MessageTypeExtension on MessageType {
  String get name {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.voice:
        return 'voice';
      case MessageType.linuxCommand:
        return 'linuxCommand';
      case MessageType.quiz:
        return 'quiz';
      case MessageType.quizResult:
        return 'quizResult';
      case MessageType.learningPath:
        return 'learningPath';
      case MessageType.suggestions:
        return 'suggestions';
      case MessageType.error:
        return 'error';
      case MessageType.system:
        return 'system';
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
    }
  }

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
          (e) => e.name == value,
      orElse: () => MessageType.text,
    );
  }
}