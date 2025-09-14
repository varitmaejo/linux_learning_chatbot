import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:dialogflow_flutter/dialogflow_flutter.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../constants/firebase_constants.dart';

class DialogflowService {
  static DialogflowService? _instance;
  static DialogflowService get instance => _instance ??= DialogflowService._();
  DialogflowService._();

  AuthClient? _authClient;
  String? _projectId;
  bool _initialized = false;

  // Initialize Dialogflow
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Load service account credentials
      final serviceAccountJson = await rootBundle.loadString('assets/credentials/dialogflow_credentials.json');
      final serviceAccount = ServiceAccountCredentials.fromJson(json.decode(serviceAccountJson));

      _projectId = serviceAccount.projectId;

      // Create authenticated client
      _authClient = await clientViaServiceAccount(
          serviceAccount,
          ['https://www.googleapis.com/auth/cloud-platform']
      );

      _initialized = true;
      print('Dialogflow initialized successfully');
    } catch (e) {
      print('Error initializing Dialogflow: $e');
      rethrow;
    }
  }

  // Send message to Dialogflow and get response
  Future<DialogflowResponse> detectIntent({
    required String message,
    required String sessionId,
    String? languageCode = 'th',
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // Create Dialogflow request
      final authClient = await AuthClient.fromServiceAccount(
          await rootBundle.loadString('assets/credentials/dialogflow_credentials.json'),
          ['https://www.googleapis.com/auth/cloud-platform']
      );

      final dialogflow = DialogflowV2(authClient, _projectId!);

      // Detect intent
      final response = await dialogflow.detectIntent(
        sessionId: sessionId,
        queryInput: QueryInput(
          text: TextInput(
            text: message,
            languageCode: languageCode ?? 'th',
          ),
        ),
      );

      return DialogflowResponse.fromDetectIntentResponse(response);
    } catch (e) {
      print('Error in detectIntent: $e');
      throw DialogflowException('Failed to get response from Dialogflow: $e');
    }
  }

  // Get small talk response
  Future<String> getSmallTalkResponse(String message) async {
    try {
      final response = await detectIntent(
        message: message,
        sessionId: 'smalltalk_session',
        languageCode: 'th',
      );

      return response.fulfillmentText ?? 'ขออภัย ฉันไม่เข้าใจคำถามของคุณ';
    } catch (e) {
      return 'เกิดข้อผิดพลาดในการประมวลผลคำถาม กรุณาลองใหม่อีกครั้ง';
    }
  }

  // Get Linux command explanation
  Future<LinuxCommandResponse> getLinuxCommandHelp(String command) async {
    try {
      final response = await detectIntent(
        message: 'อธิบายคำสั่ง Linux: $command',
        sessionId: 'linux_help_session',
        languageCode: 'th',
      );

      return LinuxCommandResponse.fromDialogflowResponse(response);
    } catch (e) {
      throw DialogflowException('Failed to get Linux command help: $e');
    }
  }

  // Get learning path recommendation
  Future<LearningPathResponse> getLearningPath({
    required String userLevel,
    required List<String> completedCommands,
  }) async {
    try {
      final message = 'แนะนำเส้นทางการเรียนรู้สำหรับระดับ $userLevel ที่เรียนจบแล้ว: ${completedCommands.join(", ")}';

      final response = await detectIntent(
        message: message,
        sessionId: 'learning_path_session',
        languageCode: 'th',
      );

      return LearningPathResponse.fromDialogflowResponse(response);
    } catch (e) {
      throw DialogflowException('Failed to get learning path: $e');
    }
  }

  // Analyze user progress and give feedback
  Future<String> getProgressFeedback({
    required int completedLessons,
    required int totalLessons,
    required double accuracy,
    required int streak,
  }) async {
    try {
      final message = '''วิเคราะห์ความก้าวหน้า: 
        เรียนจบแล้ว $completedLessons จาก $totalLessons บทเรียน
        ความแม่นยำ ${(accuracy * 100).toStringAsFixed(1)}%
        เรียนติดต่อกันได้ $streak วัน''';

      final response = await detectIntent(
        message: message,
        sessionId: 'progress_feedback_session',
        languageCode: 'th',
      );

      return response.fulfillmentText ?? 'ยินดีด้วย! คุณมีความก้าวหน้าที่ดีมาก';
    } catch (e) {
      return 'ไม่สามารถวิเคราะห์ความก้าวหน้าได้ในขณะนี้';
    }
  }

  // Generate quiz question
  Future<QuizQuestion> generateQuiz({
    required String topic,
    required String difficulty,
  }) async {
    try {
      final message = 'สร้างคำถามเกี่ยวกับ $topic ระดับ $difficulty';

      final response = await detectIntent(
        message: message,
        sessionId: 'quiz_generation_session',
        languageCode: 'th',
      );

      return QuizQuestion.fromDialogflowResponse(response);
    } catch (e) {
      throw DialogflowException('Failed to generate quiz: $e');
    }
  }

  // Clean up resources
  void dispose() {
    _authClient?.close();
    _authClient = null;
    _initialized = false;
  }
}

// Response models
class DialogflowResponse {
  final String? fulfillmentText;
  final Map<String, dynamic>? parameters;
  final String? intent;
  final double? confidence;

  DialogflowResponse({
    this.fulfillmentText,
    this.parameters,
    this.intent,
    this.confidence,
  });

  static DialogflowResponse fromDetectIntentResponse(dynamic response) {
    return DialogflowResponse(
      fulfillmentText: response['queryResult']?['fulfillmentText'],
      parameters: response['queryResult']?['parameters'],
      intent: response['queryResult']?['intent']?['displayName'],
      confidence: response['queryResult']?['intentDetectionConfidence']?.toDouble(),
    );
  }
}

class LinuxCommandResponse {
  final String command;
  final String description;
  final String syntax;
  final List<String> examples;
  final List<String> options;

  LinuxCommandResponse({
    required this.command,
    required this.description,
    required this.syntax,
    required this.examples,
    required this.options,
  });

  static LinuxCommandResponse fromDialogflowResponse(DialogflowResponse response) {
    final parameters = response.parameters ?? {};
    return LinuxCommandResponse(
      command: parameters['command'] ?? '',
      description: response.fulfillmentText ?? '',
      syntax: parameters['syntax'] ?? '',
      examples: List<String>.from(parameters['examples'] ?? []),
      options: List<String>.from(parameters['options'] ?? []),
    );
  }
}

class LearningPathResponse {
  final List<String> recommendedCommands;
  final String explanation;
  final String nextTopic;

  LearningPathResponse({
    required this.recommendedCommands,
    required this.explanation,
    required this.nextTopic,
  });

  static LearningPathResponse fromDialogflowResponse(DialogflowResponse response) {
    final parameters = response.parameters ?? {};
    return LearningPathResponse(
      recommendedCommands: List<String>.from(parameters['recommended_commands'] ?? []),
      explanation: response.fulfillmentText ?? '',
      nextTopic: parameters['next_topic'] ?? '',
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  static QuizQuestion fromDialogflowResponse(DialogflowResponse response) {
    final parameters = response.parameters ?? {};
    return QuizQuestion(
      question: response.fulfillmentText ?? '',
      options: List<String>.from(parameters['options'] ?? []),
      correctAnswer: parameters['correct_answer'] ?? '',
      explanation: parameters['explanation'] ?? '',
    );
  }
}

// Exception classes
class DialogflowException implements Exception {
  final String message;
  DialogflowException(this.message);

  @override
  String toString() => 'DialogflowException: $message';
}