import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/analytics_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/linux_command.dart';
import '../../data/models/learning_progress.dart';

enum LearningState {
  idle,
  loading,
  loaded,
  error
}

class LearningProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  // State
  LearningState _state = LearningState.idle;
  UserModel? _currentUser;
  List<LinuxCommand> _allCommands = [];
  List<LinuxCommand> _filteredCommands = [];
  List<String> _categories = [];
  List<String> _difficulties = ['beginner', 'intermediate', 'advanced', 'expert'];
  Map<String, List<LinuxCommand>> _commandsByCategory = {};
  Map<String, LearningProgress> _userProgress = {};

  // Filters
  String _selectedCategory = 'all';
  String _selectedDifficulty = 'all';
  String _searchQuery = '';

  // Learning paths
  List<LearningPath> _learningPaths = [];
  List<String> _recommendedCommands = [];

  String? _errorMessage;
  bool _isInitialized = false;

  // Getters
  LearningState get state => _state;
  UserModel? get currentUser => _currentUser;
  List<LinuxCommand> get allCommands => List.unmodifiable(_allCommands);
  List<LinuxCommand> get filteredCommands => List.unmodifiable(_filteredCommands);
  List<String> get categories => List.unmodifiable(_categories);
  List<String> get difficulties => List.unmodifiable(_difficulties);
  Map<String, List<LinuxCommand>> get commandsByCategory => Map.unmodifiable(_commandsByCategory);
  Map<String, LearningProgress> get userProgress => Map.unmodifiable(_userProgress);

  // Filter getters
  String get selectedCategory => _selectedCategory;
  String get selectedDifficulty => _selectedDifficulty;
  String get searchQuery => _searchQuery;

  // Learning paths
  List<LearningPath> get learningPaths => List.unmodifiable(_learningPaths);
  List<String> get recommendedCommands => List.unmodifiable(_recommendedCommands);

  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get hasCommands => _allCommands.isNotEmpty;

  /// Initialize learning provider
  Future<void> initialize(String? userId) async {
    try {
      _setState(LearningState.loading);

      if (userId != null) {
        await _loadLinuxCommands();
        await _loadUserProgress(userId);
        await _generateLearningPaths();
        await _generateRecommendations();
      } else {
        await _loadLinuxCommands();
      }

      _isInitialized = true;
      _setState(LearningState.loaded);

    } catch (e) {
      _setError('Failed to initialize learning: ${e.toString()}');
    }
  }

  /// Update current user
  void updateUser(UserModel? user) {
    _currentUser = user;
    if (user != null && !_isInitialized) {
      initialize(user.id);
    } else if (user != null) {
      _loadUserProgress(user.id);
      _generateRecommendations();
    }
    notifyListeners();
  }

  /// Load Linux commands from various sources
  Future<void> _loadLinuxCommands() async {
    try {
      // Load from local cache first
      await _loadCommandsFromCache();

      // Then load from Firebase if available
      await _loadCommandsFromFirebase();

      // If still empty, create default commands
      if (_allCommands.isEmpty) {
        _allCommands = _createDefaultCommands();
        await _cacheCommands();
      }

      _processCommands();

    } catch (e) {
      print('Error loading Linux commands: $e');
      _allCommands = _createDefaultCommands();
      _processCommands();
    }
  }

  /// Load commands from local cache
  Future<void> _loadCommandsFromCache() async {
    try {
      final box = await Hive.openBox<LinuxCommand>('linux_commands');
      _allCommands = box.values.toList();
    } catch (e) {
      print('Error loading commands from cache: $e');
    }
  }

  /// Load commands from Firebase
  Future<void> _loadCommandsFromFirebase() async {
    try {
      // This would load from Firestore collection
      // For now, we'll use default commands
    } catch (e) {
      print('Error loading commands from Firebase: $e');
    }
  }

  /// Cache commands locally
  Future<void> _cacheCommands() async {
    try {
      final box = await Hive.openBox<LinuxCommand>('linux_commands');
      await box.clear();
      for (final command in _allCommands) {
        await box.put(command.id, command);
      }
    } catch (e) {
      print('Error caching commands: $e');
    }
  }

  /// Process loaded commands
  void _processCommands() {
    // Extract categories
    _categories = ['all', ...{
      for (final command in _allCommands)
        command.category.toString().split('.').last
    }];

    // Group commands by category
    _commandsByCategory = {
      'all': _allCommands,
    };

    for (final category in CommandCategory.values) {
      final categoryCommands = _allCommands
          .where((cmd) => cmd.category == category)
          .toList();
      if (categoryCommands.isNotEmpty) {
        _commandsByCategory[category.toString().split('.').last] = categoryCommands;
      }
    }

    // Apply initial filters
    _applyFilters();
  }

  /// Load user progress
  Future<void> _loadUserProgress(String userId) async {
    try {
      // Load from Firebase or local storage
      // For now, create empty progress
      _userProgress = {};

      for (final command in _allCommands) {
        final progress = await _loadCommandProgress(userId, command.id);
        if (progress != null) {
          _userProgress[command.id] = progress;
        }
      }

    } catch (e) {
      print('Error loading user progress: $e');
    }
  }

  /// Load progress for specific command
  Future<LearningProgress?> _loadCommandProgress(String userId, String commandId) async {
    try {
      final doc = await _firebaseService.getLearningProgress(userId, commandId);
      if (doc?.exists == true && doc?.data() != null) {
        return LearningProgress.fromMap(doc!.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error loading command progress: $e');
    }
    return null;
  }

  /// Generate learning paths
  Future<void> _generateLearningPaths() async {
    _learningPaths = [
      LearningPath(
        id: 'beginner_path',
        title: 'เส้นทางผู้เริ่มต้น',
        description: 'เรียนรู้คำสั่งพื้นฐานสำหรับผู้เริ่มต้น',
        difficulty: 'beginner',
        estimatedDuration: 'ประมาณ 2 สัปดาห์',
        commands: [
          'pwd', 'ls', 'cd', 'mkdir', 'rmdir', 'touch', 'cat', 'cp', 'mv', 'rm'
        ],
        prerequisites: [],
        color: const Color(0xFF4CAF50),
        icon: Icons.school,
      ),
      LearningPath(
        id: 'intermediate_path',
        title: 'เส้นทางระดับกลาง',
        description: 'ขยายความรู้ด้วยคำสั่งที่ซับซ้อนขึ้น',
        difficulty: 'intermediate',
        estimatedDuration: 'ประมาณ 3 สัปดาห์',
        commands: [
          'grep', 'find', 'sort', 'uniq', 'wc', 'head', 'tail', 'chmod', 'chown', 'ps'
        ],
        prerequisites: ['beginner_path'],
        color: const Color(0xFFFF9800),
        icon: Icons.trending_up,
      ),
      LearningPath(
        id: 'advanced_path',
        title: 'เส้นทางขั้นสูง',
        description: 'เชี่ยวชาญคำสั่งขั้นสูงและการจัดการระบบ',
        difficulty: 'advanced',
        estimatedDuration: 'ประมาณ 4 สัปดาห์',
        commands: [
          'awk', 'sed', 'tar', 'zip', 'cron', 'systemctl', 'netstat', 'iptables', 'ssh', 'rsync'
        ],
        prerequisites: ['intermediate_path'],
        color: const Color(0xFFF44336),
        icon: Icons.psychology,
      ),
    ];
  }

  /// Generate personalized recommendations
  Future<void> _generateRecommendations() async {
    if (_currentUser == null) {
      _recommendedCommands = ['ls', 'cd', 'pwd', 'cat', 'mkdir'];
      return;
    }

    try {
      final userLevel = _currentUser!.preferences.difficultyLevel;
      final completedCommands = _userProgress.keys
          .where((id) => _userProgress[id]!.isCompleted)
          .toSet();

      // Filter commands based on user level and progress
      final suitableCommands = _allCommands
          .where((cmd) => _isCommandSuitable(cmd, userLevel, completedCommands))
          .take(10)
          .map((cmd) => cmd.name)
          .toList();

      _recommendedCommands = suitableCommands.isNotEmpty
          ? suitableCommands
          : ['ls', 'cd', 'pwd', 'cat', 'mkdir'];

    } catch (e) {
      print('Error generating recommendations: $e');
      _recommendedCommands = ['ls', 'cd', 'pwd', 'cat', 'mkdir'];
    }
  }

  /// Check if command is suitable for user
  bool _isCommandSuitable(LinuxCommand command, String userLevel, Set<String> completedCommands) {
    // Already completed
    if (completedCommands.contains(command.id)) return false;

    // Check difficulty match
    final userDifficultyIndex = _difficulties.indexOf(userLevel);
    final commandDifficultyIndex = _difficulties.indexOf(command.difficulty.toString().split('.').last);

    // Recommend commands at or slightly above user level
    return commandDifficultyIndex <= userDifficultyIndex + 1;
  }

  /// Filter methods
  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setDifficulty(String difficulty) {
    _selectedDifficulty = difficulty;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = 'all';
    _selectedDifficulty = 'all';
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  /// Apply all filters
  void _applyFilters() {
    var commands = List<LinuxCommand>.from(_allCommands);

    // Apply category filter
    if (_selectedCategory != 'all') {
      commands = commands.where((cmd) =>
      cmd.category.toString().split('.').last == _selectedCategory).toList();
    }

    // Apply difficulty filter
    if (_selectedDifficulty != 'all') {
      commands = commands.where((cmd) =>
      cmd.difficulty.toString().split('.').last == _selectedDifficulty).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      commands = commands.where((cmd) =>
      cmd.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          cmd.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          cmd.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }

    _filteredCommands = commands;
  }

  /// Get command by name
  LinuxCommand? getCommandByName(String name) {
    try {
      return _allCommands.firstWhere((cmd) => cmd.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get command by ID
  LinuxCommand? getCommandById(String id) {
    try {
      return _allCommands.firstWhere((cmd) => cmd.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get commands by category
  List<LinuxCommand> getCommandsByCategory(CommandCategory category) {
    return _allCommands.where((cmd) => cmd.category == category).toList();
  }

  /// Get user progress for command
  LearningProgress? getProgressForCommand(String commandId) {
    return _userProgress[commandId];
  }

  /// Check if command is completed
  bool isCommandCompleted(String commandId) {
    final progress = _userProgress[commandId];
    return progress?.isCompleted ?? false;
  }

  /// Start learning command
  Future<void> startLearningCommand(String commandId, LearningMode mode) async {
    if (_currentUser == null) return;

    try {
      final command = getCommandById(commandId);
      if (command == null) return;

      // Create or update progress
      final existingProgress = _userProgress[commandId];
      final now = DateTime.now();

      final progress = existingProgress?.copyWith(
        lastAttemptAt: now,
        updatedAt: now,
        lastLearningMode: mode,
        status: ProgressStatus.inProgress,
      ) ?? LearningProgress(
        id: 'progress_${_currentUser!.id}_$commandId',
        userId: _currentUser!.id,
        commandId: commandId,
        commandName: command.name,
        status: ProgressStatus.inProgress,
        progressPercentage: 0.0,
        attempts: 0,
        bestScore: 0,
        timeSpentSeconds: 0,
        startedAt: now,
        lastAttemptAt: now,
        updatedAt: now,
        sessions: [],
        skillsProgress: {},
        hintsUsed: [],
        errorsEncountered: [],
        lastLearningMode: mode,
        streakCount: 0,
      );

      _userProgress[commandId] = progress;

      // Save to Firebase
      await _firebaseService.saveLearningProgress(_currentUser!.id, progress.toMap());

      // Log analytics
      await _analyticsService.logLearningSessionStart(
        commandId: commandId,
        commandName: command.name,
        difficulty: command.difficulty.toString().split('.').last,
        mode: mode.toString().split('.').last,
      );

      notifyListeners();

    } catch (e) {
      _setError('Failed to start learning: ${e.toString()}');
    }
  }

  /// Complete learning session
  Future<void> completeSession(String commandId, {
    required int score,
    required int timeSpentSeconds,
    required bool successful,
    List<String>? hintsUsed,
    List<String>? errors,
  }) async {
    if (_currentUser == null) return;

    try {
      final progress = _userProgress[commandId];
      if (progress == null) return;

      final command = getCommandById(commandId);
      if (command == null) return;

      // Create session
      final session = LearningSession(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        startTime: DateTime.now().subtract(Duration(seconds: timeSpentSeconds)),
        endTime: DateTime.now(),
        mode: progress.lastLearningMode,
        score: score,
        maxScore: 100,
        isSuccessful: successful,
        hintsUsed: hintsUsed ?? [],
        errors: errors?.map((e) => SessionError(
          errorType: 'user_error',
          errorMessage: e,
          timestamp: DateTime.now(),
        )).toList() ?? [],
      );

      // Update progress
      final newSessions = [...progress.sessions, session];
      final newBestScore = score > progress.bestScore ? score : progress.bestScore;
      final newTimeSpent = progress.timeSpentSeconds + timeSpentSeconds;
      final newAttempts = progress.attempts + 1;

      // Calculate new progress percentage
      double newProgressPercentage = progress.progressPercentage;
      if (successful) {
        newProgressPercentage = ((newProgressPercentage + 25.0).clamp(0.0, 100.0));
      }

      // Determine new status
      ProgressStatus newStatus = progress.status;
      if (newProgressPercentage >= 100.0) {
        newStatus = ProgressStatus.completed;
      } else if (newProgressPercentage >= 50.0) {
        newStatus = ProgressStatus.inProgress;
      }

      final updatedProgress = progress.copyWith(
        sessions: newSessions,
        bestScore: newBestScore,
        timeSpentSeconds: newTimeSpent,
        attempts: newAttempts,
        progressPercentage: newProgressPercentage,
        status: newStatus,
        completedAt: newStatus == ProgressStatus.completed ? DateTime.now() : null,
        lastAttemptAt: DateTime.now(),
        updatedAt: DateTime.now(),
        hintsUsed: [...progress.hintsUsed, ...?(hintsUsed)],
        errorsEncountered: [...progress.errorsEncountered, ...?(errors)],
      );

      _userProgress[commandId] = updatedProgress;

      // Save to Firebase
      await _firebaseService.saveLearningProgress(_currentUser!.id, updatedProgress.toMap());

      // Log analytics
      await _analyticsService.logLearningSessionComplete(
        commandId: commandId,
        commandName: command.name,
        timeSpentSeconds: timeSpentSeconds,
        score: score,
        successful: successful,
      );

      // Regenerate recommendations
      await _generateRecommendations();

      notifyListeners();

    } catch (e) {
      _setError('Failed to complete session: ${e.toString()}');
    }
  }

  /// Get learning statistics
  Map<String, dynamic> getLearningStatistics() {
    if (_currentUser == null || _userProgress.isEmpty) {
      return {
        'totalCommands': 0,
        'completedCommands': 0,
        'inProgressCommands': 0,
        'totalTimeSpent': 0,
        'averageScore': 0.0,
        'completionRate': 0.0,
      };
    }

    final completed = _userProgress.values.where((p) => p.isCompleted).length;
    final inProgress = _userProgress.values.where((p) => p.isInProgress).length;
    final totalTime = _userProgress.values.fold(0, (sum, p) => sum + p.timeSpentSeconds);
    final totalScore = _userProgress.values.fold(0, (sum, p) => sum + p.bestScore);
    final avgScore = _userProgress.isNotEmpty ? totalScore / _userProgress.length : 0.0;
    final completionRate = _allCommands.isNotEmpty ? (completed / _allCommands.length) * 100 : 0.0;

    return {
      'totalCommands': _allCommands.length,
      'completedCommands': completed,
      'inProgressCommands': inProgress,
      'totalTimeSpent': totalTime,
      'averageScore': avgScore,
      'completionRate': completionRate,
    };
  }

  /// Create default commands
  List<LinuxCommand> _createDefaultCommands() {
    return [
      LinuxCommand(
        id: 'cmd_ls',
        name: 'ls',
        description: 'แสดงรายการไฟล์และโฟลเดอร์ในไดเรกทอรีปัจจุบัน',
        syntax: 'ls [options] [file...]',
        difficulty: CommandDifficulty.beginner,
        category: CommandCategory.fileSystem,
        examples: [
          CommandExample(
            command: 'ls',
            description: 'แสดงรายการไฟล์ทั้งหมด',
            expectedOutput: 'file1.txt  file2.txt  folder1',
          ),
          CommandExample(
            command: 'ls -la',
            description: 'แสดงรายการไฟล์แบบละเอียด รวมไฟล์ที่ซ่อน',
            expectedOutput: 'drwxr-xr-x 2 user user 4096 Jan 1 12:00 .',
          ),
        ],
        parameters: [
          CommandParameter(
            name: 'all',
            shortForm: '-a',
            longForm: '--all',
            description: 'แสดงไฟล์ที่ซ่อนด้วย',
          ),
          CommandParameter(
            name: 'long',
            shortForm: '-l',
            longForm: '--long',
            description: 'แสดงข้อมูลแบบละเอียด',
          ),
        ],
        relatedCommands: ['cd', 'pwd', 'find'],
        tags: ['list', 'directory', 'files', 'basic'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      LinuxCommand(
        id: 'cmd_cd',
        name: 'cd',
        description: 'เปลี่ยนไดเรกทอรีปัจจุบัน',
        syntax: 'cd [directory]',
        difficulty: CommandDifficulty.beginner,
        category: CommandCategory.fileSystem,
        examples: [
          CommandExample(
            command: 'cd /home/user',
            description: 'ไปยังโฟลเดอร์ /home/user',
          ),
          CommandExample(
            command: 'cd ..',
            description: 'ย้อนกลับไปโฟลเดอร์ด้านบน',
          ),
        ],
        parameters: [],
        relatedCommands: ['ls', 'pwd', 'mkdir'],
        tags: ['navigate', 'directory', 'change', 'basic'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // Add more default commands...
    ];
  }

  /// State management
  void _setState(LearningState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(LearningState.error);
  }

  void clearError() {
    _errorMessage = null;
    if (_state == LearningState.error) {
      _setState(LearningState.loaded);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Learning Path model
class LearningPath {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String estimatedDuration;
  final List<String> commands;
  final List<String> prerequisites;
  final Color color;
  final IconData icon;

  const LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.estimatedDuration,
    required this.commands,
    required this.prerequisites,
    required this.color,
    required this.icon,
  });
}

// Required imports
import 'package:flutter/material.dart';