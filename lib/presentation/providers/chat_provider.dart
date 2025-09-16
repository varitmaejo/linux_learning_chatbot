import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/dialogflow_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/analytics_service.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/user_model.dart';
import '../../data/models/linux_command.dart';

enum ChatState {
  idle,
  loading,
  typing,
  error
}

class ChatProvider extends ChangeNotifier {
  final DialogflowService _dialogflowService = DialogflowService.instance;
  final FirebaseService _firebaseService = FirebaseService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  // State
  ChatState _state = ChatState.idle;
  List<ChatMessage> _messages = [];
  UserModel? _currentUser;
  String? _sessionId;
  String? _errorMessage;
  bool _isTyping = false;

  // Getters
  ChatState get state => _state;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  UserModel? get currentUser => _currentUser;
  String? get sessionId => _sessionId;
  String? get errorMessage => _errorMessage;
  bool get isTyping => _isTyping;
  bool get hasMessages => _messages.isNotEmpty;

  /// Initialize chat provider
  Future<void> initialize(String? userId) async {
    try {
      if (userId != null) {
        _sessionId = 'chat_${userId}_${DateTime.now().millisecondsSinceEpoch}';
        await _loadChatHistory(userId);
      }
    } catch (e) {
      _setError('Failed to initialize chat: ${e.toString()}');
    }
  }

  /// Update current user
  void updateUser(UserModel? user) {
    _currentUser = user;
    if (user != null && _sessionId == null) {
      initialize(user.id);
    }
    notifyListeners();
  }

  /// Send message
  Future<void> sendMessage(String text, {MessageType type = MessageType.text}) async {
    if (text.trim().isEmpty) return;

    try {
      _setState(ChatState.loading);
      _setTyping(true);

      // Create user message
      final userMessage = ChatMessage(
        id: const Uuid().v4(),
        text: text.trim(),
        isUser: true,
        timestamp: DateTime.now(),
        messageType: type,
        userId: _currentUser?.id,
        sessionId: _sessionId,
      );

      // Add user message
      _addMessage(userMessage);
      await _saveChatMessage(userMessage);

      // Log analytics
      await _analyticsService.logEvent('chat_message_sent', parameters: {
        'message_type': type.name,
        'message_length': text.length,
        'session_id': _sessionId ?? 'unknown',
      });

      // Process message based on type
      switch (type) {
        case MessageType.text:
          await _handleTextMessage(text);
          break;
        case MessageType.linuxCommand:
          await _handleLinuxCommand(text);
          break;
        case MessageType.voice:
          await _handleVoiceMessage(text);
          break;
        default:
          await _handleGeneralQuery(text);
      }

    } catch (e) {
      _setError('Failed to send message: ${e.toString()}');
    } finally {
      _setTyping(false);
      _setState(ChatState.idle);
    }
  }

  /// Handle text message
  Future<void> _handleTextMessage(String text) async {
    try {
      // Check if it's a command query
      if (_isLinuxCommandQuery(text)) {
        await _handleLinuxCommand(_extractCommandFromQuery(text));
        return;
      }

      // Check if it's a learning path request
      if (_isLearningPathQuery(text)) {
        await _handleLearningPathRequest(text);
        return;
      }

      // Check if it's a quiz request
      if (_isQuizQuery(text)) {
        await _handleQuizRequest(text);
        return;
      }

      // General Dialogflow query
      await _handleGeneralQuery(text);

    } catch (e) {
      await _handleError(e.toString());
    }
  }

  /// Handle Linux command
  Future<void> _handleLinuxCommand(String command) async {
    try {
      // Get command explanation from Dialogflow
      final response = await _dialogflowService.explainCommand(command);

      final botMessage = ChatMessage(
        id: const Uuid().v4(),
        text: response.explanation,
        isUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.linuxCommand,
        metadata: {
          'command': command,
          'examples': response.examples,
          'relatedCommands': response.relatedCommands,
          'tips': response.tips,
        },
        userId: _currentUser?.id,
        sessionId: _sessionId,
      );

      _addMessage(botMessage);
      await _saveChatMessage(botMessage);

      // Log command explanation
      await _analyticsService.logCommandExecution(
        command: command,
        category: 'explanation',
        successful: !response.isError,
        source: 'chat',
      );

    } catch (e) {
      await _handleError('ขออภัย ไม่สามารถอธิบายคำสั่งนี้ได้');
    }
  }

  /// Handle voice message
  Future<void> _handleVoiceMessage(String transcribedText) async {
    // Process voice message same as text but with different analytics
    await _analyticsService.logVoiceInteraction(
      action: 'speech_recognized',
      language: 'th-TH',
      confidence: 0.8,
    );

    await _handleTextMessage(transcribedText);
  }

