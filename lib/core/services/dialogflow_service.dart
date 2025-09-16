import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/dialogflow/v2.dart';
import '../constants/firebase_constants.dart';

class DialogflowService {
  static DialogflowService? _instance;
  static DialogflowService get instance => _instance ??= DialogflowService._();

  DialogflowService._();

  DialogflowApi? _dialogflowApi;
  String? _projectId;
  String? _sessionId;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  String get sessionPath => 'projects/$_projectId/agent/sessions/$_sessionId';

  /// Initialize Dialogflow service
  Future<void> initialize({
    String? credentialsPath,
    String? projectId,
    String? sessionId,
  }) async {
    /// Initialize Dialogflow service
    Future<void> initialize({
      String? credentialsPath,
      String? projectId,
      String? sessionId,
    }) async {
      try {
        if (_isInitialized) return;

        // Load credentials from assets
        final credentialsJson = await rootBundle.loadString(
            credentialsPath ?? 'assets/credentials/dialogflow_credentials.json'
        );

        final credentials = ServiceAccountCredentials.fromJson(
            json.decode(credentialsJson)
        );

        // Set project ID
        _projectId = projectId ?? credentials.projectId;
        _sessionId = sessionId ?? 'flutter-session-${DateTime.now().millisecondsSinceEpoch}';

        // Create authenticated HTTP client
        final httpClient = await clientViaServiceAccount(
          credentials,
          [DialogflowApi.cloudPlatformScope],
        );

        // Initialize Dialogflow API
        _dialogflowApi = DialogflowApi(httpClient);

        _isInitialized = true;
        print('Dialogflow service initialized successfully');

      } catch (e) {
        print('Error initializing Dialogflow service: $e');
        rethrow;
      }
    }

    /// Detect intent from text
    Future<DialogflowResponse> detectIntent(String text, {String? languageCode}) async {
      if (!_isInitialized || _dialogflowApi == null) {
        throw Exception('Dialogflow service not initialized');
      }

      try {
        final request = DetectIntentRequest();
        request.queryInput = QueryInput();
        request.queryInput!.text = TextInput();
        request.queryInput!.text!.text = text;
        request.queryInput!.text!.languageCode = languageCode ?? 'th-TH';

        final response = await _dialogflowApi!.projects.agent.sessions.detectIntent(
          request,
          sessionPath,
        );

        return DialogflowResponse.fromDetectIntentResponse(response);

      } catch (e) {
        print('Error detecting intent: $e');
        return DialogflowResponse.error('Failed to process request: ${e.toString()}');
      }
    }

    /// Generate learning path based on user progress
    Future<LearningPathResponse> generateLearningPath({
      required String currentLevel,
      required List<String> completedCommands,
    }) async {
      try {
        final query = 'แนะนำเส้นทางการเรียนรู้สำหรับระดับ $currentLevel';
        final response = await detectIntent(query);

        return LearningPathResponse(
          explanation: response.fulfillmentText,
          recommendedCommands: _extractCommandsFromResponse(response.fulfillmentText),
          nextTopic: _extractNextTopicFromResponse(response.fulfillmentText),
          difficulty: currentLevel,
        );

      } catch (e) {
        print('Error generating learning path: $e');
        return LearningPathResponse(
          explanation: 'ขออภัย ไม่สามารถสร้างเส้นทางการเรียนรู้ได้ในขณะนี้',
          recommendedCommands: ['ls', 'cd', 'pwd'],
          nextTopic: 'พื้นฐานการใช้คำสั่ง',
          difficulty: currentLevel,
        );
      }
    }

    /// Generate quiz based on topic
    Future<QuizResponse> generateQuiz({
      required String topic,
      required String difficulty,
      int questionCount = 5,
    }) async {
      try {
        final query = 'สร้างแบบทดสอบเรื่อง $topic ระดับ $difficulty จำนวน $questionCount ข้อ';
        final response = await detectIntent(query);

        return QuizResponse(
          topic: topic,
          difficulty: difficulty,
          questions: _parseQuizQuestions(response.fulfillmentText),
          timeLimit: questionCount * 30, // 30 seconds per question
        );

      } catch (e) {
        print('Error generating quiz: $e');
        return QuizResponse.error(topic, difficulty);
      }
    }

    /// Explain Linux command
    Future<CommandExplanationResponse> explainCommand(String commandName) async {
      try {
        final query = 'อธิบายคำสั่ง Linux "$commandName" แบบละเอียด';
        final response = await detectIntent(query);

        return CommandExplanationResponse(
          command: commandName,
          explanation: response.fulfillmentText,
          examples: _extractExamplesFromResponse(response.fulfillmentText),
          relatedCommands: _extractRelatedCommandsFromResponse(response.fulfillmentText),
          tips: _extractTipsFromResponse(response.fulfillmentText),
        );

      } catch (e) {
        print('Error explaining command: $e');
        return CommandExplanationResponse.error(commandName);
      }
    }

    /// Get contextual help
    Future<DialogflowResponse> getContextualHelp(String context, String question) async {
      try {
        final query = 'ในบริบท $context: $question';
        return await detectIntent(query);
      } catch (e) {
        print('Error getting contextual help: $e');
        return DialogflowResponse.error('ขออภัย ไม่สามารถให้ความช่วยเหลือได้ในขณะนี้');
      }
    }

    /// Validate command syntax
    Future<ValidationResponse> validateCommand(String command) async {
      try {
        final query = 'ตรวจสอบไวยากรณ์คำสั่ง: $command';
        final response = await detectIntent(query);

        return ValidationResponse(
          isValid: _isCommandValid(response.fulfillmentText),
          message: response.fulfillmentText,
          suggestions: _extractSuggestionsFromResponse(response.fulfillmentText),
        );

      } catch (e) {
        print('Error validating command: $e');
        return ValidationResponse(
          isValid: false,
          message: 'ไม่สามารถตรวจสอบคำสั่งได้',
          suggestions: [],
        );
      }
    }

    // Helper methods for parsing responses
    List<String> _extractCommandsFromResponse(String response) {
      final commandPattern = RegExp(r'`([^`]+)`');
      final matches = commandPattern.allMatches(response);
      return matches.map((match) => match.group(1) ?? '').toList();
    }

    String? _extractNextTopicFromResponse(String response) {
      final topicPattern = RegExp(r'หัวข้อต่อไป[:\s]*([^\n\.]+)');
      final match = topicPattern.firstMatch(response);
      return match?.group(1)?.trim();
    }

    List<QuizQuestion> _parseQuizQuestions(String response) {
      // Parse quiz questions from Dialogflow response
      // This is a simplified implementation - in production, you'd have more sophisticated parsing
      final questions = <QuizQuestion>[];

      final questionPattern = RegExp(r'(\d+)\.\s*([^?]+\?)\s*(A[^\n]*)\s*(B[^\n]*)\s*(C[^\n]*)\s*(D[^\n]*)\s*คำตอบ[:\s]*([ABCD])');
      final matches = questionPattern.allMatches(response);

      for (final match in matches) {
        questions.add(QuizQuestion(
          id: match.group(1) ?? '',
          question: match.group(2) ?? '',
          options: [
            match.group(3)?.substring(2) ?? '',
            match.group(4)?.substring(2) ?? '',
            match.group(5)?.substring(2) ?? '',
            match.group(6)?.substring(2) ?? '',
          ],
          correctAnswer: _letterToIndex(match.group(7) ?? 'A'),
          explanation: 'คำอธิบาย',
        ));
      }

      return questions.isNotEmpty ? questions : _getDefaultQuestions();
    }

    List<String> _extractExamplesFromResponse(String response) {
      final examplePattern = RegExp(r'ตัวอย่าง[:\s]*`([^`]+)`');
      final matches = examplePattern.allMatches(response);
      return matches.map((match) => match.group(1) ?? '').toList();
    }

    List<String> _extractRelatedCommandsFromResponse(String response) {
      final relatedPattern = RegExp(r'คำสั่งที่เกี่ยวข้อง[:\s]*([^\n\.]+)');
      final match = relatedPattern.firstMatch(response);
      return match?.group(1)?.split(',').map((e) => e.trim()).toList() ?? [];
    }

    List<String> _extractTipsFromResponse(String response) {
      final tipsPattern = RegExp(r'เคล็ดลับ[:\s]*([^\n]+)');
      final matches = tipsPattern.allMatches(response);
      return matches.map((match) => match.group(1) ?? '').toList();
    }

    List<String> _extractSuggestionsFromResponse(String response) {
      final suggestionPattern = RegExp(r'คำแนะนำ[:\s]*([^\n\.]+)');
      final match = suggestionPattern.firstMatch(response);
      return match?.group(1)?.split(',').map((e) => e.trim()).toList() ?? [];
    }

    bool _isCommandValid(String response) {
      return !response.toLowerCase().contains('ผิด') &&
          !response.toLowerCase().contains('ไม่ถูกต้อง') &&
          !response.toLowerCase().contains('error');
    }

    int _letterToIndex(String letter) {
      switch (letter.toUpperCase()) {
        case 'A': return 0;
        case 'B': return 1;
        case 'C': return 2;
        case 'D': return 3;
        default: return 0;
      }
    }

    List<QuizQuestion> _getDefaultQuestions() {
      return [
        QuizQuestion(
          id: '1',
          question: 'คำสั่งใดใช้สำหรับแสดงรายการไฟล์ในไดเรกทอรี?',
          options: ['ls', 'cd', 'pwd', 'mkdir'],
          correctAnswer: 0,
          explanation: 'คำสั่ง ls ใช้สำหรับแสดงรายการไฟล์และไดเรกทอรี',
        ),
      ];
    }

    /// Clean up resources
    void dispose() {
      _dialogflowApi?.client.close();
      _isInitialized = false;
    }
  }

// Response models
  class DialogflowResponse {
  final String fulfillmentText;
  final String intentName;
  final double confidence;
  final Map<String, dynamic>? parameters;
  final bool isError;

