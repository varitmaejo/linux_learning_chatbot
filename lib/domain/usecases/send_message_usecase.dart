import '../entities/message.dart';
import '../repositories/chat_repository_interface.dart';

class SendMessageUseCase {
  final ChatRepositoryInterface _chatRepository;

  SendMessageUseCase(this._chatRepository);

  /// Send a message and get response from the chatbot
  Future<SendMessageResult> execute({
    required String content,
    required String sessionId,
    required String userId,
    MessageType type = MessageType.text,
    List<String>? attachments,
    Message? replyTo,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate input
      final validationResult = _validateInput(
        content: content,
        sessionId: sessionId,
        userId: userId,
        type: type,
      );

      if (!validationResult.isValid) {
        return SendMessageResult.failure(
          error: validationResult.error!,
          errorCode: 'VALIDATION_ERROR',
        );
      }

      // Create user message
      final userMessage = Message(
        id: _generateMessageId(),
        content: content,
        type: type,
        sender: MessageSender.user,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        userId: userId,
        sessionId: sessionId,
        metadata: metadata ?? {},
        attachments: attachments ?? [],
        replyTo: replyTo,
        isEdited: false,
      );

      // Send message and get bot response
      final botResponse = await _chatRepository.sendMessage(userMessage);

      return SendMessageResult.success(
        userMessage: userMessage.copyWith(status: MessageStatus.sent),
        botResponse: botResponse,
      );
    } catch (e) {
      return SendMessageResult.failure(
        error: e.toString(),
        errorCode: 'SEND_MESSAGE_ERROR',
      );
    }
  }

  /// Send a voice message
  Future<SendMessageResult> sendVoiceMessage({
    required String audioPath,
    required String sessionId,
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    return execute(
      content: audioPath,
      sessionId: sessionId,
      userId: userId,
      type: MessageType.voice,
      metadata: metadata,
    );
  }

  /// Send a command message
  Future<SendMessageResult> sendCommandMessage({
    required String command,
    required String sessionId,
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    return execute(
      content: command,
      sessionId: sessionId,
      userId: userId,
      type: MessageType.command,
      metadata: metadata,
    );
  }

  /// Send message with attachments
  Future<SendMessageResult> sendMessageWithAttachments({
    required String content,
    required String sessionId,
    required String userId,
    required List<String> attachments,
    Map<String, dynamic>? metadata,
  }) async {
    return execute(
      content: content,
      sessionId: sessionId,
      userId: userId,
      attachments: attachments,
      metadata: metadata,
    );
  }

  /// Reply to a message
  Future<SendMessageResult> replyToMessage({
    required String content,
    required String sessionId,
    required String userId,
    required Message replyTo,
    Map<String, dynamic>? metadata,
  }) async {
    return execute(
      content: content,
      sessionId: sessionId,
      userId: userId,
      replyTo: replyTo,
      metadata: metadata,
    );
  }

  ValidationResult _validateInput({
    required String content,
    required String sessionId,
    required String userId,
    required MessageType type,
  }) {
    if (content.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Message content cannot be empty',
      );
    }

    if (sessionId.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'Session ID cannot be empty',
      );
    }

    if (userId.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: 'User ID cannot be empty',
      );
    }

    if (content.length > 10000) {
      return ValidationResult(
        isValid: false,
        error: 'Message content is too long (max 10,000 characters)',
      );
    }

    return ValidationResult(isValid: true);
  }

  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
            (_) => chars.codeUnitAt(
          (DateTime.now().millisecondsSinceEpoch * 997) % chars.length,
        ),
      ),
    );
  }
}

class SendMessageResult {
  final bool isSuccess;
  final Message? userMessage;
  final Message? botResponse;
  final String? error;
  final String? errorCode;

  const SendMessageResult._({
    required this.isSuccess,
    this.userMessage,
    this.botResponse,
    this.error,
    this.errorCode,
  });

  factory SendMessageResult.success({
    required Message userMessage,
    required Message botResponse,
  }) {
    return SendMessageResult._(
      isSuccess: true,
      userMessage: userMessage,
      botResponse: botResponse,
    );
  }

  factory SendMessageResult.failure({
    required String error,
    required String errorCode,
  }) {
    return SendMessageResult._(
      isSuccess: false,
      error: error,
      errorCode: errorCode,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'SendMessageResult.success(userMessage: ${userMessage?.id}, botResponse: ${botResponse?.id})';
    } else {
      return 'SendMessageResult.failure(error: $error, errorCode: $errorCode)';
    }
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult({
    required this.isValid,
    this.error,
  });

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, error: $error)';
  }
}