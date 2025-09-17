import '../entities/message.dart';

abstract class ChatRepositoryInterface {
  /// Send a message and get response
  Future<Message> sendMessage(Message message);

  /// Get chat history for a specific session
  Future<List<Message>> getChatHistory({
    required String sessionId,
    int limit = 50,
    String? lastMessageId,
  });

  /// Get all chat sessions for a user
  Future<List<ChatSession>> getChatSessions({
    required String userId,
    int limit = 20,
  });

  /// Create a new chat session
  Future<ChatSession> createChatSession({
    required String userId,
    String? title,
    Map<String, dynamic>? metadata,
  });

  /// Update chat session
  Future<ChatSession> updateChatSession({
    required String sessionId,
    String? title,
    Map<String, dynamic>? metadata,
  });

  /// Delete a chat session
  Future<void> deleteChatSession(String sessionId);

  /// Delete a specific message
  Future<void> deleteMessage(String messageId);

  /// Update message status
  Future<Message> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  });

  /// Search messages
  Future<List<Message>> searchMessages({
    required String query,
    String? sessionId,
    String? userId,
    MessageType? type,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get message by ID
  Future<Message?> getMessageById(String messageId);

  /// Save message to local storage
  Future<void> saveMessageLocally(Message message);

  /// Sync messages with remote server
  Future<void> syncMessages({
    required String sessionId,
    DateTime? lastSyncDate,
  });

  /// Stream real-time messages for a session
  Stream<Message> streamMessages(String sessionId);

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String sessionId,
    required List<String> messageIds,
  });

  /// Get unread message count
  Future<int> getUnreadMessageCount({
    required String userId,
    String? sessionId,
  });

  /// Export chat history
  Future<String> exportChatHistory({
    required String sessionId,
    String format = 'json', // json, csv, txt
  });

  /// Clear chat history
  Future<void> clearChatHistory({
    required String sessionId,
    bool keepMetadata = true,
  });
}

class ChatSession {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final int messageCount;
  final int unreadCount;
  final Map<String, dynamic> metadata;
  final bool isArchived;
  final bool isPinned;
  final List<String> tags;

  const ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    required this.messageCount,
    required this.unreadCount,
    required this.metadata,
    required this.isArchived,
    required this.isPinned,
    required this.tags,
  });

  ChatSession copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    int? messageCount,
    int? unreadCount,
    Map<String, dynamic>? metadata,
    bool? isArchived,
    bool? isPinned,
    List<String>? tags,
  }) {
    return ChatSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messageCount: messageCount ?? this.messageCount,
      unreadCount: unreadCount ?? this.unreadCount,
      metadata: metadata ?? this.metadata,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
    );
  }

  bool get hasUnreadMessages => unreadCount > 0;
  bool get isEmpty => messageCount == 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatSession &&
        other.id == id &&
        other.userId == userId &&
        other.title == title;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ title.hashCode;
  }

  @override
  String toString() {
    return 'ChatSession(id: $id, userId: $userId, title: $title, messageCount: $messageCount, unreadCount: $unreadCount)';
  }
}