  const DialogflowResponse({
  required this.fulfillmentText,
  required this.intentName,
  required this.confidence,
  this.parameters,
  this.isError = false,
  });

  factory DialogflowResponse.fromDetectIntentResponse(DetectIntentResponse response) {
  return DialogflowResponse(
  fulfillmentText: response.queryResult?.fulfillmentText ?? 'ไม่มีการตอบกลับ',
  intentName: response.queryResult?.intent?.displayName ?? 'Unknown',
  confidence: response.queryResult?.intentDetectionConfidence ?? 0.0,
  parameters: response.queryResult?.parameters,
  );
  }

  factory DialogflowResponse.error(String message) {
  return DialogflowResponse(
  fulfillmentText: message,
  intentName: 'Error',
  confidence: 0.0,
  isError: true,
  );
  }
  }

  class LearningPathResponse {
  final String explanation;
  final List<String> recommendedCommands;
  final String? nextTopic;
  final String difficulty;

  const LearningPathResponse({
  required this.explanation,
  required this.recommendedCommands,
  this.nextTopic,
  required this.difficulty,
  });
  }

  class QuizResponse {
  final String topic;
  final String difficulty;
  final List<QuizQuestion> questions;
  final int timeLimit;
  final bool isError;

  const QuizResponse({
  required this.topic,
  required this.difficulty,
  required this.questions,
  required this.timeLimit,
  this.isError = false,
  });

  factory QuizResponse.error(String topic, String difficulty) {
  return QuizResponse(
  topic: topic,
  difficulty: difficulty,
  questions: [],
  timeLimit: 0,
  isError: true,
  );
  }
  }

  class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  const QuizQuestion({
  required this.id,
  required this.question,
  required this.options,
  required this.correctAnswer,
  required this.explanation,
  });
  }

  class CommandExplanationResponse {
  final String command;
  final String explanation;
  final List<String> examples;
  final List<String> relatedCommands;
  final List<String> tips;
  final bool isError;

  const CommandExplanationResponse({
  required this.command,
  required this.explanation,
  required this.examples,
  required this.relatedCommands,
  required this.tips,
  this.isError = false,
  });

  factory CommandExplanationResponse.error(String command) {
  return CommandExplanationResponse(
  command: command,
  explanation: 'ขออภัย ไม่สามารถอธิบายคำสั่งนี้ได้ในขณะนี้',
  examples: [],
  relatedCommands: [],
  tips: [],
  isError: true,
  );
  }
  }

  class ValidationResponse {
  final bool isValid;
  final String message;
  final List<String> suggestions;

  const ValidationResponse({
  required this.isValid,
  required this.message,
  required this.suggestions,
  });
  }