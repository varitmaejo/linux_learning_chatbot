import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/colors.dart';
import '../../data/models/quiz.dart';

class QuizWidget extends StatefulWidget {
  final Quiz quiz;
  final Function(QuizResult) onQuizCompleted;
  final VoidCallback? onQuizSkipped;
  final bool showTimer;
  final Duration? timeLimit;

  const QuizWidget({
    Key? key,
    required this.quiz,
    required this.onQuizCompleted,
    this.onQuizSkipped,
    this.showTimer = false,
    this.timeLimit,
  }) : super(key: key);

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget>
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  Map<int, int> _selectedAnswers = {};
  Timer? _timer;
  int _remainingTime = 0;
  bool _isCompleted = false;

  late AnimationController _questionAnimationController;
  late AnimationController _timerAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupTimer();
  }

  void _setupAnimations() {
    _questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _timerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.easeIn,
    ));

    _questionAnimationController.forward();
  }

  void _setupTimer() {
    if (widget.showTimer && widget.timeLimit != null) {
      _remainingTime = widget.timeLimit!.inSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && !_isCompleted) {
          setState(() {
            _remainingTime--;
          });

          if (_remainingTime <= 10) {
            _timerAnimationController.repeat(reverse: true);
          }

          if (_remainingTime <= 0) {
            _completeQuiz();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _questionAnimationController.dispose();
    _timerAnimationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _selectAnswer(int answerIndex) {
    if (_isCompleted) return;

    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      _questionAnimationController.reset();
      setState(() {
        _currentQuestionIndex++;
      });
      _questionAnimationController.forward();
    } else {
      _completeQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _questionAnimationController.reset();
      setState(() {
        _currentQuestionIndex--;
      });
      _questionAnimationController.forward();
    }
  }

  void _completeQuiz() {
    if (_isCompleted) return;

    setState(() {
      _isCompleted = true;
    });

    _timer?.cancel();
    _timerAnimationController.stop();

    final result = _calculateResult();
    widget.onQuizCompleted(result);
  }

  QuizResult _calculateResult() {
    int correctAnswers = 0;
    int totalQuestions = widget.quiz.questions.length;

    for (int i = 0; i < totalQuestions; i++) {
      final question = widget.quiz.questions[i];
      final selectedAnswer = _selectedAnswers[i];

      if (selectedAnswer != null && selectedAnswer == question.correctAnswerIndex) {
        correctAnswers++;
      }
    }

    final score = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;
    final timeTaken = widget.timeLimit != null
        ? widget.timeLimit!.inSeconds - _remainingTime
        : 0;

    return QuizResult(
      quizId: widget.quiz.id,
      score: score,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      timeTaken: timeTaken,
      answers: _selectedAnswers,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompletionMessage();
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: AnimatedBuilder(
            animation: _questionAnimationController,
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildQuestionCard(),
                ),
              );
            },
          ),
        ),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.quiz.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.onQuizSkipped != null)
                TextButton(
                  onPressed: widget.onQuizSkipped,
                  child: const Text('ข้าม'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (widget.showTimer && widget.timeLimit != null) ...[
            const SizedBox(height: 12),
            _buildTimer(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final minutes = _remainingTime ~/ 60;
    final seconds = _remainingTime % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    Color timerColor = AppColors.primaryColor;
    if (_remainingTime <= 30) {
      timerColor = Colors.red;
    } else if (_remainingTime <= 60) {
      timerColor = Colors.orange;
    }

    return AnimatedBuilder(
      animation: _timerAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _remainingTime <= 10 ? 1.0 + (_timerAnimationController.value * 0.1) : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: timerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: timerColor, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, color: timerColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  timeString,
                  style: TextStyle(
                    color: timerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard() {
    final question = widget.quiz.questions[_currentQuestionIndex];
    final selectedAnswer = _selectedAnswers[_currentQuestionIndex];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.question,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...question.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = selectedAnswer == index;

                return _buildAnswerOption(option, index, isSelected);
              }).toList(),
              if (question.hint.isNotEmpty) ...[
                const SizedBox(height: 16),
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
                          'คำใบ้: ${question.hint}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerOption(String option, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.black87,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final hasSelected = _selectedAnswers.containsKey(_currentQuestionIndex);
    final isLastQuestion = _currentQuestionIndex == widget.quiz.questions.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _previousQuestion,
                child: const Text('ย้อนกลับ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _currentQuestionIndex > 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: hasSelected
                  ? (isLastQuestion ? _completeQuiz : _nextQuestion)
                  : null,
              child: Text(isLastQuestion ? 'เสร็จสิ้น' : 'ถัดไป'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionMessage() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.quiz,
              size: 64,
              color: AppColors.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'แบบทดสอบเสร็จสิ้น!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'กำลังประมวลผลคะแนน...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

// Quiz Result Widget
class QuizResultWidget extends StatefulWidget {
  final QuizResult result;
  final Quiz quiz;
  final VoidCallback? onRetry;
  final VoidCallback? onContinue;

  const QuizResultWidget({
    Key? key,
    required this.result,
    required this.quiz,
    this.onRetry,
    this.onContinue,
  }) : super(key: key);

  @override
  State<QuizResultWidget> createState() => _QuizResultWidgetState();
}

class _QuizResultWidgetState extends State<QuizResultWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: widget.result.score,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildResultHeader(),
              const SizedBox(height: 32),
              _buildScoreCard(),
              const SizedBox(height: 24),
              _buildStatsCard(),
              const SizedBox(height: 24),
              _buildAnswersReview(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            children: [
              Icon(
                _getResultIcon(),
                size: 80,
                color: _getResultColor(),
              ),
              const SizedBox(height: 16),
              Text(
                _getResultTitle(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getResultColor(),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getResultSubtitle(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoreCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [_getResultColor().withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              'คะแนนของคุณ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _scoreAnimation,
              builder: (context, child) {
                return Text(
                  '${_scoreAnimation.value.round()}%',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getResultColor(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.result.correctAnswers}/${widget.result.totalQuestions} ข้อถูก',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.timer,
              label: 'เวลาที่ใช้',
              value: _formatTime(widget.result.timeTaken),
            ),
            _buildStatItem(
              icon: Icons.quiz,
              label: 'จำนวนข้อ',
              value: '${widget.result.totalQuestions}',
            ),
            _buildStatItem(
              icon: Icons.percent,
              label: 'เปอร์เซ็นต์',
              value: '${widget.result.score.round()}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswersReview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'รายละเอียดคำตอบ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.quiz.questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              final selectedAnswer = widget.result.answers[index];
              final isCorrect = selectedAnswer == question.correctAnswerIndex;

              return _buildAnswerReviewItem(
                question: question,
                questionIndex: index,
                selectedAnswer: selectedAnswer,
                isCorrect: isCorrect,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerReviewItem({
    required QuizQuestion question,
    required int questionIndex,
    int? selectedAnswer,
    required bool isCorrect,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ข้อ ${questionIndex + 1}: ${question.question}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isCorrect ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedAnswer != null) ...[
            Text(
              'คำตอบของคุณ: ${question.options[selectedAnswer]}',
              style: TextStyle(
                color: isCorrect ? Colors.green[700] : Colors.red[700],
              ),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 4),
              Text(
                'คำตอบที่ถูก: ${question.options[question.correctAnswerIndex]}',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ] else ...[
            Text(
              'ไม่ได้ตอบ - คำตอบที่ถูก: ${question.options[question.correctAnswerIndex]}',
              style: TextStyle(
                color: Colors.red[700],
              ),
            ),
          ],
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'คำอธิบาย: ${question.explanation}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.onRetry != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('ทำแบบทดสอบใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (widget.onRetry != null && widget.onContinue != null)
          const SizedBox(height: 12),
        if (widget.onContinue != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onContinue,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('เรียนต่อ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side: BorderSide(color: AppColors.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getBackgroundColor() {
    final score = widget.result.score;
    if (score >= 80) return Colors.green.withOpacity(0.1);
    if (score >= 60) return Colors.orange.withOpacity(0.1);
    return Colors.red.withOpacity(0.1);
  }

  Color _getResultColor() {
    final score = widget.result.score;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getResultIcon() {
    final score = widget.result.score;
    if (score >= 80) return Icons.emoji_events;
    if (score >= 60) return Icons.thumb_up;
    return Icons.sentiment_dissatisfied;
  }

  String _getResultTitle() {
    final score = widget.result.score;
    if (score >= 80) return 'ยอดเยี่ยม!';
    if (score >= 60) return 'ดีมาก!';
    return 'ต้องพยายามอีกนิด';
  }

  String _getResultSubtitle() {
    final score = widget.result.score;
    if (score >= 80) return 'คุณเข้าใจเนื้อหาเป็นอย่างดี';
    if (score >= 60) return 'คุณมีความเข้าใจในระดับดี';
    return 'ลองทบทวนเนื้อหาและทำใหม่อีกครั้ง';
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}