  /// Handle learning path request
  Future<void> _handleLearningPathRequest(String query) async {
    try {
      final userProgress = await _getCurrentUserProgress();

      final response = await _dialogflowService.generateLearningPath(
        currentLevel: userProgress['difficulty'] ?? 'beginner',
        completedCommands: List<String>.from(userProgress['completedCommands'] ?? []),
      );

      final pathMessage = ChatMessage(
        id: const Uuid().v4(),
        text: response.explanation,
        isUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.learningPath,
        metadata: {
          'recommendedCommands': response.recommendedCommands,
          'nextTopic': response.nextTopic,
          'difficulty': response.difficulty,
        },
        userId: _currentUser?.id,
        sessionId: _sessionId,
      );

      _addMessage(pathMessage);
      await _saveChatMessage(pathMessage);

    } catch (e) {
      await _handleError('ไม่สามารถสร้างเส้นทางการเรียนรู้ได้');
    }
  }

  /// Handle quiz request
  Future<void> _handleQuizRequest(String query) async {
    try {
      final userProgress = await _getCurrentUserProgress();
      final topic = _extractTopicFromQuery(query);

      final quiz = await _dialogflowService.generateQuiz(
        topic: topic,
        difficulty: userProgress['difficulty'] ?? 'beginner',
      );

      final quizMessage = ChatMessage(
        id: const Uuid().v4(),
        text: 'แบบทดสอบเรื่อง $topic พร้อมแล้ว!',
        isUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.quiz,
        metadata: {
          'quiz': {
            'topic': quiz.topic,
            'difficulty': quiz.difficulty,
            'questions': quiz.questions.map((q) => {
              'id': q.id,
              'question': q.question,
              'options': q.options,
              'correctAnswer': q.correctAnswer,
              'explanation': q.explanation,
            }).toList(),
            'timeLimit': quiz.timeLimit,
          }
        },
        quickReplies: ['เริ่มทำแบบทดสอบ', 'ข้ามไปก่อน'],
        userId: _currentUser?.id,
        sessionId: _sessionId,
      );

      _addMessage(quizMessage);
      await _saveChatMessage(quizMessage);

      // Log quiz generation
      await _analyticsService.logQuizStart(
        topic: quiz.topic,
        difficulty: quiz.difficulty,
        questionCount: quiz.questions.length,
      );

    } catch (e) {
      await _handleError('ไม่สามารถสร้างแบบทดสอบได้');
    }
  }

  /// Handle general query
  Future<void> _handleGeneralQuery(String query) async {
    try {
      final response = await _dialogflowService.detectIntent(query);

      final botMessage = ChatMessage(
        id: const Uuid().v4(),
        text: response.fulfillmentText,
        isUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.text,
        confidence: response.confidence,
        metadata: {
          'intentName': response.intentName,
          'parameters': response.parameters,
        },
        userId: _currentUser?.id,
        sessionId: _sessionId,
      );

      _addMessage(botMessage);
      await _saveChatMessage(botMessage);

      // Add quick replies if available
      final quickReplies = _generateQuickReplies(response.intentName);
      if (quickReplies.isNotEmpty) {
        final quickReplyMessage = botMessage.copyWith(
          quickReplies: quickReplies,
        );
        _updateMessage(botMessage.id, quickReplyMessage);
      }

    } catch (e) {
      await _handleError('ขออภัย ไม่เข้าใจคำถามของคุณ');
    }
  }

  /// Handle error
  Future<void> _handleError(String errorMessage) async {
    final errorMsg = ChatMessage(
      id: const Uuid().v4(),
      text: errorMessage,
      isUser: false,
      timestamp: DateTime.now(),
      messageType: MessageType.error,
      userId: _currentUser?.id,
      sessionId: _sessionId,
    );

    _addMessage(errorMsg);
    await _saveChatMessage(errorMsg);
  }

  /// Get current user progress
  Future<Map<String, dynamic>> _getCurrentUserProgress() async {
    if (_currentUser == null) {
      return {'difficulty': 'beginner', 'completedCommands': []};
    }

    // This would typically come from ProgressProvider
    return {
      'difficulty': _currentUser!.preferences.difficultyLevel,
      'completedCommands': [], // Get from progress provider
    };
  }

  /// Query analysis methods
  bool _isLinuxCommandQuery(String text) {
    final commandKeywords = ['คำสั่ง', 'command', 'อธิบาย', 'explain', 'ใช้ยังไง'];
    return commandKeywords.any((keyword) =>
        text.toLowerCase().contains(keyword.toLowerCase()));
  }

