import '../entities/message.dart';
import '../repositories/chat_repository_interface.dart';

class SendMessageUsecase {
  final ChatRepositoryInterface _chatRepository;

  SendMessageUsecase(this._chatRepository);

  Future<SendMessageResult> execute({
    required String text,
    required String userId,
    required String sessionId,
    MessageType type = MessageType.text,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Validate input
      if (text.trim().isEmpty) {
        throw SendMessageException('ข้อความไม่สามารถเป็นค่าว่างได้');
      }

      if (userId.trim().isEmpty) {
        throw SendMessageException('ไม่พบข้อมูลผู้ใช้');
      }

      if (sessionId.trim().isEmpty) {
        throw SendMessageException('Session ID ไม่ถูกต้อง');
      }

      // Check message length
      if (text.length > 500) {
        throw SendMessageException('ข้อความยาวเกินไป (สูงสุด 500 ตัวอักษร)');
      }

      // Send message through repository
      final responseMessage = await _chatRepository.sendMessage(
        text: text,
        userId: userId,
        sessionId: sessionId,
        type: type,
        context: _buildContext(context, type),
      );

      // Determine response type
      final responseType = _determineResponseType(responseMessage);

      return SendMessageResult.success(
        message: responseMessage,
        responseType: responseType,
        metadata: {
          'processingTime': DateTime.now().millisecondsSinceEpoch,
          'messageType': type.toString(),
          'hasQuickReplies': responseMessage.quickReplies?.isNotEmpty ?? false,
          'hasCommandSuggestions': responseMessage.commandSuggestions?.isNotEmpty ?? false,
        },
      );

    } on SendMessageException {
      rethrow;
    } catch (error) {
      throw SendMessageException('เกิดข้อผิดพลาดในการส่งข้อความ: ${error.toString()}');
    }
  }

  Future<SendMessageResult> executeCommand({
    required String command,
    required String userId,
    required String sessionId,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Validate command
      if (command.trim().isEmpty) {
        throw SendMessageException('คำสั่งไม่สามารถเป็นค่าว่างได้');
      }

      // Check if command is potentially dangerous
      if (_isDangerousCommand(command)) {
        return SendMessageResult.warning(
          message: 'คำสั่ง "$command" อาจเป็นอันตราย กรุณาใช้ความระมัดระวัง',
          originalCommand: command,
        );
      }

      // Send command through repository
      final responseMessage = await _chatRepository.sendCommand(
        command: command,
        userId: userId,
        sessionId: sessionId,
        context: context,
      );

      return SendMessageResult.success(
        message: responseMessage,
        responseType: ResponseType.commandExplanation,
        metadata: {
          'originalCommand': command,
          'isCommandResponse': true,
        },
      );

    } catch (error) {
      throw SendMessageException('เกิดข้อผิดพลาดในการส่งคำสั่ง: ${error.toString()}');
    }
  }

  Future<SendMessageResult> executeVoiceMessage({
    required String transcribedText,
    required String userId,
    required String sessionId,
    required String audioUrl,
    double? confidence,
  }) async {
    try {
      // Validate transcription
      if (transcribedText.trim().isEmpty) {
        throw SendMessageException('ไม่สามารถแปลงเสียงเป็นข้อความได้');
      }

      if (confidence != null && confidence < 0.7) {
        return SendMessageResult.lowConfidence(
          transcribedText: transcribedText,
          confidence: confidence,
        );
      }

      // Send voice message through repository
      final responseMessage = await _chatRepository.sendVoiceMessage(
        transcribedText: transcribedText,
        userId: userId,
        sessionId: sessionId,
        audioUrl: audioUrl,
        confidence: confidence,
      );

      return SendMessageResult.success(
        message: responseMessage,
        responseType: ResponseType.voiceResponse,
        metadata: {
          'originalAudioUrl': audioUrl,
          'transcriptionConfidence': confidence,
          'isVoiceResponse': true,
        },
      );

    } catch (error) {
      throw SendMessageException('เกิดข้อผิดพลาดในการประมวลผลเสียง: ${error.toString()}');
    }
  }

  Future<SendMessageResult> startLearningSession({
    required String userId,
    required String sessionId,
    required String skillLevel,
    List<String>? interestedCategories,
  }) async {
    try {
      final responseMessage = await _chatRepository.startLearningSession(
        userId: userId,
        sessionId: sessionId,
        skillLevel: skillLevel,
        interestedCategories: interestedCategories,
      );

      return SendMessageResult.success(
        message: responseMessage,
        responseType: ResponseType.sessionStart,
        metadata: {
          'skillLevel': skillLevel,
          'interestedCategories': interestedCategories,
          'isSessionStart': true,
        },
      );

    } catch (error) {
      throw SendMessageException('เกิดข้อผิดพลาดในการเริ่มเซสชันการเรียน: ${error.toString()}');
    }
  }

