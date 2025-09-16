import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/message.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class ChatMessage extends Message {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String text;

  @HiveField(2)
  @override
  final bool isFromUser;

  @HiveField(3)
  @override
  final DateTime timestamp;

  @HiveField(4)
  @override
  final MessageType messageType;

  @HiveField(5)
  @override
  final List<String>? quickReplies;

  @HiveField(6)
  @override
  final List<String>? commandSuggestions;

  @HiveField(7)
  @override
  final Map<String, dynamic>? metadata;

  @HiveField(8)
  @override
  final String? imageUrl;

  @HiveField(9)
  @override
  final String? audioUrl;

  @HiveField(10)
  @override
  final bool isRead;

  @HiveField(11)
  @override
  final String? replyToId;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    required this.messageType,
    this.quickReplies,
    this.commandSuggestions,
    this.metadata,
    this.imageUrl,
    this.audioUrl,
    this.isRead = true,
    this.replyToId,
  });

  // JSON serialization
  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  // From domain entity
  factory ChatMessage.fromEntity(Message message) {
    return ChatMessage(
      id: message.id,
      text: message.text,
      isFromUser: message.isFromUser,
      timestamp: message.timestamp,
      messageType: message.messageType,
      quickReplies: message.quickReplies,
      commandSuggestions: message.commandSuggestions,
      metadata: message.metadata,
      imageUrl: message.imageUrl,
      audioUrl: message.audioUrl,
      isRead: message.isRead,
      replyToId: message.replyToId,
    );
  }

  // Factory constructors for different message types
  factory ChatMessage.userText({
    required String text,
    String? replyToId,
  }) {
    return ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isFromUser: true,
      timestamp: DateTime.now(),
      messageType: MessageType.text,
      replyToId: replyToId,
    );
  }

  factory ChatMessage.botText({
    required String text,
    List<String>? quickReplies,
    List<String>? commandSuggestions,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: MessageType.text,
      quickReplies: quickReplies,
      commandSuggestions: commandSuggestions,
      metadata: metadata,
    );
  }

  factory ChatMessage.commandMessage({
    required String command,
    required String output,
    bool isError = false,
  }) {
    return ChatMessage(
      id: 'cmd_${DateTime.now().millisecondsSinceEpoch}',
      text: command,
      isFromUser: true,
      timestamp: DateTime.now(),
      messageType: MessageType.command,
      metadata: {
        'output': output,
        'isError': isError,
        'executedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  factory ChatMessage.voiceMessage({
    required String text,
    required String audioUrl,
  }) {
    return ChatMessage(
      id: 'voice_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isFromUser: true,
      timestamp: DateTime.now(),
      messageType: MessageType.voice,
      audioUrl: audioUrl,
    );
  }

  factory ChatMessage.imageMessage({
    required String text,
    required String imageUrl,
  }) {
    return ChatMessage(
      id: 'img_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isFromUser: true,
      timestamp: DateTime.now(),
      messageType: MessageType.image,
      imageUrl: imageUrl,
    );
  }

  factory ChatMessage.systemMessage({
    required String text,
    MessageType type = MessageType.system,
  }) {
    return ChatMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: type,
    );
  }

  factory ChatMessage.errorMessage({
    required String text,
    Map<String, dynamic>? errorDetails,
  }) {
    return ChatMessage(
      id: 'err_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: MessageType.error,
      metadata: errorDetails,
    );
  }

  // Copy with method
  ChatMessage copyWith({
    String? text,
    bool? isRead,
    List<String>? quickReplies,
    List<String>? commandSuggestions,
    Map<String, dynamic>? metadata,
    String? imageUrl,
    String? audioUrl,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isFromUser: isFromUser,
      timestamp: timestamp,
      messageType: messageType,
      quickReplies: quickReplies ?? this.quickReplies,
      commandSuggestions: commandSuggestions ?? this.commandSuggestions,
      metadata: metadata ?? this.metadata,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      isRead: isRead ?? this.isRead,
      replyToId: replyToId,
    );
  }

  // Helper methods
  bool get hasQuickReplies => quickReplies != null && quickReplies!.isNotEmpty;
  bool get hasCommandSuggestions => commandSuggestions != null && commandSuggestions!.isNotEmpty;
  bool get hasMetadata => metadata != null && metadata!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
  bool get isReply => replyToId != null;

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

  String get messageTypeDisplayName {
    switch (messageType) {
      case MessageType.text:
        return 'ข้อความ';
      case MessageType.command:
        return 'คำสั่ง';
      case MessageType.voice:
        return 'เสียง';
      case MessageType.image:
        return 'รูปภาพ';
      case MessageType.system:
        return 'ระบบ';
      case MessageType.error:
        return 'ข้อผิดพลาด';
      default:
        return 'ไม่ระบุ';
    }
  }

  // Get command output from metadata
  String? get commandOutput {
    if (messageType == MessageType.command && metadata != null) {
      return metadata!['output'] as String?;
    }
    return null;
  }

  // Check if command resulted in error
  bool get isCommandError {
    if (messageType == MessageType.command && metadata != null) {
      return metadata!['isError'] as bool? ?? false;
    }
    return false;
  }

  // Get response time (for bot messages)
  Duration? get responseTime {
    if (metadata != null && metadata!.containsKey('responseTime')) {
      final ms = metadata!['responseTime'] as int?;
      return ms != null ? Duration(milliseconds: ms) : null;
    }
    return null;
  }

  // Check if message contains learning content
  bool get hasLearningContent {
    return metadata != null &&
        (metadata!.containsKey('commandInfo') ||
            metadata!.containsKey('lessonId') ||
            metadata!.containsKey('quizId'));
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, type: $messageType, isFromUser: $isFromUser, text: ${text.length > 50 ? text.substring(0, 50) + '...' : text})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Hive Adapter for MessageType enum
@HiveType(typeId: 4)
enum MessageType {
  @HiveField(0)
  text,

  @HiveField(1)
  command,

  @HiveField(2)
  voice,

  @HiveField(3)
  image,

  @HiveField(4)
  system,

  @HiveField(5)
  error,
}