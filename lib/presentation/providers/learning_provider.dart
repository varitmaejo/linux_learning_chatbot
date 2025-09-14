import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/linux_command.dart';
import '../models/learning_progress.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../constants/firebase_constants.dart';

class LearningProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  // State variables
  bool _isInitialized = false;
  bool _isLoading = false;
  List<LinuxCommand> _allCommands = [];
  List<LinuxCommand> _filteredCommands = [];
  List<LearningProgress> _userProgress = [];
  Map<String, List<LinuxCommand>> _categorizedCommands = {};
  String _selectedCategory = 'all';
  String _selectedDifficulty = 'all';
  String _searchQuery = '';
  String? _currentUserId;

  // Learning path
  List<String> _recommendedCommands = [];
  String _currentLearningPath = 'beginner';
  Map<String, double> _categoryProgress = {};

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  List<LinuxCommand> get allCommands => List.unmodifiable(_allCommands);
  List<LinuxCommand> get filteredCommands => List.unmodifiable(_filteredCommands);
  List<LearningProgress> get userProgress => List.unmodifiable(_userProgress);
  Map<String, List<LinuxCommand>> get categorizedCommands => Map.unmodifiable(_categorizedCommands);
  String get selectedCategory => _selectedCategory;
  String get selectedDifficulty => _selectedDifficulty;
  String get searchQuery => _searchQuery;
  List<String> get recommendedCommands => List.unmodifiable(_recommendedCommands);
  String get currentLearningPath => _currentLearningPath;
  Map<String, double> get categoryProgress => Map.unmodifiable(_categoryProgress);

  // Available categories
  List<String> get availableCategories => [
    'all',
    'file_management',
    'system_administration',
    'networking',
    'text_processing',
    'package_management',
    'security',
    'shell_scripting',
  ];

  // Available difficulties
  List<String> get availableDifficulties => [
    'all',
    'beginner',
    'intermediate',
    'advanced',
    'expert',
  ];

  // Initialize learning provider
  Future<void> initialize([String? userId]) async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentUserId = userId;

      // Load Linux commands from local assets
      await _loadLinuxCommands();

      // Categorize commands
      _categorizeCommands();

      // Load user progress if logged in
      if (_currentUserId != null) {
        await _loadUserProgress();
        _calculateCategoryProgress();
        _generateRecommendations();
      }

      // Apply initial filters
      _applyFilters();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing learning provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load Linux commands from assets
  Future<void> _loadLinuxCommands() async {
    try {
      final String data = await rootBundle.loadString('assets/data/linux_commands.json');
      final List<dynamic> commandsJson = json.decode(data);

      _allCommands = commandsJson.map((json) => LinuxCommand.fromMap(json)).toList();

      // Sort by popularity and difficulty
      _allCommands.sort((a, b) {
        if (a.isPopular && !b.isPopular) return -1;
        if (!a.isPopular && b.isPopular) return 1;
        return a.difficulty.compareTo(b.difficulty);
      });

    } catch (e) {
      debugPrint('Error loading Linux commands: $e');
      // Create some default commands if loading fails
      _createDefaultCommands();
    }
  }

  // Create default commands as fallback
  void _createDefaultCommands() {
    _allCommands = [
      LinuxCommand(
        id: 'ls',
        name: 'ls',
        description: 'แสดงรายการไฟล์และไดเร็กทอรี',
        syntax: 'ls [options] [path]',
        category: 'file_management',
        difficulty: 'beginner',
        examples: ['ls', 'ls -la', 'ls /home'],
        options: [
          CommandOption(flag: '-l', description: 'แสดงรายละเอียดแบบยาว'),
          CommandOption(flag: '-a', description: 'แสดงไฟล์ที่ซ่อนอยู่'),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPopular: true,
      ),
      LinuxCommand(
        id: 'cd',
        name: 'cd',
        description: 'เปลี่ยนไดเร็กทอรี',
        syntax: 'cd [path]',
        category: 'file_management',
        difficulty: 'beginner',
        examples: ['cd /home', 'cd ..', 'cd ~'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPopular: true,
      ),
      LinuxCommand(
        id: 'pwd',
        name: 'pwd',
        description: 'แสดงไดเร็กทอรีปัจจุบัน',
        syntax: 'pwd',
        category: 'file_management',
        difficulty: 'beginner',
        examples: ['pwd'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPopular: true,
      ),
    ];
  }

  // Categorize commands
  void _categorizeCommands() {
    _categorizedCommands.clear();

    for (final category in availableCategories) {
      if (category == 'all') continue;

      _categorizedCommands[category] = _allCommands
          .where((cmd) => cmd.category == category)
          .toList();
    }
  }

  // Load user progress from Firebase
  Future<void> _loadUserProgress() async {
    if (_currentUserId == null) return;

    try {
      _userProgress = await _firebaseService.getLearningProgress(_currentUserId!);
    } catch (e) {
      debugPrint('Error loading user progress: $e');
    }
  }

  // Calculate category progress
  void _calculateCategoryProgress() {
    _categoryProgress.clear();

    for (final category in availableCategories) {
      if (category == 'all') continue;

      final categoryCommands = _categorizedCommands[category] ?? [];
      if (categoryCommands.isEmpty) continue;

      final completedCommands = _userProgress
          .where((progress) =>
      progress.category == category && progress.isCompleted)
          .length;

      _categoryProgress[category] = completedCommands / categoryCommands.length;
    }
  }

  // Generate learning recommendations
  void _generateRecommendations() {
    _recommendedCommands.clear();

    // Get commands the user hasn't completed yet
    final completedCommandNames = _userProgress
        .where((progress) => progress.isCompleted)
        .map((progress) => progress.commandName)
        .toSet();

    final uncompletedCommands = _allCommands
        .where((cmd) => !completedCommandNames.contains(cmd.name))
        .toList();

    // Prioritize by difficulty and popularity
    uncompletedCommands.sort((a, b) {
      final aDifficultyWeight = _getDifficultyWeight(a.difficulty);
      final bDifficultyWeight = _getDifficultyWeight(b.difficulty);

      if (aDifficultyWeight != bDifficultyWeight) {
        return aDifficultyWeight.compareTo(bDifficultyWeight);
      }

      if (a.isPopular && !b.isPopular) return -1;
      if (!a.isPopular && b.isPopular) return 1;

      return 0;
    });

    // Take top 10 recommendations
    _recommendedCommands = uncompletedCommands
        .take(10)
        .map((cmd) => cmd.name)
        .toList();
  }

  int _getDifficultyWeight(String difficulty) {
    switch (difficulty) {
      case 'beginner': return 1;
      case 'intermediate': return 2;
      case 'advanced': return 3;
      case 'expert': return 4;
      default: return 1;
    }
  }

  // Apply filters to commands
  void _applyFilters() {
    _filteredCommands = _allCommands.where((command) {
      // Category filter
      if (_selectedCategory != 'all' && command.category != _selectedCategory) {
        return false;
      }

      // Difficulty filter
      if (_selectedDifficulty != 'all' && command.difficulty != _selectedDifficulty) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return command.name.toLowerCase().contains(query) ||
            command.description.toLowerCase().contains(query) ||
            command.tags.any((tag) => tag.toLowerCase().contains(query));
      }

      return true;
    }).toList();
  }

  // Filter methods
  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();

    _analyticsService.logEvent('filter_category_selected', {
      'category': category,
    });
  }

  void setDifficulty(String difficulty) {
    _selectedDifficulty = difficulty;
    _applyFilters();
    notifyListeners();

    _analyticsService.logEvent('filter_difficulty_selected', {
      'difficulty': difficulty,
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();

    if (query.isNotEmpty) {
      _analyticsService.logEvent('command_searched', {
        'search_term': query,
        'results_count': _filteredCommands.length,
      });
    }
  }

  void clearFilters() {
    _selectedCategory = 'all';
    _selectedDifficulty = 'all';
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  // Get specific command
  LinuxCommand? getCommandById(String id) {
    try {
      return _allCommands.firstWhere((cmd) => cmd.id == id);
    } catch (e) {
      return null;
    }
  }

  LinuxCommand? getCommandByName(String name) {
    try {
      return _allCommands.firstWhere((cmd) => cmd.name == name);
    } catch (e) {
      return null;
    }
  }

  // Get related commands
  List<LinuxCommand> getRelatedCommands(String commandId) {
    final command = getCommandById(commandId);
    if (command == null) return [];

    final relatedIds = command.relatedCommands;
    return _allCommands
        .where((cmd) => relatedIds.contains(cmd.id))
        .toList();
  }

  // Get commands by category
  List<LinuxCommand> getCommandsByCategory(String category) {
    return _categorizedCommands[category] ?? [];
  }

  // Get popular commands
  List<LinuxCommand> getPopularCommands({int limit = 10}) {
    return _allCommands
        .where((cmd) => cmd.isPopular)
        .take(limit)
        .toList();
  }

  // Get commands by difficulty
  List<LinuxCommand> getCommandsByDifficulty(String difficulty) {
    return _allCommands
        .where((cmd) => cmd.difficulty == difficulty)
        .toList();
  }

  // Progress tracking methods
  Future<void> startLearning(String commandId) async {
    final command = getCommandById(commandId);
    if (command == null || _currentUserId == null) return;

    final progressId = '${_currentUserId}_${command.name}';
    final progress = LearningProgress(
      id: progressId,
      userId: _currentUserId!,
      commandName: command.name,
      category: command.category,
      difficulty: command.difficulty,
      startedAt: DateTime.now(),
      progressType: 'lesson',
    );

    // Save to Firebase
    try {
      await _firebaseService.saveLearningProgress(_currentUserId!, progress);
      _userProgress.add(progress);
      notifyListeners();

      _analyticsService.logLessonStarted(
        lessonId: commandId,
        category: command.category,
        difficulty: command.difficulty,
      );
    } catch (e) {
      debugPrint('Error starting learning: $e');
    }
  }

  Future<void> completeLearning(
      String commandId, {
        required double accuracy,
        required int completionTimeInSeconds,
        int attempts = 1,
      }) async {
    final command = getCommandById(commandId);
    if (command == null || _currentUserId == null) return;

    // Find existing progress
    final progressIndex = _userProgress.indexWhere(
          (p) => p.commandName == command.name && p.userId == _currentUserId,
    );

    if (progressIndex != -1) {
      // Update existing progress
      final updatedProgress = _userProgress[progressIndex].copyWith(
        completedAt: DateTime.now(),
        isCompleted: true,
        accuracy: accuracy,
        completionTimeInSeconds: completionTimeInSeconds,
        attempts: attempts,
        xpEarned: _calculateXP(command.difficulty, accuracy),
        overallProgress: 1.0,
      );

      _userProgress[progressIndex] = updatedProgress;

      // Save to Firebase
      try {
        await _firebaseService.saveLearningProgress(_currentUserId!, updatedProgress);

        // Update calculations
        _calculateCategoryProgress();
        _generateRecommendations();
        notifyListeners();

        _analyticsService.logLessonCompleted(
          lessonId: commandId,
          category: command.category,
          difficulty: command.difficulty,
          completionTime: completionTimeInSeconds,
          accuracy: accuracy,
          xpEarned: updatedProgress.xpEarned,
        );
      } catch (e) {
        debugPrint('Error completing learning: $e');
      }
    }
  }

  int _calculateXP(String difficulty, double accuracy) {
    int baseXP = switch (difficulty) {
      'beginner' => FirebaseConstants.defaultXPForBeginner,
      'intermediate' => FirebaseConstants.defaultXPForIntermediate,
      'advanced' => FirebaseConstants.defaultXPForAdvanced,
      'expert' => FirebaseConstants.defaultXPForExpert,
      _ => FirebaseConstants.defaultXPForBeginner,
    };

    return (baseXP * accuracy).round();
  }

  // Get user's progress for a specific command
  LearningProgress? getProgressForCommand(String commandName) {
    if (_currentUserId == null) return null;

    try {
      return _userProgress.firstWhere(
            (progress) => progress.commandName == commandName &&
            progress.userId == _currentUserId,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if command is completed
  bool isCommandCompleted(String commandName) {
    final progress = getProgressForCommand(commandName);
    return progress?.isCompleted ?? false;
  }

  // Get completion percentage for category
  double getCategoryCompletionPercentage(String category) {
    return _categoryProgress[category] ?? 0.0;
  }

  // Get overall completion percentage
  double getOverallCompletionPercentage() {
    if (_allCommands.isEmpty) return 0.0;

    final completedCount = _userProgress
        .where((progress) => progress.isCompleted)
        .length;

    return completedCount / _allCommands.length;
  }

  // Get learning statistics
  Map<String, dynamic> getLearningStatistics() {
    final completedCommands = _userProgress
        .where((progress) => progress.isCompleted)
        .length;

    final totalCommands = _allCommands.length;
    final averageAccuracy = _userProgress
        .where((progress) => progress.isCompleted && progress.accuracy > 0)
        .fold(0.0, (sum, progress) => sum + progress.accuracy) /
        _userProgress.where((progress) => progress.isCompleted && progress.accuracy > 0).length;

    final totalTime = _userProgress
        .where((progress) => progress.isCompleted)
        .fold(0, (sum, progress) => sum + progress.completionTimeInSeconds);

    return {
      'completedCommands': completedCommands,
      'totalCommands': totalCommands,
      'completionPercentage': (completedCommands / totalCommands) * 100,
      'averageAccuracy': averageAccuracy.isNaN ? 0.0 : averageAccuracy,
      'totalTimeSpent': totalTime,
      'categoriesCompleted': _categoryProgress.values.where((p) => p >= 1.0).length,
      'currentStreak': _getCurrentStreak(),
    };
  }

  int _getCurrentStreak() {
    if (_userProgress.isEmpty) return 0;

    // Sort by completion date
    final completedProgress = _userProgress
        .where((progress) => progress.isCompleted && progress.completedAt != null)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    if (completedProgress.isEmpty) return 0;

    int streak = 1;
    DateTime lastDate = completedProgress.first.completedAt!;

    for (int i = 1; i < completedProgress.length; i++) {
      final currentDate = completedProgress[i].completedAt!;
      final difference = lastDate.difference(currentDate).inDays;

      if (difference <= 1) {
        streak++;
        lastDate = currentDate;
      } else {
        break;
      }
    }

    // Check if streak is still active (within last 2 days)
    final now = DateTime.now();
    final daysSinceLastActivity = now.difference(lastDate).inDays;

    return daysSinceLastActivity <= 2 ? streak : 0;
  }

  // Set learning path
  void setLearningPath(String path) {
    _currentLearningPath = path;
    _generateRecommendations();
    notifyListeners();

    _analyticsService.logEvent(FirebaseConstants.eventLearningPathChanged, {
      'new_path': path,
    });
  }

  // Refresh data
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUserId != null) {
        await _loadUserProgress();
        _calculateCategoryProgress();
        _generateRecommendations();
      }

      _applyFilters();
    } catch (e) {
      debugPrint('Error refreshing learning data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset learning data
  void reset() {
    _userProgress.clear();
    _categoryProgress.clear();
    _recommendedCommands.clear();
    _selectedCategory = 'all';
    _selectedDifficulty = 'all';
    _searchQuery = '';
    _currentLearningPath = 'beginner';
    _applyFilters();
    notifyListeners();
  }
}
'