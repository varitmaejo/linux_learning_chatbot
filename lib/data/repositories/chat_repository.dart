import 'dart:async';

import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository_interface.dart';
import '../models/chat_message.dart';
import '../datasources/local/hive_datasource.dart';
import '../datasources/remote/firebase_datasource.dart';
import '../datasources/remote/dialogflow_datasource.dart';

class ChatRepository implements ChatRepositoryInterface {
  final HiveDatasource _localDataSource;
  final FirebaseDatasource _remoteDataSource;
  final DialogflowDatasource _aiDataSource;

  ChatRepository({
    required HiveDatasource localDataSource,
    required FirebaseDatasource remoteDataSource,
    required DialogflowDatasource aiDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _aiDataSource = aiDataSource;

  @override
  Future<List<Message>> getChatHistory(String userId, {int limit = 50}) async {
    try {
      // Try to get from local first
      final localHistory = await _localDataSource.getChatHistory(userId);

      if (localHistory.isNotEmpty) {
        return localHistory.take(limit).toList();
      }

      // If local is empty and we're connected, try remote
      if (_remoteDataSource.isAuthenticated) {
        final remoteHistory = await _remoteDataSource.getChatHistory(userId, limit: limit);

        // Cache the remote history locally
        if (remoteHistory.isNotEmpty) {
          await _localDataSource.saveChatHistory(userId, remoteHistory);
        }

        return remoteHistory;
      }

      return [];
    } catch (error) {
      throw Exception('Failed to get chat history: $error');
    }
  }

  @override
  Future<void> saveChatHistory(String userId, List<Message> messages) async {
    try {
      // Save to local storage
      await _localDataSource.saveChatHistory(userId, messages);

      // Save to remote if connected
      if (_remoteDataSource.isAuthenticated) {
        try {
          // Save only recent messages to remote to avoid quota issues
          final recentMessages = messages.take(20).toList();
          for (final message in recentMessages) {
            await _remoteDataSource.saveChatMessage(message);
          }
        } catch (remoteError) {
          print('Warning: Failed to save to remote: $remoteError');
        }
      }
    } catch (error) {
      throw Exception('Failed to save chat history: $error');
    }
  }

  @override
  Future<Message> sendMessage({
    required String text,
    required String userId,
    required String sessionId,
    MessageType type = MessageType.text,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Create user message
      final userMessage = ChatMessage.userText(text: text);

      // Add user message to history immediately
      await _localDataSource.addChatMessage(userId, userMessage);

      // Send to AI and get response
      final aiResponse = await _sendToAI(
        text: text,
        sessionId: sessionId,
        messageType: type,
        context: context,
      );

      // Create AI response message
      final aiMessage = ChatMessage.botText(
        text: aiResponse.text,
        quickReplies: aiResponse.quickReplies,
        commandSuggestions: aiResponse.commandSuggestions,
        metadata: {
          'intent': aiResponse.intent,
          'confidence': aiResponse.confidence,
          'sessionId': aiResponse.sessionId,
          'responseTime': DateTime.now().millisecondsSinceEpoch,
          ...?aiResponse.metadata,
        },
      );

      // Add AI response to history
      await _localDataSource.addChatMessage(userId, aiMessage);

      // Save to remote if connected
      if (_remoteDataSource.isAuthenticated) {
        try {
          await _remoteDataSource.saveChatMessage(userMessage);
          await _remoteDataSource.saveChatMessage(aiMessage);
        } catch (remoteError) {
          print('Warning: Failed to save messages to remote: $remoteError');
        }
      }

      return aiMessage;
    } catch (error) {
      // Create error message
      final errorMessage = ChatMessage.errorMessage(
        text: 'ขออภัยครับ เกิดข้อผิดพลาดในการส่งข้อความ กรุณาลองใหม่อีกครั้ง',
        errorDetails: {
          'originalText': text,
          'errorType': 'send_message_error',
          'error': error.toString(),
        },
      );

      await _localDataSource.addChatMessage(userId, errorMessage);
      return errorMessage;
    }
  }

  @override
  Future<Message> sendCommand({
    required String command,
    required String userId,
    required String sessionId,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Process command through AI with Linux context
      final aiResponse = await _aiDataSource.queryLinuxCommand(
        command: command,
        sessionId: sessionId,
        userContext: context,
      );

      // Create command message
      final commandMessage = ChatMessage.commandMessage(
        command: command,
        output: aiResponse.text,
        isError: aiResponse.confidence < 0.5,
      );

      // Add to chat history
      await _localDataSource.addChatMessage(userId, commandMessage);

      // Create AI explanation message
      final explanationMessage = ChatMessage.botText(
        text: aiResponse.text,
        commandSuggestions: aiResponse.commandSuggestions,
        metadata: {
          'commandExplanation': true,
          'originalCommand': command,
          'confidence': aiResponse.confidence,
          'intent': aiResponse.intent,
        },
      );

      await _localDataSource.addChatMessage(userId, explanationMessage);

      // Save to remote
      if (_remoteDataSource.isAuthenticated) {
        try {
          await _remoteDataSource.saveChatMessage(commandMessage);
          await _remoteDataSource.saveChatMessage(explanationMessage);
        } catch (remoteError) {
          print('Warning: Failed to save command to remote: $remoteError');
        }
      }

      return explanationMessage;
    } catch (error) {
      throw Exception('Failed to send command: $error');
    }
  }

  @override
  Future<Message> sendVoiceMessage({
    required String transcribedText,
    required String userId,
    required String sessionId,
    required String audioUrl,
    double? confidence,
  }) async {
    try {
      // Create voice message
      final voiceMessage = ChatMessage.voiceMessage(
        text: transcribedText,
        audioUrl: audioUrl,
      );

      // Add to history
      await _localDataSource.addChatMessage(userId, voiceMessage);

      // Process through AI
      final aiResponse = await _aiDataSource.processVoiceInput(
        transcribedText: transcribedText,
        sessionId: sessionId,
        confidence: confidence,
        voiceMetadata: {
          'audioUrl': audioUrl,
          'transcriptionConfidence': confidence,
        },
      );

      // Create AI response
      final responseMessage = ChatMessage.botText(
        text: aiResponse.text,
        quickReplies: aiResponse.quickReplies,
        commandSuggestions: aiResponse.commandSuggestions,
        metadata: {
          'voiceResponse': true,
          'originalAudioUrl': audioUrl,
          'transcriptionConfidence': confidence,
          'responseConfidence': aiResponse.confidence,
        },
      );

      await _localDataSource.addChatMessage(userId, responseMessage);

      return responseMessage;
    } catch (error) {
      throw Exception('Failed to send voice message: $error');
    }
  }

  @override
  Future<void> clearChatHistory(String userId) async {
    try {
      // Clear from local storage
      await _localDataSource.clearChatHistory(userId);

      // Clear from remote
      if (_remoteDataSource.isAuthenticated) {
        try {
          await _remoteDataSource.clearChatHistory(userId);
        } catch (remoteError) {
          print('Warning: Failed to clear remote chat history: $remoteError');
        }
      }

      // Clear DialogFlow session
      try {
        await _aiDataSource.clearSession('session_$userId');
      } catch (aiError) {
        print('Warning: Failed to clear AI session: $aiError');
      }
    } catch (error) {
      throw Exception('Failed to clear chat history: $error');
    }
  }

  @override
  Future<List<Message>> searchMessages(String userId, String query) async {
    try {
      final allMessages = await getChatHistory(userId, limit: 1000);

      final lowercaseQuery = query.toLowerCase();
      return allMessages.where((message) {
        return message.text.toLowerCase().contains(lowercaseQuery) ||
            (message.metadata != null &&
                message.metadata.toString().toLowerCase().contains(lowercaseQuery));
      }).toList();
    } catch (error) {
      throw Exception('Failed to search messages: $error');
    }
  }

  @override
  Future<List<Message>> getMessagesByType(String userId, MessageType type) async {
    try {
      final allMessages = await getChatHistory(userId, limit: 1000);
      return allMessages.where((message) => message.messageType == type).toList();
    } catch (error) {
      throw Exception('Failed to get messages by type: $error');
    }
  }

  @override
  Future<List<Message>> getMessagesByDateRange(
      String userId,
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final allMessages = await getChatHistory(userId, limit: 1000);
      return allMessages.where((message) {
        return message.timestamp.isAfter(startDate) &&
            message.timestamp.isBefore(endDate);
      }).toList();
    } catch (error) {
      throw Exception('Failed to get messages by date range: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> getChatAnalytics(String userId) async {
    try {
      final allMessages = await getChatHistory(userId, limit: 1000);

      if (allMessages.isEmpty) {
        return {
          'totalMessages': 0,
          'userMessages': 0,
          'botMessages': 0,
          'commandMessages': 0,
          'voiceMessages': 0,
          'averageResponseTime': 0.0,
          'sessionDuration': 0,
          'mostUsedCommands': <String>[],
          'chatFrequency': <String, int>{},
        };
      }

      final userMessages = allMessages.where((m) => m.isFromUser).length;
      final botMessages = allMessages.where((m) => !m.isFromUser).length;
      final commandMessages = allMessages.where((m) => m.messageType == MessageType.command).length;
      final voiceMessages = allMessages.where((m) => m.messageType == MessageType.voice).length;

      // Calculate session duration
      final firstMessage = allMessages.last;
      final lastMessage = allMessages.first;
      final sessionDuration = lastMessage.timestamp.difference(firstMessage.timestamp);

      // Calculate average response time
      double totalResponseTime = 0;
      int responseCount = 0;

      for (int i = 0; i < allMessages.length - 1; i++) {
        final current = allMessages[i];
        final next = allMessages[i + 1];

        if (!current.isFromUser && next.isFromUser) {
          final responseTime = next.timestamp.difference(current.timestamp);
          totalResponseTime += responseTime.inMilliseconds;
          responseCount++;
        }
      }

      final averageResponseTime = responseCount > 0
          ? totalResponseTime / responseCount / 1000 // Convert to seconds
          : 0.0;

      // Find most used commands
      final commandFrequency = <String, int>{};
      for (final message in allMessages) {
        if (message.messageType == MessageType.command) {
          final command = message.text.split(' ').first;
          commandFrequency[command] = (commandFrequency[command] ?? 0) + 1;
        }
      }

      final mostUsedCommands = commandFrequency.entries
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(10);

      // Chat frequency by day
      final chatFrequency = <String, int>{};
      for (final message in allMessages) {
        final dateKey = '${message.timestamp.year}-${message.timestamp.month}-${message.timestamp.day}';
        chatFrequency[dateKey] = (chatFrequency[dateKey] ?? 0) + 1;
      }

      return {
        'totalMessages': allMessages.length,
        'userMessages': userMessages,
        'botMessages': botMessages,
        'commandMessages': commandMessages,
        'voiceMessages': voiceMessages,
        'averageResponseTime': averageResponseTime,
        'sessionDuration': sessionDuration.inMinutes,
        'mostUsedCommands': mostUsedCommands.map((e) => e.key).toList(),
        'chatFrequency': chatFrequency,
        'analysisDate': DateTime.now().toIso8601String(),
      };
    } catch (error) {
      throw Exception('Failed to get chat analytics: $error');
    }
  }

  @override
  Future<Message> startLearningSession({
    required String userId,
    required String sessionId,
    required String skillLevel,
    List<String>? interestedCategories,
  }) async {
    try {
      // Start AI learning session
      final aiResponse = await _aiDataSource.startLearningSession(
        sessionId: sessionId,
        skillLevel: skillLevel,
        interestedCategories: interestedCategories,
      );

      // Create session start message
      final sessionMessage = ChatMessage.systemMessage(
        text: aiResponse.text,
        type: MessageType.system,
      );

      await _localDataSource.addChatMessage(userId, sessionMessage);

      return sessionMessage;
    } catch (error) {
      throw Exception('Failed to start learning session: $error');
    }
  }

  @override
  Future<Message> askForHelp({
    required String topic,
    required String userId,
    required String sessionId,
    String? currentLevel,
  }) async {
    try {
      // Get help from AI
      final aiResponse = await _aiDataSource.askForHelp(
        topic: topic,
        sessionId: sessionId,
        currentLevel: currentLevel,
      );

      // Create user help request message
      final helpRequestMessage = ChatMessage.userText(
        text: 'ขอความช่วยเหลือเกี่ยวกับ $topic',
      );

      await _localDataSource.addChatMessage(userId, helpRequestMessage);

      // Create AI help response
      final helpResponseMessage = ChatMessage.botText(
        text: aiResponse.text,
        quickReplies: aiResponse.quickReplies,
        commandSuggestions: aiResponse.commandSuggestions,
        metadata: {
          'helpTopic': topic,
          'currentLevel': currentLevel,
          'helpResponse': true,
        },
      );

      await _localDataSource.addChatMessage(userId, helpResponseMessage);

      return helpResponseMessage;
    } catch (error) {
      throw Exception('Failed to ask for help: $error');
    }
  }

  @override
  Future<Message> requestPractice({
    required String userId,
    required String sessionId,
    String? category,
    String? difficulty,
    int? questionCount,
  }) async {
    try {
      // Request practice from AI
      final aiResponse = await _aiDataSource.requestPractice(
        sessionId: sessionId,
        category: category,
        difficulty: difficulty,
        questionCount: questionCount,
      );

      // Create practice request message
      final practiceMessage = ChatMessage.botText(
        text: aiResponse.text,
        quickReplies: aiResponse.quickReplies,
        metadata: {
          'practiceSession': true,
          'category': category,
          'difficulty': difficulty,
          'questionCount': questionCount,
        },
      );

      await _localDataSource.addChatMessage(userId, practiceMessage);

      return practiceMessage;
    } catch (error) {
      throw Exception('Failed to request practice: $error');
    }
  }

  @override
  Future<Message> submitQuizAnswer({
    required String answer,
    required String userId,
    required String sessionId,
    required String questionId,
    bool? isCorrect,
  }) async {
    try {
      // Create user answer message
      final answerMessage = ChatMessage.userText(text: answer);
      await _localDataSource.addChatMessage(userId, answerMessage);

      // Submit to AI for evaluation
      final aiResponse = await _aiDataSource.submitQuizAnswer(
        answer: answer,
        sessionId: sessionId,
        questionId: questionId,
        isCorrect: isCorrect,
      );

      // Create AI feedback message
      final feedbackMessage = ChatMessage.botText(
        text: aiResponse.text,
        quickReplies: aiResponse.quickReplies,
        metadata: {
          'quizFeedback': true,
          'questionId': questionId,
          'userAnswer': answer,
          'isCorrect': isCorrect,
          'confidence': aiResponse.confidence,
        },
      );

      await _localDataSource.addChatMessage(userId, feedbackMessage);

      return feedbackMessage;
    } catch (error) {
      throw Exception('Failed to submit quiz answer: $error');
    }
  }

  @override
  Future<Message> getPersonalizedSuggestions({
    required String userId,
    required String sessionId,
    required Map<String, dynamic> userProgress,
  }) async {
    try {
      // Get current user progress and learning data
      final chatHistory = await getChatHistory(userId, limit: 50);
      final completedLessons = userProgress['completedLessons'] as List<String>? ?? [];
      final categoryScores = userProgress['categoryProgress'] as Map<String, int>? ?? {};

      // Get personalized suggestions from AI
      final aiResponse = await _aiDataSource.getPersonalizedSuggestions(
        sessionId: sessionId,
        userProgress: userProgress,
        completedLessons: completedLessons,
        categoryScores: categoryScores,
      );

      // Create suggestions message
      final suggestionsMessage = ChatMessage.botText(
        text: aiResponse.text,
        quickReplies: aiResponse.quickReplies,
        commandSuggestions: aiResponse.commandSuggestions,
        metadata: {
          'personalizedSuggestions': true,
          'basedOnProgress': userProgress,
          'suggestionTime': DateTime.now().toIso8601String(),
        },
      );

      await _localDataSource.addChatMessage(userId, suggestionsMessage);

      return suggestionsMessage;
    } catch (error) {
      throw Exception('Failed to get personalized suggestions: $error');
    }
  }

  @override
  Stream<List<Message>> getChatStream(String userId, {int limit = 20}) {
    // Return Firebase real-time stream if connected
    if (_remoteDataSource.isAuthenticated) {
      return _remoteDataSource.getChatStream(userId, limit: limit);
    } else {
      // For local-only, return a single emission of current history
      return Stream.fromFuture(getChatHistory(userId, limit: limit));
    }
  }

  @override
  Future<void> syncChatHistory(String userId) async {
    try {
      if (!_remoteDataSource.isAuthenticated) {
        throw Exception('Not authenticated');
      }

      // Get local and remote histories
      final localHistory = await _localDataSource.getChatHistory(userId);
      final remoteHistory = await _remoteDataSource.getChatHistory(userId, limit: 100);

      // Merge histories (prefer remote for conflicts)
      final mergedHistory = <String, Message>{};

      // Add local messages
      for (final message in localHistory) {
        mergedHistory[message.id] = message;
      }

      // Add/override with remote messages
      for (final message in remoteHistory) {
        mergedHistory[message.id] = message;
      }

      // Sort by timestamp and save
      final sortedMessages = mergedHistory.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Save merged history locally
      await _localDataSource.saveChatHistory(userId, sortedMessages);

    } catch (error) {
      throw Exception('Failed to sync chat history: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> exportChatData(String userId) async {
    try {
      final chatHistory = await getChatHistory(userId, limit: 1000);
      final analytics = await getChatAnalytics(userId);

      return {
        'userId': userId,
        'chatHistory': chatHistory.map((m) => (m as ChatMessage).toJson()).toList(),
        'analytics': analytics,
        'exportedAt': DateTime.now().toIso8601String(),
        'totalMessages': chatHistory.length,
      };
    } catch (error) {
      throw Exception('Failed to export chat data: $error');
    }
  }

  // Private helper methods
  Future<DialogFlowResponse> _sendToAI({
    required String text,
    required String sessionId,
    MessageType messageType = MessageType.text,
    Map<String, dynamic>? context,
  }) async {
    try {
      switch (messageType) {
        case MessageType.command:
          return await _aiDataSource.queryLinuxCommand(
            command: text,
            sessionId: sessionId,
            userContext: context,
          );
        case MessageType.voice:
          return await _aiDataSource.processVoiceInput(
            transcribedText: text,
            sessionId: sessionId,
            voiceMetadata: context,
          );
        default:
          return await _aiDataSource.sendMessageWithRetry(
            text: text,
            sessionId: sessionId,
            context: context,
          );
      }
    } catch (error) {
      // Return fallback response if AI fails
      return _aiDataSource.getFallbackResponse(text, sessionId);
    }
  }

  @override
  Future<bool> isConnected() async {
    return await _remoteDataSource.checkConnection() &&
        await _aiDataSource.checkConnection();
  }

  @override
  Future<void> cleanup() async {
    try {
      // Clean up old local chat data
      // This would typically be called by a background service
      final cutoffDate = DateTime.now().subtract(Duration(days: 30));

      // Implementation would clean up messages older than cutoff date
      // Left as placeholder for now
    } catch (error) {
      print('Warning: Failed to cleanup chat data: $error');
    }
  }
}