  Future<SendMessageResult> askForHelp({
    required String topic,
    required String userId,
    required String sessionId,
    String? currentLevel,
  }) async {
    try {
      if (topic.trim().isEmpty) {
        throw SendMessageException('กรุณาระบุหัวข้อที่ต้องการความช่วยเหลือ');
      }

      final responseMessage = await _chatRepository.askForHelp(
        topic: topic,
        userId: userId,
        sessionId: sessionId,
        currentLevel: currentLevel,
      );

      return SendMessageResult.success(
        message: responseMessage,
        responseType: ResponseType.helpResponse,
        metadata: {
          'helpTopic': topic,
          'currentLevel': currentLevel,
          'isHelpResponse': true,
        },
      );

    } catch (error) {
      throw SendMessageException('เกิดข้อผิดพลาดในการขอความช่วยเหลือ: ${error.toString()}');
    }
  }

  // Private helper methods
  Map<String, dynamic> _buildContext(Map<String, dynamic>? userContext, MessageType type) {
    final context = userContext ?? {};

    context['messageType'] = type.toString();
    context['timestamp'] = DateTime.now().toIso8601String();

    // Add type-specific context
    switch (type) {
      case MessageType.command:
        context['expectCommandResponse'] = true;
        break;
      case MessageType.voice:
        context['isVoiceInput'] = true;
        break;
      default:
        break;
    }

    return context;
  }

  ResponseType _determineResponseType(Message message) {
    final metadata = message.metadata ?? {};

    if (metadata['commandExplanation'] == true) {
      return ResponseType.commandExplanation;
    } else if (metadata['voiceResponse'] == true) {
      return ResponseType.voiceResponse;
    } else if (metadata['helpResponse'] == true) {
      return ResponseType.helpResponse;
    } else if (message.quickReplies?.isNotEmpty ?? false) {
      return ResponseType.interactive;
    } else {
      return ResponseType.standard;
    }
  }

  bool _isDangerousCommand(String command) {
    final dangerousCommands = [
      'rm -rf',
      'dd if=',
      'mkfs',
      'fdisk',
      'parted',
      'format',
      '> /dev/',
      'shutdown',
      'reboot',
      'init 0',
      'init 6',
      'killall',
      'pkill -9',
    ];

    final lowercaseCommand = command.toLowerCase();
    return dangerousCommands.any((dangerous) =>
        lowercaseCommand.contains(dangerous.toLowerCase()));
  }
}

// Result classes
class SendMessageResult {
  final bool isSuccess;
  final Message? message;
  final ResponseType? responseType;
  final String? errorMessage;
  final String? warningMessage;
  final Map<String, dynamic>? metadata;

  const SendMessageResult._({
    required this.isSuccess,
    this.message,
    this.responseType,
    this.errorMessage,
    this.warningMessage,
    this.metadata,
  });

  factory SendMessageResult.success({
    required Message message,
    required ResponseType responseType,
    Map<String, dynamic>? metadata,
  }) {
    return SendMessageResult._(
      isSuccess: true,
      message: message,
      responseType: responseType,
      metadata: metadata,
    );
  }

  factory SendMessageResult.warning({
    required String message,
    String? originalCommand,
    Map<String, dynamic>? metadata,
  }) {
    return SendMessageResult._(
      isSuccess: false,
      warningMessage: message,
      metadata: {
        ...?metadata,
        'originalCommand': originalCommand,
        'isWarning': true,
      },
    );
  }

  factory SendMessageResult.lowConfidence({
    required String transcribedText,
    required double confidence,
  }) {
    return SendMessageResult._(
      isSuccess: false,
      warningMessage: 'ความมั่นใจในการแปลงเสียงต่ำ (${(confidence * 100).toInt()}%) กรุณาลองพูดใหม่',
      metadata: {
        'transcribedText': transcribedText,
        'confidence': confidence,
        'isLowConfidence': true,
      },
    );
  }

  factory SendMessageResult.error({
    required String errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return SendMessageResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      metadata: metadata,
    );
  }

  bool get hasWarning => warningMessage != null;
  bool get hasError => errorMessage != null;
  bool get hasQuickReplies => message?.quickReplies?.isNotEmpty ?? false;
  bool get hasCommandSuggestions => message?.commandSuggestions?.isNotEmpty ?? false;
}

enum ResponseType {
  standard,
  interactive,
  commandExplanation,
  voiceResponse,
  helpResponse,
  sessionStart,
  error,
}

class SendMessageException implements Exception {
  final String message;

  const SendMessageException(this.message);

  @override
  String toString() => 'SendMessageException: $message';
}