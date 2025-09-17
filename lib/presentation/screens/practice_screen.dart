import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/learning_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/terminal/virtual_terminal.dart';
import '../widgets/learning/command_card.dart';
import '../widgets/learning/quiz_widget.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/achievement_badge.dart';
import '../core/theme/colors.dart';
import '../data/models/practice_session.dart';
import '../data/models/linux_command.dart';
import '../data/models/quiz.dart';

class PracticeScreen extends StatefulWidget {
  final String? topicId;
  final LinuxCommand? specificCommand;

  const PracticeScreen({
    Key? key,
    this.topicId,
    this.specificCommand,
  }) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  PracticeSession? _currentSession;
  int _currentChallengeIndex = 0;
  bool _isSessionActive = false;
  Map<String, dynamic> _sessionProgress = {};

  // Practice modes
  PracticeMode _selectedMode = PracticeMode.guided;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializePracticeSession();
  }

  void _initializePracticeSession() {
    final learningProvider = Provider.of<LearningProvider>(context, listen: false);

    if (widget.specificCommand != null) {
      _currentSession = PracticeSession.fromCommand(widget.specificCommand!);
    } else if (widget.topicId != null) {
      _currentSession = PracticeSession.fromTopic(widget.topicId!);
    } else {
      _currentSession = learningProvider.getCurrentPracticeSession();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _currentSession == null
          ? _buildSessionSelector()
          : _buildPracticeContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_currentSession?.title ?? 'Practice'),
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      bottom: _currentSession != null
          ? TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Challenges', icon: Icon(Icons.quiz)),
          Tab(text: 'Terminal', icon: Icon(Icons.terminal)),
          Tab(text: 'Progress', icon: Icon(Icons.analytics)),
        ],
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
      )
          : null,
      actions: [
        if (_isSessionActive)
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: _pauseSession,
            tooltip: 'Pause Session',
          ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restart',
              child: ListTile(
                leading: Icon(Icons.restart_alt),
                title: Text('Restart Session'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Practice Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: ListTile(
                leading: Icon(Icons.help),
                title: Text('Help & Tips'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: _handleMenuAction,
        ),
      ],
    );
  }

  Widget _buildSessionSelector() {
    return Consumer<LearningProvider>(
      builder: (context, learningProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildPracticeModeSelector(),
              const SizedBox(height: 24),
              _buildTopicSelector(learningProvider),
              const SizedBox(height: 24),
              _buildQuickPracticeOptions(),
              const SizedBox(height: 24),
              _buildRecentSessions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Practice Time!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Improve your Linux skills with hands-on practice',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<ProgressProvider>(
            builder: (context, progressProvider, child) {
              final streakDays = progressProvider.currentStreak;
              return Row(
                children: [
                  _buildStatChip(
                    icon: Icons.local_fire_department,
                    label: '$streakDays day streak',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    icon: Icons.star,
                    label: '${progressProvider.totalScore} points',
                    color: Colors.yellow,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Practice Mode',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildModeCard(
                mode: PracticeMode.guided,
                title: 'Guided',
                description: 'Step-by-step instructions',
                icon: Icons.school,
                isSelected: _selectedMode == PracticeMode.guided,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModeCard(
                mode: PracticeMode.challenge,
                title: 'Challenge',
                description: 'Test your skills',
                icon: Icons.emoji_events,
                isSelected: _selectedMode == PracticeMode.challenge,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModeCard(
                mode: PracticeMode.sandbox,
                title: 'Sandbox',
                description: 'Free exploration',
                icon: Icons.science,
                isSelected: _selectedMode == PracticeMode.sandbox,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required PracticeMode mode,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primaryColor : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primaryColor : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSelector(LearningProvider learningProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Choose Topic',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Show all topics
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: learningProvider.availableTopics.length,
            itemBuilder: (context, index) {
              final topic = learningProvider.availableTopics[index];
              return _buildTopicCard(topic);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _startPracticeSession(topic['id']),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  topic['icon'] as IconData,
                  size: 32,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  topic['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                LinearProgressIndicator(
                  value: topic['progress'] as double,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  minHeight: 3,
                ),
                const SizedBox(height: 4),
                Text(
                  '${((topic['progress'] as double) * 100).round()}% complete',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPracticeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Practice',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildQuickOption(
              title: 'Random Challenge',
              icon: Icons.shuffle,
              color: Colors.purple,
              onTap: _startRandomChallenge,
            ),
            _buildQuickOption(
              title: 'Daily Practice',
              icon: Icons.today,
              color: Colors.blue,
              onTap: _startDailyPractice,
            ),
            _buildQuickOption(
              title: 'Weak Areas',
              icon: Icons.trending_up,
              color: Colors.orange,
              onTap: _practiceWeakAreas,
            ),
            _buildQuickOption(
              title: 'Speed Test',
              icon: Icons.speed,
              color: Colors.green,
              onTap: _startSpeedTest,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickOption({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSessions() {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final recentSessions = progressProvider.recentPracticeSessions;

        if (recentSessions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Sessions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...recentSessions.map((session) => _buildRecentSessionCard(session)),
          ],
        );
      },
    );
  }

  Widget _buildRecentSessionCard(Map<String, dynamic> session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSessionStatusColor(session['status']).withOpacity(0.2),
          child: Icon(
            _getSessionStatusIcon(session['status']),
            color: _getSessionStatusColor(session['status']),
          ),
        ),
        title: Text(session['title']),
        subtitle: Text(
          '${session['completedChallenges']}/${session['totalChallenges']} challenges • ${session['duration']}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session['status'] == 'paused')
              const Icon(Icons.play_arrow, color: Colors.blue),
            Text(
              '${session['score']} pts',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () => _resumeSession(session),
      ),
    );
  }

  Widget _buildPracticeContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildChallengesTab(),
        _buildTerminalTab(),
        _buildProgressTab(),
      ],
    );
  }

  Widget _buildChallengesTab() {
    if (_currentSession?.challenges.isEmpty == true) {
      return const Center(
        child: Text('No challenges available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSessionHeader(),
          const SizedBox(height: 16),
          _buildCurrentChallenge(),
          const SizedBox(height: 16),
          _buildChallengesList(),
        ],
      ),
    );
  }

  Widget _buildSessionHeader() {
    if (_currentSession == null) return const SizedBox.shrink();

    final completedChallenges = _sessionProgress.values
        .where((status) => status == 'completed')
        .length;
    final totalChallenges = _currentSession!.challenges.length;
    final progress = totalChallenges > 0 ? completedChallenges / totalChallenges : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentSession!.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentSession!.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.psychology,
                  color: AppColors.primaryColor,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedChallenges/$totalChallenges challenges',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              if (!_isSessionActive)
                ElevatedButton(
                  onPressed: _startSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Start Session'),
                ),
              if (_isSessionActive)
                ElevatedButton(
                  onPressed: _pauseSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Pause'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentChallenge() {
    if (_currentSession == null || _currentChallengeIndex >= _currentSession!.challenges.length) {
      return const SizedBox.shrink();
    }

    final challenge = _currentSession!.challenges[_currentChallengeIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Challenge ${_currentChallengeIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              _buildDifficultyBadge(challenge.difficulty),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            challenge.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (challenge.type == ChallengeType.quiz)
            _buildQuizChallenge(challenge)
          else if (challenge.type == ChallengeType.command)
            _buildCommandChallenge(challenge)
          else if (challenge.type == ChallengeType.scenario)
              _buildScenarioChallenge(challenge),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(ChallengeDifficulty difficulty) {
    Color color;
    String text;

    switch (difficulty) {
      case ChallengeDifficulty.easy:
        color = Colors.green;
        text = 'Easy';
        break;
      case ChallengeDifficulty.medium:
        color = Colors.orange;
        text = 'Medium';
        break;
      case ChallengeDifficulty.hard:
        color = Colors.red;
        text = 'Hard';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuizChallenge(PracticeChallenge challenge) {
    if (challenge.quiz == null) return const SizedBox.shrink();

    return QuizWidget(
      quiz: challenge.quiz!,
      onQuizCompleted: _onChallengeCompleted,
      showTimer: true,
      timeLimit: const Duration(minutes: 5),
    );
  }

  Widget _buildCommandChallenge(PracticeChallenge challenge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (challenge.hint.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hint: ${challenge.hint}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Open Terminal',
                icon: Icons.terminal,
                onPressed: () {
                  _tabController.animateTo(1); // Switch to terminal tab
                },
              ),
            ),
            const SizedBox(width: 12),
            CustomButton(
              text: 'Get Help',
              type: ButtonType.outline,
              icon: Icons.help,
              onPressed: _showChallengeHelp,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScenarioChallenge(PracticeChallenge challenge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scenario:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                challenge.scenario ?? '',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Start Challenge',
                onPressed: () => _startScenario(challenge),
              ),
            ),
            const SizedBox(width: 12),
            CustomButton(
              text: 'View Steps',
              type: ButtonType.outline,
              onPressed: () => _showScenarioSteps(challenge),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChallengesList() {
    if (_currentSession == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      const Text(
      'All Challenges',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    const SizedBox(height: 12),
    ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _currentSession!.challenges.length,
    itemBuilder: (context, index) {
    final challenge = _currentSession!.challenges[index];
    final status = _sessionProgress[challenge.id] ?? 'pending';
    final isCurrentChallenge =