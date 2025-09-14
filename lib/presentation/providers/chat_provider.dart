import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/linux_command.dart';
import '../services/dialogflow_service.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';

class ChatProvider with ChangeNotifier {
  final DialogflowService _dialogflowService = DialogflowService.instance;
  final FirebaseService _firebaseService = FirebaseService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  // Chat state
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isInitialized = false;
  String _sessionId = '';
  String? _currentUserId;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isInitialized => _isInitialized;
  String get sessionId => _sessionId;

  // Initialize chat
  Future<void> initialize(String userId) async {
    try {
      _currentUserId = userId;
      _sessionId = 'session_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      // Initialize Dialogflow
      await _dialogflowService.initialize();

      // Load chat history from Firebase
      await _loadChatHistory();

      // Add welcome message if no previous messages
      if (_messages.isEmpty) {
        await _addWelcomeMessage();
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing chat: $e');
    }
  }

  // Load chat history from Firebase
  Future<void> _loadChatHistory() async {
    if (_currentUserId == null) return;

    try {
      final history = await _firebaseService.getChatHistory(_currentUserId!, limit: 50);
      _messages = history;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  // Add welcome message
  Future<void> _addWelcomeMessage() async {
    final welcomeMessage = ChatMessage(
      id: const Uuid().v4(),
      text: 'สวัสดีครับ! ผมคือ Linux Learning Assistant ที่จะช่วยคุณเรียนรู้คำสั่ง Linux อย่างสนุกสนาน 🐧\n\nคุณสามารถ:\n• ถามเกี่ยวกับคำสั่ง Linux ใดๆ\n• ขอให้อธิบายคำสั่งที่สนใจ\n• ทดสอบความรู้ด้วย Quiz\n• ใช้ Virtual Terminal\n\nเริ่มต้นได้เลย! คุณอยากรู้เรื่องอะไร?',
      isUser: false,
      timestamp: DateTime.now(),
      messageType: MessageType.text,
      metadata: {'isWelcome': true},
    );

    _messages.add(welcomeMessage);
    await _saveChatMessage(welcomeMessage);
    notifyListeners();
  }

  // Send message
  Future<void> sendMessage(String text, {MessageType type = MessageType.text}) async {
    if (text.trim().isEmpty || !_isInitialized) return;

    try {
      _isTyping = true;
      notifyListeners();

      // Create user message
      final userMessage = ChatMessage(
        id: const Uuid().v4(),
        text: text.trim(),
        isUser: true,
        timestamp: DateTime.now(),
        messageType: type,
      );

      // Add user message to list
      _messages.add(userMessage);
      await _saveChatMessage(userMessage);
      notifyListeners();

      // Get bot response
      await _getBotResponse(text, type);

      // Log analytics
      await _analyticsService.logEvent('chat_message_sent', {
        'message_type': type.toString(),
        'message_length': text.length,
        'session_id': _sessionId,
      });

    } catch (e) {
      debugPrint('Error sending message: $e');
      await _addErrorMessage('ขออภัย เกิดข้อผิดพลาดในการส่งข้อความ กรุณาลองใหม่อีกครั้ง');
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  // Get bot response from Dialogflow
  Future<void> _getBotResponse(String userMessage, MessageType messageType) async {
    try {
      // Determine response type based on message content
      if (_isLinuxCommandQuery(userMessage)) {
        await _handleLinuxCommandQuery(userMessage);
      } else if (_isLearningPathQuery(userMessage)) {
        await _handleLearningPathQuery(userMessage);
      } else if (_isQuizRequest(userMessage)) {
        await _handleQuizRequest(userMessage);
      } else {
        await _handleGeneralQuery(userMessage);
      }
    } catch (e) {
      debugPrint('Error getting bot response: $e');
      await _addErrorMessage('เกิดข้อผิดพลาดในการประมวลผลคำถาม');
    }
  }

  // Check if message is asking about Linux command
  bool _isLinuxCommandQuery(String message) {
    final commandKeywords = ['คำสั่ง', 'command', 'linux', 'อธิบาย', 'วิธีใช้', 'ls', 'cd', 'cp', 'mv', 'rm', 'mkdir', 'chmod', 'chown', 'ps', 'top', 'kill', 'grep', 'find', 'tar', 'wget', 'curl'];
    return commandKeywords.any((keyword) => message.toLowerCase().contains(keyword.toLowerCase()));
  }

  // Check if message is asking about learning path
  bool _isLearningPathQuery(String message) {
    final pathKeywords = ['เส้นทาง', 'แนะนำ', 'เรียน', 'เริ่มต้น', 'ต่อไป', 'ควรเรียน', 'path', 'recommend'];
    return pathKeywords.any((keyword) => message.toLowerCase().contains(keyword.toLowerCase()));
  }

  // Check if message is requesting a quiz
  bool _isQuizRequest(String message) {
    final quizKeywords = ['ทดสอบ', 'quiz', 'แบบทดสอบ', 'คำถาม', 'ตอบ', 'test'];
    return quizKeywords.any((keyword) => message.toLowerCase().contains(keyword.toLowerCase()));
  }

  // Handle Linux command queries
  Future<void> _handleLinuxCommandQuery(String query) async {
    try {
      final response = await _dialogflowService.getLinuxCommandHelp(query);

      final commandMessage = ChatMessage(
        id: const Uuid().v4(),
        text: response.description,
        isUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.linuxCommand,
        metadata: {
          'command': response.command,
          'syntax': response.syntax,
          'examples': response.examples,
          'options': response.options,
        },
      );

      _messages.add(commandMessage);
      await _saveChatMessage(commandMessage);
      notifyListeners();

      // Add follow-up suggestions
      await _addFollowUpSuggestions(response.command);

    } catch (e) {
      await _handleGeneralQuery(query);
    }
  }

  // Handle learning path queries
  Future<void> _handleLearningPathQuery(String query) async {
    try {
      // Get user's current progress
      final userProgress = await _getCurrentUserProgress();

      final response = await _dialogflowService.getLearningPath(
        userLevel: userProgress['level'] ?? 'beginner',
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
        },
      );

      _messages.add(pathMessage);
      await _saveChatMessage(pathMessage);
      notifyListeners();

    } catch (e) {
      await _handleGeneralQuery(query);
    }
  }

  // Handle quiz requests
  Future<void> _handleQuizRequest(String query) async {
    try {
      final userProgress = await _getCurrentUserProgress();

      final quiz = await _dialogflowService.generateQuiz(
        topic: _extractTopicFromQuery(query),
        difficulty: userProgress['difficulty'] ?? 'beginner',
      );

      final quizMessage = ChatMessage(
        id: const Uuid().v4(),
        text: quiz.question,
        isUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.quiz,
        metadata: {
          'options': quiz.options,
          'correctAnswer': quiz.correctAnswer,
          'explanation': quiz.explanation,
          'quizId': const Uuid().v4(),
        },
      );

      _messages.add(quizMessage);
      await _saveChatMessage(quizMessage);
      notifyListeners();

    } catch (e) {
      await _handleGeneralQuery(query);
    }
  }

  // Handle general queries
  Future<void> _handleGeneralQuery(String query) async {
    try {
      final response = await _dialogflowService.getSmallTalkResponse(query);

      final botMessage = ChatMessage(
        id: const Uuid().v4(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.text,
      );

      _messages.add(botMessage);
      await _saveChatMessage(botMessage);
      notifyListeners();

    } catch (e) {
      await _addErrorMessage('ขออภัย ฉันไม่สามารถตอบคำถามนี้ได้ในขณะนี้');
    }
  }

  // Add follow-up suggestions
  Future<void> _addFollowUpSuggestions(String command) async {
    final suggestions = _getCommandSuggestions(command);

    if (suggestions.isNotEmpty) {
      final suggestionMessage = ChatMessage(
        id: const Uuid().v4(),
        text: 'คุณอาจสนใจคำสั่งเหล่านี้:',
        isUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.suggestions,
        metadata: {
          'suggestions': suggestions,
        },
      );

      _messages.add(suggestionMessage);
      await _saveChatMessage(suggestionMessage);
      notifyListeners();
    }
  }

  // Get command suggestions based on current command
  List<String> _getCommandSuggestions(String command) {
    final suggestionMap = {
      'ls': ['cd', 'pwd', 'mkdir', 'rmdir'],
      'cd': ['ls', 'pwd', 'find'],
      'cp': ['mv', 'rm', 'chmod'],
      'mv': ['cp', 'rm', 'chmod'],
      'rm': ['ls', 'cp', 'mv'],
      'mkdir': ['rmdir', 'ls', 'chmod'],
      'chmod': ['chown', 'ls', 'stat'],
      'ps': ['top', 'kill', 'jobs'],
      'grep': ['find', 'awk', 'sed'],
    };

    return suggestionMap[command.toLowerCase()] ?? [];
  }

  // Add error message
  Future<void> _addErrorMessage(String errorText) async {
    final errorMessage = ChatMessage(
      id: const Uuid().v4(),
      text: errorText,
      isUser: false,
      timestamp: DateTime.now(),
      messageType: MessageType.error,
      metadata: {'isError': true},
    );

    _messages.add(errorMessage);
    await _saveChatMessage(errorMessage);
    notifyListeners();
  }

  // Save chat message to Firebase
  Future<void> _saveChatMessage(ChatMessage message) async {
    if (_currentUserId == null) return;

    try {
      await _firebaseService.saveChatMessage(_currentUserId!, message);
    } catch (e) {
      debugPrint('Error saving chat message: $e');
    }
  }

  // Get current user progress
  Future<Map<String, dynamic>> _getCurrentUserProgress() async {
    if (_currentUserId == null) return {};

    try {
      final userProfile = await _firebaseService.getUserProfile(_currentUserId!);
      final learningProgress = await _firebaseService.getLearningProgress(_currentUserId!);

      return {
        'level': userProfile?.currentDifficulty ?? 'beginner',
        'difficulty': userProfile?.currentDifficulty ?? 'beginner',
        'completedCommands': learningProgress.map((p) => p.commandName).toList(),
        'totalLessons': userProfile?.totalLessonsCompleted ?? 0,
      };
    } catch (e) {
      debugPrint('Error getting user progress: $e');
      return {
        'level': 'beginner',
        'difficulty': 'beginner',
        'completedCommands': <String>[],
        'totalLessons': 0,
      };
    }
  }

  // Extract topic from query
  String _extractTopicFromQuery(String query) {
    final topicKeywords = {
      'file': ['ไฟล์', 'file', 'ls', 'cp', 'mv', 'rm'],
      'system': ['ระบบ', 'system', 'ps', 'top', 'kill'],
      'network': ['เครือข่าย', 'network', 'ping', 'wget', 'curl'],
      'text': ['ข้อความ', 'text', 'grep', 'sed', 'awk'],
      'permission': ['สิทธิ์', 'permission', 'chmod', 'chown'],
    };

    for (final entry in topicKeywords.entries) {
      if (entry.value.any((keyword) => query.toLowerCase().contains(keyword.toLowerCase()))) {
        return entry.key;
      }
    }

    return 'general';
  }

  // Handle quiz answer
  Future<void> handleQuizAnswer(String messageId, String answer) async {
    try {
      final quizMessage = _messages.firstWhere((m) => m.id == messageId);
      final correctAnswer = quizMessage.metadata?['correctAnswer'] as String?;
      final explanation = quizMessage.metadata?['explanation'] as String?;

      final isCorrect = answer.toLowerCase() == correctAnswer?.toLowerCase();

      // Add user's answer
      final answerMessage = ChatMessage(
        id: const Uuid().v4(),
        text: 'คำตอบ: $answer',
        isUser: true,
        timestamp: DateTime.now(),
        messageType: MessageType.text,
      );

      _messages.add(answerMessage);
      await _saveChatMessage(answerMessage);

      // Add result message
      final resultText = isCorrect
          ? '🎉 ถูกต้อง! $explanation'
          : '❌ ไม่ถูกต้อง คำตอบที่ถูกคือ: $correctAnswer\n$explanation';

      final resultMessage = ChatMessage(
        id: const Uuid().v4(),
        text: resultText,
        isUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.quizResult,
        metadata: {
          'isCorrect': isCorrect,
          'correctAnswer': correctAnswer,
          'userAnswer': answer,
        },
      );

      _messages.add(resultMessage);
      await _saveChatMessage(resultMessage);
      notifyListeners();

      // Log quiz result
      await _analyticsService.logEvent('quiz_answered', {
        'is_correct': isCorrect,
        'quiz_id': quizMessage.metadata?['quizId'],
        'topic': _extractTopicFromQuery(quizMessage.text),
      });

    } catch (e) {
      debugPrint('Error handling quiz answer: $e');
      await _addErrorMessage('เกิดข้อผิดพลาดในการประมวลผลคำตอบ');
    }
  }

  // Send command suggestion
  Future<void> sendCommandSuggestion(String command) async {
    await sendMessage('อธิบายคำสั่ง $command', type: MessageType.text);
  }

  // Clear chat history
  Future<void> clearChatHistory() async {
    _messages.clear();
    await _addWelcomeMessage();
    notifyListeners();

    // Log analytics
    await _analyticsService.logEvent('chat_history_cleared', {
      'session_id': _sessionId,
      'messages_count': _messages.length,
    });
  }

  // Send voice message
  Future<void> sendVoiceMessage(String transcribedText) async {
    await sendMessage(transcribedText, type: MessageType.voice);
  }

  // Get chat summary
  String getChatSummary() {
    if (_messages.isEmpty) return 'ไม่มีประวัติการสนทนา';

    final userMessages = _messages.where((m) => m.isUser).length;
    final botMessages = _messages.where((m) => !m.isUser).length;
    final commandQueries = _messages.where((m) => m.messageType == MessageType.linuxCommand).length;
    final quizzes = _messages.where((m) => m.messageType == MessageType.quiz).length;

    return 'ข้อความทั้งหมด: ${_messages.length}\n'
        'คำถามของคุณ: $userMessages\n'
        'คำตอบจากบอท: $botMessages\n'
        'คำสั่ง Linux ที่ถาม: $commandQueries\n'
        'แบบทดสอบ: $quizzes';
  }

  // Export chat history
  Map<String, dynamic> exportChatHistory() {
    return {
      'sessionId': _sessionId,
      'userId': _currentUserId,
      'exportedAt': DateTime.now().toIso8601String(),
      'messages': _messages.map((m) => m.toMap()).toList(),
      'summary': getChatSummary(),
    };
  }

  // Dispose resources
  @override
  void dispose() {
    _messages.clear();
    _isInitialized = false;
    _currentUserId = null;
    super.dispose();
  }

  // Reset chat for new session
  Future<void> resetChat() async {
    _messages.clear();
    _sessionId = 'session_${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}';
    await _addWelcomeMessage();
    notifyListeners();
  }

  // Get suggested questions
  List<String> getSuggestedQuestions() {
    return [
      'คำสั่ง ls ใช้ทำอะไร?',
      'วิธีเปลี่ยนไดเร็กทอรี่ใน Linux',
      'อธิบายคำสั่ง chmod',
      'แนะนำคำสั่งสำหรับผู้เริ่มต้น',
      'ทดสอบความรู้เรื่องไฟล์',
      'คำสั่งดูกระบวนการที่กำลังทำงาน',
      'วิธีค้นหาไฟล์ใน Linux',
      'คำสั่งบีบอัดไฟล์',
    ];
  }

  // Handle quick reply
  Future<void> handleQuickReply(String reply) async {
    await sendMessage(reply, type: MessageType.text);
  }
}