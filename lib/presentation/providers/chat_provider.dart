import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/send_message_usecase.dart';

enum ChatState {
  initial,
  loading,
  loaded,
  typing,
  error,
}

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;
  late final SendMessageUsecase _sendMessageUsecase;

  ChatProvider({required ChatRepository chatRepository})
      : _chatRepository = chatRepository {
    _sendMessageUsecase = SendMessageUsecase(_chatRepository);
    _initialize();
  }

  // State
  ChatState _state = ChatState.initial;
  ChatState get state => _state;

  // User
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Messages
  List<Message> _messages = [];
  List<Message> get messages => List.unmodifiable(_messages);

  // Current session
  String _sessionId = AppConstants.dialogflowSessionId;
  String get sessionId => _sessionId;

  // Typing indicator
  bool _isTyping = false;
  bool get isTyping => _isTyping;

  // Error handling
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Quick replies
  List<String> _quickReplies = [];
  List<String> get quickReplies => List.unmodifiable(_quickReplies);

  // Voice input
  bool _isListening = false;
  bool get isListening => _isListening;

  // Message statistics
  int get messageCount => _messages.length;
  int get userMessageCount => _messages.where((m) => m.isFromUser).length;
  int get botMessageCount => _messages.where((m) => !m.isFromUser).length;

  void _initialize() {
    _loadChatHistory();
    _setupQuickReplies();
  }

  void updateUser(User? user) {
    _currentUser = user;
    if (user != null) {
      _sessionId = 'session_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
    }
    notifyListeners();
  }

  Future<void> _loadChatHistory() async {
    if (_currentUser == null) return;

    _setState(ChatState.loading);

    try {
      final history = await _chatRepository.getChatHistory(_currentUser!.id);
      _messages = history;

      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }

      _setState(ChatState.loaded);
    } catch (error) {
      _setError('ไม่สามารถโหลดประวัติการสนทนาได้: ${error.toString()}');
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      text: _getWelcomeMessage(),
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: MessageType.text,
      quickReplies: [
        'สอนคำสั่ง ls ให้ฉันหน่อย',
        'คำสั่งไหนใช้สำหรับดูไฟล์?',
        'ฉันเป็นมือใหม่ เริ่มจากไหนดี?',
        'แสดงคำสั่งที่นิยม',
      ],
    );

    _messages.insert(0, welcomeMessage);
    _quickReplies = welcomeMessage.quickReplies ?? [];
  }

  String _getWelcomeMessage() {
    if (_currentUser == null) {
      return 'สวัสดีครับ! ยินดีต้อนรับสู่ระบบเรียนรู้คำสั่ง Linux แบบโต้ตอบ 🐧\n\nผมจะช่วยให้คุณเรียนรู้คำสั่ง Linux แบบง่ายๆ และสนุก มีอะไรให้ช่วยไหมครับ?';
    }

    final user = _currentUser!;
    final timeOfDay = _getTimeOfDay();

    if (user.isNewUser) {
      return '$timeOfDay คุณ${user.name}! 🎉\n\nยินดีต้อนรับสู่การเรียนรู้คำสั่ง Linux ครั้งแรก!\n\nผมจะเป็นครูสอนส่วนตัวของคุณ พร้อมช่วยให้คุณเชี่ยวชาญคำสั่ง Linux แบบสเต็ปบายสเต็ป\n\nเริ่มต้นจากไหนดีครับ?';
    }

    final streak = user.hasActiveStreak ? ' 🔥 สเตรก ${user.streakDays} วัน!' : '';

    return '$timeOfDay คุณ${user.name}!$streak\n\nเรียนรู้คำสั่ง Linux กันต่อเลยไหมครับ?\n\nระดับปัจจุบันของคุณ: ${user.skillLevelDisplayName} (Level ${user.currentLevel})';
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'สวัสดีตอนเช้า';
    if (hour < 17) return 'สวัสดีตอนบ่าย';
    return 'สวัสดีตอนเย็น';
  }

  void _setupQuickReplies() {
    _quickReplies = [
      'สอนคำสั่ง ls ให้ฉันหน่อย',
      'คำสั่งไหนใช้สำหรับดูไฟล์?',
      'ฉันเป็นมือใหม่ เริ่มจากไหนดี?',
      'แสดงคำสั่งที่นิยม',
    ];
  }

  Future<void> sendMessage(String text, {MessageType? type}) async {
    if (text.trim().isEmpty || _currentUser == null) return;

    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
      isFromUser: true,
      timestamp: DateTime.now(),
      messageType: type ?? MessageType.text,
    );

    // Add user message immediately
    _messages.insert(0, userMessage);
    _quickReplies.clear();
    notifyListeners();

    // Show typing indicator
    _setTyping(true);

    try {
      // Send message and get AI response
      final response = await _sendMessageUsecase.execute(
        text: text,
        userId: _currentUser!.id,
        sessionId: _sessionId,
      );

      _setTyping(false);

      // Add AI response
      final aiMessage = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: response.text,
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.text,
        quickReplies: response.quickReplies,
        commandSuggestions: response.commandSuggestions,
        metadata: response.metadata,
      );

      _messages.insert(0, aiMessage);
      _quickReplies = response.quickReplies ?? [];

      // Save to local storage
      await _saveChatHistory();

      _setState(ChatState.loaded);
    } catch (error) {
      _setTyping(false);
      _setError('ไม่สามารถส่งข้อความได้: ${error.toString()}');

      // Add error message
      final errorMessage = ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        text: 'ขออพกเหตุครับ เกิดข้อผิดพลาดในการส่งข้อความ กรุณาลองใหม่อีกครั้ง',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.error,
      );

      _messages.insert(0, errorMessage);
      notifyListeners();
    }
  }

  Future<void> sendQuickReply(String reply) async {
    await sendMessage(reply);
  }

  Future<void> sendCommand(String command) async {
    await sendMessage(command, type: MessageType.command);
  }

  Future<void> sendVoiceMessage(String text) async {
    await sendMessage(text, type: MessageType.voice);
  }

  void _setTyping(bool typing) {
    _isTyping = typing;
    notifyListeners();
  }

  void startListening() {
    _isListening = true;
    notifyListeners();
  }

  void stopListening() {
    _isListening = false;
    notifyListeners();
  }

  Future<void> _saveChatHistory() async {
    if (_currentUser == null) return;

    try {
      // Keep only recent messages to avoid storage issues
      final recentMessages = _messages.take(AppConstants.maxChatHistory).toList();
      await _chatRepository.saveChatHistory(_currentUser!.id, recentMessages);
    } catch (error) {
      debugPrint('Failed to save chat history: $error');
    }
  }

  Future<void> clearChatHistory() async {
    if (_currentUser == null) return;

    try {
      await _chatRepository.clearChatHistory(_currentUser!.id);
      _messages.clear();
      _addWelcomeMessage();
      _setState(ChatState.loaded);
    } catch (error) {
      _setError('ไม่สามารถลบประวัติการสนทนาได้');
    }
  }

  Future<void> exportChatHistory() async {
    // Implementation for exporting chat history
    // This could save to a file or share via platform share dialog
  }

  void retryLastMessage() {
    if (_messages.isNotEmpty && _messages.first.isFromUser) {
      final lastUserMessage = _messages.first;
      sendMessage(lastUserMessage.text, type: lastUserMessage.messageType);
    }
  }

  void _setState(ChatState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _state = ChatState.error;
    _errorMessage = message;
    _isTyping = false;
    notifyListeners();
  }

  void clearError() {
    if (_state == ChatState.error) {
      _setState(ChatState.loaded);
    }
  }

  // Message search functionality
  List<Message> searchMessages(String query) {
    if (query.trim().isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    return _messages.where((message) {
      return message.text.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Message filtering
  List<Message> getMessagesByType(MessageType type) {
    return _messages.where((message) => message.messageType == type).toList();
  }

  List<Message> getUserMessages() {
    return _messages.where((message) => message.isFromUser).toList();
  }

  List<Message> getBotMessages() {
    return _messages.where((message) => !message.isFromUser).toList();
  }

  // Get messages from today
  List<Message> getTodaysMessages() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _messages.where((message) {
      return message.timestamp.isAfter(startOfDay);
    }).toList();
  }

  // Analytics
  Map<String, dynamic> getChatAnalytics() {
    final totalMessages = _messages.length;
    final userMessages = getUserMessages().length;
    final botMessages = getBotMessages().length;
    final commandMessages = getMessagesByType(MessageType.command).length;
    final voiceMessages = getMessagesByType(MessageType.voice).length;

    final firstMessage = _messages.isNotEmpty ? _messages.last.timestamp : null;
    final lastMessage = _messages.isNotEmpty ? _messages.first.timestamp : null;

    Duration? sessionDuration;
    if (firstMessage != null && lastMessage != null) {
      sessionDuration = lastMessage.difference(firstMessage);
    }

    return {
      'totalMessages': totalMessages,
      'userMessages': userMessages,
      'botMessages': botMessages,
      'commandMessages': commandMessages,
      'voiceMessages': voiceMessages,
      'sessionDuration': sessionDuration?.inMinutes ?? 0,
      'averageResponseTime': _calculateAverageResponseTime(),
    };
  }

  double _calculateAverageResponseTime() {
    final responseTimes = <Duration>[];

    for (int i = 0; i < _messages.length - 1; i++) {
      final current = _messages[i];
      final next = _messages[i + 1];

      if (!current.isFromUser && next.isFromUser) {
        responseTimes.add(next.timestamp.difference(current.timestamp));
      }
    }

    if (responseTimes.isEmpty) return 0.0;

    final totalMs = responseTimes.fold(0, (sum, duration) => sum + duration.inMilliseconds);
    return totalMs / responseTimes.length / 1000; // Return in seconds
  }

  @override
  void dispose() {
    _saveChatHistory();
    super.dispose();
  }
}