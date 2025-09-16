import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

import '../../../core/constants/app_constants.dart';

class DialogFlowResponse {
  final String text;
  final List<String>? quickReplies;
  final List<String>? commandSuggestions;
  final Map<String, dynamic>? metadata;
  final String? intent;
  final double confidence;
  final String sessionId;

  const DialogFlowResponse({
    required this.text,
    this.quickReplies,
    this.commandSuggestions,
    this.metadata,
    this.intent,
    required this.confidence,
    required this.sessionId,
  });

  factory DialogFlowResponse.fromJson(Map<String, dynamic> json) {
    final queryResult = json['queryResult'] as Map<String, dynamic>? ?? {};
    final fulfillmentText = queryResult['fulfillmentText'] as String? ?? '';
    final intentData = queryResult['intent'] as Map<String, dynamic>? ?? {};
    final parameters = queryResult['parameters'] as Map<String, dynamic>? ?? {};

    // Extract quick replies from fulfillment messages
    final fulfillmentMessages = queryResult['fulfillmentMessages'] as List? ?? [];
    List<String>? quickReplies;
    List<String>? commandSuggestions;

    for (final message in fulfillmentMessages) {
      if (message is Map<String, dynamic>) {
        final quickRepliesData = message['quickReplies'] as Map<String, dynamic>?;
        if (quickRepliesData != null) {
          quickReplies = (quickRepliesData['quickReplies'] as List?)
              ?.cast<String>();
        }

        final suggestions = message['suggestions'] as Map<String, dynamic>?;
        if (suggestions != null) {
          commandSuggestions = (suggestions['suggestions'] as List?)
              ?.map((s) => s['title'] as String)
              .toList();
        }
      }
    }

    return DialogFlowResponse(
      text: fulfillmentText,
      quickReplies: quickReplies,
      commandSuggestions: commandSuggestions,
      metadata: parameters,
      intent: intentData['displayName'] as String?,
      confidence: (queryResult['intentDetectionConfidence'] as num?)?.toDouble() ?? 0.0,
      sessionId: json['session'] as String? ?? '',
    );
  }
}

class DialogflowDatasource {
  static const String _baseUrl = 'https://dialogflow.googleapis.com/v2';
  late String _projectId;
  late String _accessToken;
  late DateTime _tokenExpiry;

  // Singleton pattern
  static final DialogflowDatasource _instance = DialogflowDatasource._internal();
  factory DialogflowDatasource() => _instance;
  DialogflowDatasource._internal();

  // Initialize with service account credentials
  Future<void> initialize() async {
    try {
      _projectId = AppConstants.dialogflowProjectId;
      await _refreshAccessToken();
    } catch (error) {
      throw Exception('Failed to initialize DialogFlow: $error');
    }
  }

  // Refresh access token using service account key
  Future<void> _refreshAccessToken() async {
    try {
      // Load service account credentials from assets
      final credentialsJson = await rootBundle.loadString(
          'assets/credentials/dialogflow_credentials.json'
      );
      final credentials = ServiceAccountCredentials.fromJson(credentialsJson);

      // Get access token
      final client = await clientViaServiceAccount(
          credentials,
          ['https://www.googleapis.com/auth/cloud-platform']
      );

      final accessCredentials = client.credentials;
      _accessToken = accessCredentials.accessToken.data;
      _tokenExpiry = accessCredentials.accessToken.expiry;

      client.close();
    } catch (error) {
      throw Exception('Failed to refresh access token: $error');
    }
  }

  // Check if token needs refresh
  Future<void> _ensureValidToken() async {
    if (DateTime.now().isAfter(_tokenExpiry.subtract(Duration(minutes: 5)))) {
      await _refreshAccessToken();
    }
  }

