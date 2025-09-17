enum MessageType {
  text,
  voice,
  command,
  image,
  file,
  system,
  error,
}

enum MessageSender {
  user,
  bot,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class Message {
  final String id;
  final String content;
  final MessageType type;
  final MessageSender sender;
  final MessageStatus status;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;
  final Map<String, dynamic> metadata;
  final List<String> attachments;
  final Message? replyTo;
  final bool isEdited;
  final DateTime? editedAt;
  final double? confidence;
  final String? language;

  const Message({
    required this.id,
    required this.content,
    required this.type,
    required this.sender,
    required this.status,
    required this.timestamp,
    this.userId,
    this.sessionId,
    required this.metadata,
    required this.attachments,
    this.replyTo,
    required this.isEdited,
    this.editedAt,
    this.confidence,
    this.language,
  });

  Message copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageSender? sender,
    MessageStatus? status,
    DateTime? timestamp,
    String? userId,
    String? sessionId,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
    Message? replyTo,
    bool? isEdited,
    DateTime? editedAt,
    double? confidence,
    String? language,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
      replyTo: replyTo ?? this.replyTo,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      confidence: confidence ?? this.confidence,
      language: language ?? this.language,
    );
  }

  bool get isFromUser => sender == MessageSender.user;
  bool get isFromBot => sender == MessageSender.bot;
  bool get isFromSystem => sender == MessageSender.system;

  bool get isPending => status == MessageStatus.sending;
  bool get isFailed => status == MessageStatus.failed;
  bool get isSuccess => status == MessageStatus.sent ||
      status == MessageStatus.delivered ||
      status == MessageStatus.read;

  bool get hasAttachments => attachments.isNotEmpty;
  bool get isReply => replyTo != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message &&
        other.id == id &&
        other.content == content &&
        other.type == type &&
        other.sender == sender &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    content.hashCode ^
    type.hashCode ^
    sender.hashCode ^
    timestamp.hashCode;
  }

  @override
  String toString() {
    return 'Message(id: $id, content: $content, type: $type, sender: $sender, status: $status, timestamp: $timestamp)';
  }
}