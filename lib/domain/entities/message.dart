abstract class Message {
  const Message();

  String get id;
  String get text;
  bool get isFromUser;
  DateTime get timestamp;
  MessageType get messageType;
  List<String>? get quickReplies;
  List<String>? get commandSuggestions;
  Map<String, dynamic>? get metadata;
  String? get imageUrl;
  String? get audioUrl;
  bool get isRead;
  String? get replyToId;

  // Helper methods
  bool get hasQuickReplies => quickReplies != null && quickReplies!.isNotEmpty;
  bool get hasCommandSuggestions => commandSuggestions != null && commandSuggestions!.isNotEmpty;
  bool get hasMetadata => metadata != null && metadata!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
  bool get isReply => replyToId != null;
}

enum MessageType {
  text,
  command,
  voice,
  image,
  system,
  error,
}