  // Send message to DialogFlow and get response
  Future<DialogFlowResponse> sendMessage({
    required String text,
    required String sessionId,
    String? languageCode,
    Map<String, dynamic>? context,
  }) async {
    try {
      await _ensureValidToken();

      final url = '$_baseUrl/projects/$_projectId/agent/sessions/$sessionId:detectIntent';

      final requestBody = {
        'queryInput': {
          'text': {
            'text': text,
            'languageCode': languageCode ?? AppConstants.dialogflowLanguageCode,
          }
        },
        'queryParams': {
          if (context != null) 'contexts': _buildContexts(context),
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return DialogFlowResponse.fromJson(responseData);
      } else {
        throw Exception('DialogFlow API error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      throw Exception('Failed to send message to DialogFlow: $error');
    }
  }

  // Send event to DialogFlow
  Future<DialogFlowResponse> sendEvent({
    required String eventName,
    required String sessionId,
    String? languageCode,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? context,
  }) async {
    try {
      await _ensureValidToken();

      final url = '$_baseUrl/projects/$_projectId/agent/sessions/$sessionId:detectIntent';

      final requestBody = {
        'queryInput': {
          'event': {
            'name': eventName,
            'languageCode': languageCode ?? AppConstants.dialogflowLanguageCode,
            if (parameters != null) 'parameters': parameters,
          }
        },
        'queryParams': {
          if (context != null) 'contexts': _buildContexts(context),
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return DialogFlowResponse.fromJson(responseData);
      } else {
        throw Exception('DialogFlow API error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      throw Exception('Failed to send event to DialogFlow: $error');
    }
  }

  // Build contexts for DialogFlow
  List<Map<String, dynamic>> _buildContexts(Map<String, dynamic> contextData) {
    final contexts = <Map<String, dynamic>>[];

    for (final entry in contextData.entries) {
      contexts.add({
        'name': 'projects/$_projectId/agent/sessions/${contextData['sessionId'] ?? 'default'}/contexts/${entry.key}',
        'lifespanCount': 5,
        'parameters': entry.value,
      });
    }

    return contexts;
  }

  // Specialized methods for Linux learning context

  // Send Linux command query
  Future<DialogFlowResponse> queryLinuxCommand({
    required String command,
    required String sessionId,
    String? category,
    String? difficulty,
    Map<String, dynamic>? userContext,
  }) async {
    final context = {
      'sessionId': sessionId,
      'linux-command-context': {
        'command': command,
        if (category != null) 'category': category,
        if (difficulty != null) 'difficulty': difficulty,
        'timestamp': DateTime.now().toIso8601String(),
        ...?userContext,
      }
    };

    return await sendMessage(
      text: command,
      sessionId: sessionId,
      context: context,
    );
  }

  // Start learning session
  Future<DialogFlowResponse> startLearningSession({
    required String sessionId,
    required String skillLevel,
    List<String>? interestedCategories,
    Map<String, dynamic>? userProfile,
  }) async {
    final parameters = {
      'skillLevel': skillLevel,
      if (interestedCategories != null) 'interestedCategories': interestedCategories,
      'sessionStart': DateTime.now().toIso8601String(),
      ...?userProfile,
    };

    return await sendEvent(
      eventName: 'start-learning-session',
      sessionId: sessionId,
      parameters: parameters,
    );
  }

  // Ask for help with specific topic
  Future<DialogFlowResponse> askForHelp({
    required String topic,
    required String sessionId,
    String? currentLevel,
    List<String>? strugglingWith,
  }) async {
    final context = {
      'sessionId': sessionId,
      'help-context': {
        'topic': topic,
        if (currentLevel != null) 'currentLevel': currentLevel,
        if (strugglingWith != null) 'strugglingWith': strugglingWith,
        'helpRequested': DateTime.now().toIso8601String(),
      }
    };

    return await sendMessage(
      text: 'ช่วยเหลือเกี่ยวกับ $topic',
      sessionId: sessionId,
      context: context,
    );
  }

  // Request quiz or practice
  Future<DialogFlowResponse> requestPractice({
    required String sessionId,
    String? category,
    String? difficulty,
    int? questionCount,
  }) async {
    final parameters = {
      if (category != null) 'category': category,
      if (difficulty != null) 'difficulty': difficulty,
      if (questionCount != null) 'questionCount': questionCount,
      'practiceType': 'quiz',
      'requestTime': DateTime.now().toIso8601String(),
    };

    return await sendEvent(
      eventName: 'request-practice',
      sessionId: sessionId,
      parameters: parameters,
    );
  }

  // Submit quiz answer
  Future<DialogFlowResponse> submitQuizAnswer({
    required String answer,
    required String sessionId,
    required String questionId,
    bool? isCorrect,
  }) async {
    final context = {
      'sessionId': sessionId,
      'quiz-context': {
        'questionId': questionId,
        'userAnswer': answer,
        if (isCorrect != null) 'isCorrect': isCorrect,
        'answerTime': DateTime.now().toIso8601String(),
      }
    };

    return await sendMessage(
      text: answer,
      sessionId: sessionId,
      context: context,
    );
  }

  // Get personalized suggestions
  Future<DialogFlowResponse> getPersonalizedSuggestions({
    required String sessionId,
    required Map<String, dynamic> userProgress,
    required List<String> completedLessons,
    required Map<String, int> categoryScores,
  }) async {
    final parameters = {
      'userProgress': userProgress,
      'completedLessons': completedLessons,
      'categoryScores': categoryScores,
      'requestTime': DateTime.now().toIso8601String(),
    };

    return await sendEvent(
      eventName: 'get-personalized-suggestions',
      sessionId: sessionId,
      parameters: parameters,
    );
  }

  // Report learning progress
  Future<DialogFlowResponse> reportProgress({
    required String sessionId,
    required int xpGained,
    required int currentLevel,
    List<String>? newAchievements,
    Map<String, dynamic>? sessionStats,
  }) async {
    final parameters = {
      'xpGained': xpGained,
      'currentLevel': currentLevel,
      if (newAchievements != null) 'newAchievements': newAchievements,
      'reportTime': DateTime.now().toIso8601String(),
      ...?sessionStats,
    };

    return await sendEvent(
      eventName: 'report-progress',
      sessionId: sessionId,
      parameters: parameters,
    );
  }

  // Handle voice input
  Future<DialogFlowResponse> processVoiceInput({
    required String transcribedText,
    required String sessionId,
    double? confidence,
    Map<String, dynamic>? voiceMetadata,
  }) async {
    final context = {
      'sessionId': sessionId,
      'voice-context': {
        'transcribedText': transcribedText,
        if (confidence != null) 'transcriptionConfidence': confidence,
        'inputMethod': 'voice',
        'voiceInputTime': DateTime.now().toIso8601String(),
        ...?voiceMetadata,
      }
    };

    return await sendMessage(
      text: transcribedText,
      sessionId: sessionId,
      context: context,
    );
  }

  // End learning session
  Future<DialogFlowResponse> endLearningSession({
    required String sessionId,
    required Duration sessionDuration,
    required Map<String, dynamic> sessionSummary,
  }) async {
    final parameters = {
      'sessionDuration': sessionDuration.inMinutes,
      'sessionSummary': sessionSummary,
      'sessionEndTime': DateTime.now().toIso8601String(),
    };

    return await sendEvent(
      eventName: 'end-learning-session',
      sessionId: sessionId,
      parameters: parameters,
    );
  }

  // Error handling and fallback
  Future<DialogFlowResponse> handleError({
    required String sessionId,
    required String errorType,
    String? errorMessage,
    Map<String, dynamic>? errorContext,
  }) async {
    final parameters = {
      'errorType': errorType,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'errorTime': DateTime.now().toIso8601String(),
      ...?errorContext,
    };

    return await sendEvent(
      eventName: 'handle-error',
      sessionId: sessionId,
      parameters: parameters,
    );
  }

  // Get fallback response when DialogFlow is unavailable
  DialogFlowResponse getFallbackResponse(String originalText, String sessionId) {
    final fallbackResponses = [
      'ขออภัยครับ ขณะนี้ระบบมีปัญหาชั่วคราว กรุณาลองใหม่อีกครั้งในสักครู่',
      'เกิดข้อผิดพลาดในการเชื่อมต่อ กรุณาตรวจสอบการเชื่อมต่อและลองใหม่',
      'ระบบไม่สามารถประมวลผลคำถามได้ในขณะนี้ กรุณาลองถามใหม่',
    ];

    final randomResponse = fallbackResponses[
    DateTime.now().millisecond % fallbackResponses.length
    ];

    return DialogFlowResponse(
      text: randomResponse,
      confidence: 0.0,
      sessionId: sessionId,
      intent: 'fallback',
      quickReplies: [
        'ลองใหม่',
        'ช่วยเหลือ',
        'กลับหน้าหลัก',
      ],
    );
  }

  // Batch processing for multiple queries
  Future<List<DialogFlowResponse>> sendBatchMessages({
    required List<String> messages,
    required String sessionId,
    String? languageCode,
    Map<String, dynamic>? sharedContext,
  }) async {
    final responses = <DialogFlowResponse>[];

    for (int i = 0; i < messages.length; i++) {
      try {
        final response = await sendMessage(
          text: messages[i],
          sessionId: '${sessionId}_batch_$i',
          languageCode: languageCode,
          context: sharedContext,
        );
        responses.add(response);
      } catch (error) {
        // Add fallback response for failed requests
        responses.add(getFallbackResponse(messages[i], sessionId));
      }

      // Add small delay to avoid rate limiting
      if (i < messages.length - 1) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }

    return responses;
  }

  // Session management
  Future<void> clearSession(String sessionId) async {
    try {
      await _ensureValidToken();

      final url = '$_baseUrl/projects/$_projectId/agent/sessions/$sessionId/contexts';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to clear session: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to clear DialogFlow session: $error');
    }
  }

  // Get session contexts
  Future<List<Map<String, dynamic>>> getSessionContexts(String sessionId) async {
    try {
      await _ensureValidToken();

      final url = '$_baseUrl/projects/$_projectId/agent/sessions/$sessionId/contexts';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['contexts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      } else {
        throw Exception('Failed to get contexts: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to get session contexts: $error');
    }
  }

  // Analytics and monitoring
  Map<String, dynamic> getResponseAnalytics(DialogFlowResponse response) {
    return {
      'intent': response.intent,
      'confidence': response.confidence,
      'hasQuickReplies': response.quickReplies?.isNotEmpty ?? false,
      'hasCommandSuggestions': response.commandSuggestions?.isNotEmpty ?? false,
      'responseLength': response.text.length,
      'processingTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Connection health check
  Future<bool> checkConnection() async {
    try {
      await _ensureValidToken();

      // Send a simple test query
      final testResponse = await sendMessage(
        text: 'test connection',
        sessionId: 'health_check_${DateTime.now().millisecondsSinceEpoch}',
      );

      return testResponse.confidence >= 0.0; // Any valid response indicates connection
    } catch (error) {
      return false;
    }
  }

  // Rate limiting helper
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(milliseconds: 100);

  Future<void> _respectRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - timeSinceLastRequest);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  // Enhanced error handling with retry logic
  Future<DialogFlowResponse> sendMessageWithRetry({
    required String text,
    required String sessionId,
    String? languageCode,
    Map<String, dynamic>? context,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    Exception? lastError;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await _respectRateLimit();

        return await sendMessage(
          text: text,
          sessionId: sessionId,
          languageCode: languageCode,
          context: context,
        );
      } catch (error) {
        lastError = error is Exception ? error : Exception(error.toString());

        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay * (attempt + 1)); // Exponential backoff
        }
      }
    }

    // If all retries failed, return fallback response
    return getFallbackResponse(text, sessionId);
  }

  // Specialized query processing for different input types
  Future<DialogFlowResponse> processLinuxQuery({
    required String query,
    required String sessionId,
    required String userLevel,
    List<String>? recentCommands,
    Map<String, int>? categoryProgress,
  }) async {
    // Pre-process the query to add context
    final context = {
      'sessionId': sessionId,
      'learning-context': {
        'userLevel': userLevel,
        'queryType': 'linux_command',
        'timestamp': DateTime.now().toIso8601String(),
        if (recentCommands != null) 'recentCommands': recentCommands,
        if (categoryProgress != null) 'categoryProgress': categoryProgress,
      }
    };

    return await sendMessageWithRetry(
      text: query,
      sessionId: sessionId,
      context: context,
    );
  }

  // Command explanation request
  Future<DialogFlowResponse> explainCommand({
    required String command,
    required String sessionId,
    String? detailLevel, // 'basic', 'intermediate', 'advanced'
    bool includeExamples = true,
  }) async {
    final context = {
      'sessionId': sessionId,
      'explanation-context': {
        'command': command,
        'detailLevel': detailLevel ?? 'basic',
        'includeExamples': includeExamples,
        'requestType': 'explanation',
      }
    };

    return await sendMessageWithRetry(
      text: 'อธิบายคำสั่ง $command',
      sessionId: sessionId,
      context: context,
    );
  }

  // Practice suggestion request
  Future<DialogFlowResponse> getPracticeSuggestions({
    required String sessionId,
    required String currentTopic,
    required String difficulty,
    int? timeAvailable, // in minutes
  }) async {
    final parameters = {
      'currentTopic': currentTopic,
      'difficulty': difficulty,
      if (timeAvailable != null) 'timeAvailable': timeAvailable,
      'requestType': 'practice_suggestions',
      'timestamp': DateTime.now().toIso8601String(),
    };

    return await sendEvent(
      eventName: 'get-practice-suggestions',
      sessionId: sessionId,
      parameters: parameters,
    );
  }

  // Cleanup resources
  void dispose() {
    // Clean up any resources if needed
    _lastRequestTime = null;
  }

  // Export session data for debugging
  Future<Map<String, dynamic>> exportSessionData(String sessionId) async {
    try {
      final contexts = await getSessionContexts(sessionId);

      return {
        'sessionId': sessionId,
        'contexts': contexts,
        'exportTime': DateTime.now().toIso8601String(),
        'tokenExpiry': _tokenExpiry.toIso8601String(),
      };
    } catch (error) {
      return {
        'sessionId': sessionId,
        'error': error.toString(),
        'exportTime': DateTime.now().toIso8601String(),
      };
    }
  }
}