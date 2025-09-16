import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'learning_progress.g.dart';

enum ProgressStatus {
  notStarted,
  inProgress,
  completed,
  review,
  mastered
}

enum LearningMode {
  tutorial,
  practice,
  quiz,
  challenge,
  freePlay
}

@HiveType(typeId: 7)
class LearningProgress extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String commandId;

  @HiveField(3)
  final String commandName;

  @HiveField(4)
  final ProgressStatus status;

  @HiveField(5)
  final double progressPercentage;

  @HiveField(6)
  final int attempts;

  @HiveField(7)
  final int bestScore;

  @HiveField(8)
  final int timeSpentSeconds;

  @HiveField(9)
  final DateTime startedAt;

  @HiveField(10)
  final DateTime? completedAt;

  @HiveField(11)
  final DateTime lastAttemptAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final List<LearningSession> sessions;

  @HiveField(14)
  final Map<String, int> skillsProgress;

  @HiveField(15)
  final List<String> hintsUsed;

  @HiveField(16)
  final List<String> errorsEncountered;

  @HiveField(17)
  final LearningMode lastLearningMode;

  @HiveField(18)
  final int streakCount;

  @HiveField(19)
  final Map<String, dynamic>? metadata;

  @HiveField(20)
  final double? difficultyRating;

  @HiveField(21)
  final String? notes;

  const LearningProgress({
    required this.id,
    required this.userId,
    required this.commandId,
    required this.commandName,
    required this.status,
    required this.progressPercentage,
    required this.attempts,
    required this.bestScore,
    required this.timeSpentSeconds,
    required this.startedAt,
    this.completedAt,
    required this.lastAttemptAt,
    required this.updatedAt,
    required this.sessions,
    required this.skillsProgress,
    required this.hintsUsed,
    required this.errorsEncountered,
    required this.lastLearningMode,
    required this.streakCount,
    this.metadata,
    this.difficultyRating,
    this.notes,
  });

  // Factory constructor from Map (Firebase)
  factory LearningProgress.fromMap(Map<String, dynamic> map) {
    return LearningProgress(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      commandId: map['commandId'] ?? '',
      commandName: map['commandName'] ?? '',
      status: ProgressStatus.values.firstWhere(
            (e) => e.toString() == 'ProgressStatus.${map['status']}',
        orElse: () => ProgressStatus.notStarted,
      ),
      progressPercentage: (map['progressPercentage'] ?? 0.0).toDouble(),
      attempts: map['attempts'] ?? 0,
      bestScore: map['bestScore'] ?? 0,
      timeSpentSeconds: map['timeSpentSeconds'] ?? 0,
      startedAt: (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      lastAttemptAt: (map['lastAttemptAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sessions: (map['sessions'] as List?)
          ?.map((e) => LearningSession.fromMap(Map<String, dynamic>.from(e)))
          .toList() ?? [],
      skillsProgress: Map<String, int>.from(map['skillsProgress'] ?? {}),
      hintsUsed: List<String>.from(map['hintsUsed'] ?? []),
      errorsEncountered: List<String>.from(map['errorsEncountered'] ?? []),
      lastLearningMode: LearningMode.values.firstWhere(
            (e) => e.toString() == 'LearningMode.${map['lastLearningMode']}',
        orElse: () => LearningMode.tutorial,
      ),
      streakCount: map['streakCount'] ?? 0,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      difficultyRating: map['difficultyRating']?.toDouble(),
      notes: map['notes'],
    );
  }

  // Convert to Map (Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'commandId': commandId,
      'commandName': commandName,
      'status': status.toString().split('.').last,
      'progressPercentage': progressPercentage,
      'attempts': attempts,
      'bestScore': bestScore,
      'timeSpentSeconds': timeSpentSeconds,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'lastAttemptAt': Timestamp.fromDate(lastAttemptAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'sessions': sessions.map((e) => e.toMap()).toList(),
      'skillsProgress': skillsProgress,
      'hintsUsed': hintsUsed,
      'errorsEncountered': errorsEncountered,
      'lastLearningMode': lastLearningMode.toString().split('.').last,
      'streakCount': streakCount,
      'metadata': metadata,
      'difficultyRating': difficultyRating,
      'notes': notes,
    };
  }

  // Copy with method
  LearningProgress copyWith({
    String? id,
    String? userId,
    String? commandId,
    String? commandName,
    ProgressStatus? status,
    double? progressPercentage,
    int? attempts,
    int? bestScore,
    int? timeSpentSeconds,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastAttemptAt,
    DateTime? updatedAt,
    List<LearningSession>? sessions,
    Map<String, int>? skillsProgress,
    List<String>? hintsUsed,
    List<String>? errorsEncountered,
    LearningMode? lastLearningMode,
    int? streakCount,
    Map<String, dynamic>? metadata,
    double? difficultyRating,
    String? notes,
  }) {
    return LearningProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      commandId: commandId ?? this.commandId,
      commandName: commandName ?? this.commandName,
      status: status ?? this.status,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      attempts: attempts ?? this.attempts,
      bestScore: bestScore ?? this.bestScore,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sessions: sessions ?? this.sessions,
      skillsProgress: skillsProgress ?? this.skillsProgress,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      errorsEncountered: errorsEncountered ?? this.errorsEncountered,
      lastLearningMode: lastLearningMode ?? this.lastLearningMode,
      streakCount: streakCount ?? this.streakCount,
      metadata: metadata ?? this.metadata,
      difficultyRating: difficultyRating ?? this.difficultyRating,
      notes: notes ?? this.notes,
    );
  }

  // Helper methods
  String get statusDisplayText {
    switch (status) {
      case ProgressStatus.notStarted:
        return 'ยังไม่เริ่ม';
      case ProgressStatus.inProgress:
        return 'กำลังเรียน';
      case ProgressStatus.completed:
        return 'เสร็จสิ้น';
      case ProgressStatus.review:
        return 'ทบทวน';
      case ProgressStatus.mastered:
        return 'เชี่ยวชาญ';
    }
  }

  String get learningModeDisplayText {
    switch (lastLearningMode) {
      case LearningMode.tutorial:
        return 'บทเรียน';
      case LearningMode.practice:
        return 'ฝึกฝน';
      case LearningMode.quiz:
        return 'แบบทดสอบ';
      case LearningMode.challenge:
        return 'ความท้าทาย';
      case LearningMode.freePlay:
        return 'เล่นอิสระ';
    }
  }

  bool get isCompleted => status == ProgressStatus.completed || status == ProgressStatus.mastered;
  bool get isInProgress => status == ProgressStatus.inProgress;
  bool get needsReview => status == ProgressStatus.review;
  bool get isMastered => status == ProgressStatus.mastered;

  Duration get timeSpent => Duration(seconds: timeSpentSeconds);
  String get formattedTimeSpent {
    final duration = timeSpent;
    if (duration.inHours > 0) {
      return '${duration.inHours} ชม. ${duration.inMinutes % 60} น.';
    } else {
      return '${duration.inMinutes} นาที';
    }
  }

  double get averageScore {
    if (sessions.isEmpty) return 0.0;
    final total = sessions.fold(0, (sum, session) => sum + session.score);
    return total / sessions.length;
  }

  int get totalSessions => sessions.length;
  int get successfulSessions => sessions.where((s) => s.isSuccessful).length;
  double get successRate => totalSessions > 0 ? successfulSessions / totalSessions : 0.0;

  bool get hasRecentActivity {
    final daysSinceLastAttempt = DateTime.now().difference(lastAttemptAt).inDays;
    return daysSinceLastAttempt <= 7;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    commandId,
    commandName,
    status,
    progressPercentage,
    attempts,
    bestScore,
    timeSpentSeconds,
    startedAt,
    completedAt,
    lastAttemptAt,
    updatedAt,
    sessions,
    skillsProgress,
    hintsUsed,
    errorsEncountered,
    lastLearningMode,
    streakCount,
    metadata,
    difficultyRating,
    notes,
  ];
}