  bool _isLearningPathQuery(String text) {
    final pathKeywords = ['เส้นทาง', 'แนะนำ', 'เรียนอะไรต่อ', 'หัวข้อถัดไป'];
    return pathKeywords.any((keyword) =>
        text.toLowerCase().contains(keyword.toLowerCase()));
  }

  bool _isQuizQuery(String text) {
    final quizKeywords = ['แบบทดสอบ', 'ทดสอบ', 'สอบ', 'quiz', 'test'];
    return quizKeywords.any((keyword) =>
        text.toLowerCase().contains(keyword.toLowerCase()));
  }

  String _extractCommandFromQuery(String text) {
    // Simple extraction - in production, use more sophisticated NLP
    final words = text.split(' ');
    for (final word in words) {
      if (word.length > 1 && !_isThaiWord(word)) {
        return word;
      }
    }
    return text;
  }

  String _extractTopicFromQuery(String text) {
    // Extract topic from quiz query
    if (text.contains('ระบบไฟล์')) return 'ระบบไฟล์';
    if (text.contains('เครือข่าย')) return 'เครือข่าย';
    if (text.contains('สิทธิ์')) return 'สิทธิ์การเข้าถึง';
    return 'พื้นฐาน';
  }

  bool _isThaiWord(String word) {
    return RegExp(r'[\u0E00-\u0E7F]').hasMatch(word);
  }

  /// Generate quick replies based on intent
  List<String> _generateQuickReplies(String intentName) {
    switch (intentName) {
      case 'command.explain':
        return ['ยกตัวอย่างให้หน่อย', 'คำสั่งที่เกี่ยวข้อง', 'ฝึกใช้คำสั่งนี้'];
      case 'help.general':
        return ['เรียนรู้คำสั่งพื้นฐาน', 'ทดสอบความรู้', 'แนะนำหัวข้อ'];
      case 'learning.path':
        return ['เริ่มเรียนเลย', 'ดูตัวอย่างคำสั่ง', 'ทำแบบทดสอบ'];
      default:
        return ['ต้องการความช่วยเหลือ', 'คำสั่งที่น่าสนใจ', 'เรียนต่อ'];
    }
  }

  /// Message management
  void _addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void _updateMessage(String messageId, ChatMessage updatedMessage) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = updatedMessage;
      notifyListeners();
    }
  }

  void removeMessage(String messageId) {
    _messages.removeWhere((message) => message.id == messageId);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  /// Mark message as favorite
  void toggleFavorite(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = _messages[index];
      _messages[index] = message.copyWith(isFavorite: !message.isFavorite);
      notifyListeners();

      // Save to Firebase
      if (_currentUser != null) {
        _saveChatMessage(_messages[index]);
      }
    }
  }

  /// Mark messages as read
  void markMessagesAsRead() {
    bool hasChanges = false;
    for (int i = 0; i < _messages.length; i++) {
      if (!_messages[i].isRead && !_messages[i].isUser) {
        _messages[i] = _messages[i].copyWith(isRead: true);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  /// Save chat message to Firebase
  Future<void> _saveChatMessage(ChatMessage message) async {
    if (_currentUser == null) return;

    try {
      await _firebaseService.saveChatMessage(
        _currentUser!.id,
        message.toMap(),
      );
    } catch (e) {
      print('Error saving chat message: $e');
    }
  }

  /// Load chat history
  Future<void> _loadChatHistory(String userId) async {
    try {
      final messagesStream = _firebaseService.getChatMessages(userId);

      messagesStream.listen((snapshot) {
        final messages = snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        _messages = messages;
        notifyListeners();
      });

    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  /// State management
  void _setState(ChatState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void _setTyping(bool typing) {
    if (_isTyping != typing) {
      _isTyping = typing;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(ChatState.error);
  }

  void clearError() {
    _errorMessage = null;
    if (_state == ChatState.error) {
      _setState(ChatState.idle);
    }
  }

  /// Get unread message count
  int get unreadCount {
    return _messages.where((m) => !m.isRead && !m.isUser).length;
  }

  /// Get favorite messages
  List<ChatMessage> get favoriteMessages {
    return _messages.where((m) => m.isFavorite).toList();
  }

  /// Search messages
  List<ChatMessage> searchMessages(String query) {
    if (query.trim().isEmpty) return _messages;

    return _messages.where((message) =>
        message.text.toLowerCase().contains(query.toLowerCase())).toList();
  }

  /// Get messages by type
  List<ChatMessage> getMessagesByType(MessageType type) {
    return _messages.where((m) => m.messageType == type).toList();
  }

  @override
  void dispose() {
    // Clean up any streams or subscriptions
    super.dispose();
  }
}