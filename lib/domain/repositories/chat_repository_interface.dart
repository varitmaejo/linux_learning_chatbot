import '../entities/message.dart';

abstract class ChatRepositoryInterface {
  // Chat History Management
  Future<List<Message>> getChatHistory(String userId, {int limit = 50});
  Future<void> saveChatHistory(String userId, List<Message> messages);
  Future<void> clearChatHistory(String userId);

  // Message Operations
  Future<Message> sendMessage({
    required String text,
    required String userId,
    required String sessionId,
    MessageType type = MessageType.text,
    Map<String, dynamic>? context,
  });

  Future<Message> sendCommand({
    required String command,
    required String userId,
    required String sessionId,
    Map<String, dynamic>? context,
  });

  Future<Message> sendVoiceMessage({
    required String transcribedText,
    required String userId,
    required String sessionId,
    required String audioUrl,
    double? confidence,
  });

  // Search & Filter
  Future<List<Message>> searchMessages(String userId, String query);
  Future<List<Message>> getMessagesByType(String userId, MessageType type);
  Future<List<Message>> getMessagesByDateRange(
      String userId,
      DateTime startDate,
      DateTime endDate,
      );

  // Learning Sessions
  Future<Message> startLearningSession({
    required String userId,
    required String sessionId,
    required String skillLevel,
    List<String>? interestedCategories,
  });

  Future<Message> askForHelp({
    required String topic,
    required String userId,
    required String sessionId,
    String? currentLevel,
  });

  Future<Message> requestPractice({
    required String userId,
    required String sessionId,
    String? category,
    String? difficulty,
    int? questionCount,
  });

  Future<Message> submitQuizAnswer({
    required String answer,
    required String userId,
    required String sessionId,
    required String questionId,
    bool? isCorrect,
  });

  Future<Message> getPersonalizedSuggestions({
    required String userId,
    required String sessionId,
    required Map<String, dynamic> userProgress,
  });

  // Analytics & Data
  Future<Map<String, dynamic>> getChatAnalytics(String userId);
  Future<Map<String, dynamic>> exportChatData(String userId);

  // Real-time & Sync
  Stream<List<Message>> getChatStream(String userId, {int limit = 20});
  Future<void> syncChatHistory(String userId);

  // Utility
  Future<bool> isConnected();
  Future<void> cleanup();
}