@HiveType(typeId: 8)
class LearningSession extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  final DateTime endTime;

  @HiveField(3)
  final LearningMode mode;

  @HiveField(4)
  final int score;

  @HiveField(5)
  final int maxScore;

  @HiveField(6)
  final bool isSuccessful;

  @HiveField(7)
  final List<String> hintsUsed;

  @HiveField(8)
  final List<SessionError> errors;

  @HiveField(9)
  final Map<String, dynamic>? sessionData;

  @HiveField(10)
  final String? feedback;

  const LearningSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.mode,
    required this.score,
    required this.maxScore,
    required this.isSuccessful,
    required this.hintsUsed,
    required this.errors,
    this.sessionData,
    this.feedback,
  });

  factory LearningSession.fromMap(Map<String, dynamic> map) {
    return LearningSession(
      id: map['id'] ?? '',
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mode: LearningMode.values.firstWhere(
            (e) => e.toString() == 'LearningMode.${map['mode']}',
        orElse: () => LearningMode.tutorial,
      ),
      score: map['score'] ?? 0,
      maxScore: map['maxScore'] ?? 100,
      isSuccessful: map['isSuccessful'] ?? false,
      hintsUsed: List<String>.from(map['hintsUsed'] ?? []),
      errors: (map['errors'] as List?)
          ?.map((e) => SessionError.fromMap(Map<String, dynamic>.from(e)))
          .toList() ?? [],
      sessionData: map['sessionData'] != null
          ? Map<String, dynamic>.from(map['sessionData'])
          : null,
      feedback: map['feedback'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'mode': mode.toString().split('.').last,
      'score': score,
      'maxScore': maxScore,
      'isSuccessful': isSuccessful,
      'hintsUsed': hintsUsed,
      'errors': errors.map((e) => e.toMap()).toList(),
      'sessionData': sessionData,
      'feedback': feedback,
    };
  }

  Duration get duration => endTime.difference(startTime);
  double get scorePercentage => maxScore > 0 ? (score / maxScore) * 100 : 0.0;
  int get errorCount => errors.length;
  int get hintCount => hintsUsed.length;

  @override
  List<Object?> get props => [
    id,
    startTime,
    endTime,
    mode,
    score,
    maxScore,
    isSuccessful,
    hintsUsed,
    errors,
    sessionData,
    feedback,
  ];
}

@HiveType(typeId: 9)
class SessionError extends Equatable {
  @HiveField(0)
  final String errorType;

  @HiveField(1)
  final String errorMessage;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String? userInput;

  @HiveField(4)
  final String? expectedInput;

  @HiveField(5)
  final String? suggestion;

  const SessionError({
    required this.errorType,
    required this.errorMessage,
    required this.timestamp,
    this.userInput,
    this.expectedInput,
    this.suggestion,
  });

  factory SessionError.fromMap(Map<String, dynamic> map) {
    return SessionError(
      errorType: map['errorType'] ?? '',
      errorMessage: map['errorMessage'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userInput: map['userInput'],
      expectedInput: map['expectedInput'],
      suggestion: map['suggestion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'errorType': errorType,
      'errorMessage': errorMessage,
      'timestamp': Timestamp.fromDate(timestamp),
      'userInput': userInput,
      'expectedInput': expectedInput,
      'suggestion': suggestion,
    };
  }

  @override
  List<Object?> get props => [
    errorType,
    errorMessage,
    timestamp,
    userInput,
    expectedInput,
    suggestion,
  ];
}