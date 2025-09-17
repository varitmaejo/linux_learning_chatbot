import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../data/models/lesson.dart';

class LessonWidget extends StatefulWidget {
  final Lesson lesson;
  final VoidCallback? onStart;
  final VoidCallback? onContinue;
  final VoidCallback? onComplete;
  final bool isUnlocked;
  final double progress;

  const LessonWidget({
    Key? key,
    required this.lesson,
    this.onStart,
    this.onContinue,
    this.onComplete,
    this.isUnlocked = true,
    this.progress = 0.0,
  }) : super(key: key);

  @override
  State<LessonWidget> createState() => _LessonWidgetState();
}

class _LessonWidgetState extends State<LessonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    if (widget.progress > 0) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(LessonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isUnlocked) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isUnlocked) {
      _animationController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.isUnlocked) {
      _animationController.reverse();
    }
  }

  void _handleTap() {
    if (!widget.isUnlocked) return;

    if (widget.progress == 0.0) {
      widget.onStart?.call();
    } else if (widget.progress < 1.0) {
      widget.onContinue?.call();
    } else {
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              elevation: widget.isUnlocked ? 3 : 1,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: widget.isUnlocked
                      ? _getLessonGradient()
                      : LinearGradient(
                    colors: [Colors.grey[300]!, Colors.grey[200]!],
                  ),
                ),
                child: Stack(
                  children: [
                    _buildBackground(),
                    _buildContent(),
                    if (!widget.isUnlocked) _buildLockedOverlay(),
                    _buildProgressIndicator(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: widget.isUnlocked
              ? _getLessonGradient().createShader(const Rect.fromLTWH(0, 0, 100, 100)) != null
              ? _getLessonGradient()
              : null
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              image: widget.lesson.imageUrl.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(widget.lesson.imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLessonBadge(),
              _buildDifficultyBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.lesson.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.isUnlocked ? Colors.white : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.lesson.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: widget.isUnlocked
                  ? Colors.white.withOpacity(0.9)
                  : Colors.grey[500],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          _buildLessonInfo(),
          const SizedBox(height: 16),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildLessonBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        'บทเรียนที่ ${widget.lesson.order}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge() {
    Color badgeColor;
    String difficultyText;

    switch (widget.lesson.difficulty) {
      case LessonDifficulty.beginner:
        badgeColor = Colors.green;
        difficultyText = 'เริ่มต้น';
        break;
      case LessonDifficulty.intermediate:
        badgeColor = Colors.orange;
        difficultyText = 'ปานกลาง';
        break;
      case LessonDifficulty.advanced:
        badgeColor = Colors.red;
        difficultyText = 'ขั้นสูง';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        difficultyText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLessonInfo() {
    return Row(
      children: [
        _buildInfoChip(
          icon: Icons.schedule,
          text: '${widget.lesson.estimatedDuration} นาที',
        ),
        const SizedBox(width: 12),
        _buildInfoChip(
          icon: Icons.psychology,
          text: '${widget.lesson.topics.length} หัวข้อ',
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    String buttonText;
    IconData buttonIcon;

    if (widget.progress == 0.0) {
      buttonText = 'เริ่มเรียน';
      buttonIcon = Icons.play_arrow;
    } else if (widget.progress < 1.0) {
      buttonText = 'เรียนต่อ';
      buttonIcon = Icons.play_arrow;
    } else {
      buttonText = 'ทบทวน';
      buttonIcon = Icons.replay;
    }

    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.isUnlocked ? _handleTap : null,
        icon: Icon(buttonIcon, size: 18),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: widget.isUnlocked
              ? AppColors.primaryColor
              : Colors.grey[600],
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withOpacity(0.6),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 48,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(height: 8),
              Text(
                'ล็อค',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ต้องจบบทเรียนก่อนหน้า',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (widget.progress == 0.0) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Container(
            height: 4,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 4,
              ),
            ),
          );
        },
      ),
    );
  }

  LinearGradient _getLessonGradient() {
    switch (widget.lesson.difficulty) {
      case LessonDifficulty.beginner:
        return const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case LessonDifficulty.intermediate:
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFC107)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case LessonDifficulty.advanced:
        return const LinearGradient(
          colors: [Color(0xFFF44336), Color(0xFFE91E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

// Compact Lesson Card for lists
class CompactLessonWidget extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback? onTap;
  final bool isUnlocked;
  final double progress;

  const CompactLessonWidget({
    Key? key,
    required this.lesson,
    this.onTap,
    this.isUnlocked = true,
    this.progress = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(
          lesson.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isUnlocked ? null : Colors.grey[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUnlocked ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            if (progress > 0)
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                minHeight: 2,
              ),
          ],
        ),
        trailing: _buildTrailingWidget(),
        onTap: isUnlocked ? onTap : null,
        enabled: isUnlocked,
      ),
    );
  }

  Widget _buildLeadingIcon() {
    if (!isUnlocked) {
      return const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.lock, color: Colors.white, size: 20),
      );
    }

    Color backgroundColor;
    switch (lesson.difficulty) {
      case LessonDifficulty.beginner:
        backgroundColor = Colors.green;
        break;
      case LessonDifficulty.intermediate:
        backgroundColor = Colors.orange;
        break;
      case LessonDifficulty.advanced:
        backgroundColor = Colors.red;
        break;
    }

    IconData iconData;
    if (progress == 1.0) {
      iconData = Icons.check;
    } else if (progress > 0) {
      iconData = Icons.play_arrow;
    } else {
      iconData = Icons.school;
    }

    return CircleAvatar(
      backgroundColor: backgroundColor,
      child: Icon(iconData, color: Colors.white, size: 20),
    );
  }

  Widget _buildTrailingWidget() {
    if (!isUnlocked) {
      return const SizedBox.shrink();
    }

    if (progress == 1.0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(height: 2),
          Text(
            'เสร็จแล้ว',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (progress > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'กำลังเรียน',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      );
    }

    return Text(
      '${lesson.estimatedDuration} นาที',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }
}

// Lesson Topic Widget
class LessonTopicWidget extends StatefulWidget {
  final LessonTopic topic;
  final bool isCompleted;
  final bool isCurrentTopic;
  final VoidCallback? onTap;

  const LessonTopicWidget({
    Key? key,
    required this.topic,
    this.isCompleted = false,
    this.isCurrentTopic = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<LessonTopicWidget> createState() => _LessonTopicWidgetState();
}

class _LessonTopicWidgetState extends State<LessonTopicWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isCurrentTopic) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LessonTopicWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTopic != oldWidget.isCurrentTopic) {
      if (widget.isCurrentTopic) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isCurrentTopic ? _pulseAnimation.value : 1.0,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: widget.isCurrentTopic ? 4 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: widget.isCurrentTopic
                      ? AppColors.primaryColor
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ExpansionTile(
                leading: _buildTopicIcon(),
                title: Text(
                  widget.topic.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: widget.isCompleted
                        ? Colors.green
                        : (widget.isCurrentTopic
                        ? AppColors.primaryColor
                        : null),
                  ),
                ),
                subtitle: Text(
                  widget.topic.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.topic.content.isNotEmpty) ...[
                          Text(
                            'เนื้อหา',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.topic.content,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (widget.topic.commands.isNotEmpty) ...[
                          Text(
                            'คำสั่งที่เกี่ยวข้อง',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.topic.commands.map((command) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  command,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (widget.topic.examples.isNotEmpty) ...[
                          Text(
                            'ตัวอย่าง',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.topic.examples.map((example) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '$ ',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      color: Colors.green[400],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      example,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        color: Colors.green[300],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopicIcon() {
    if (widget.isCompleted) {
      return const CircleAvatar(
        backgroundColor: Colors.green,
        radius: 16,
        child: Icon(
          Icons.check,
          color: Colors.white,
          size: 18,
        ),
      );
    }

    if (widget.isCurrentTopic) {
      return CircleAvatar(
        backgroundColor: AppColors.primaryColor,
        radius: 16,
        child: const Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 18,
        ),
      );
    }

    return CircleAvatar(
      backgroundColor: Colors.grey[300],
      radius: 16,
      child: Text(
        '${widget.topic.order}',
        style: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

// Lesson Progress Widget
class LessonProgressWidget extends StatelessWidget {
  final List<Lesson> lessons;
  final Map<String, double> lessonProgress;
  final Function(Lesson) onLessonTap;

  const LessonProgressWidget({
    Key? key,
    required this.lessons,
    required this.lessonProgress,
    required this.onLessonTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completedLessons = lessons.where((lesson) =>
    lessonProgress[lesson.id] == 1.0).length;
    final totalLessons = lessons.length;
    final overallProgress = totalLessons > 0
        ? completedLessons / totalLessons
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ความคืบหน้า',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$completedLessons/$totalLessons บทเรียน',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: overallProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lessons.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final progress = lessonProgress[lesson.id] ?? 0.0;
              final isUnlocked = _isLessonUnlocked(lesson, index);

              return CompactLessonWidget(
                lesson: lesson,
                progress: progress,
                isUnlocked: isUnlocked,
                onTap: () => onLessonTap(lesson),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isLessonUnlocked(Lesson lesson, int index) {
    if (index == 0) return true; // First lesson is always unlocked

    final previousLesson = lessons[index - 1];
    final previousProgress = lessonProgress[previousLesson.id] ?? 0.0;

    return previousProgress >= 1.0; // Previous lesson must be completed
  }
}