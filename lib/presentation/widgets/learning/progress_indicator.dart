import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/colors.dart';

class CustomProgressIndicator extends StatefulWidget {
  final double progress;
  final Color? progressColor;
  final Color? backgroundColor;
  final double strokeWidth;
  final double size;
  final bool showPercentage;
  final String? label;
  final Duration animationDuration;

  const CustomProgressIndicator({
    Key? key,
    required this.progress,
    this.progressColor,
    this.backgroundColor,
    this.strokeWidth = 8.0,
    this.size = 100.0,
    this.showPercentage = true,
    this.label,
    this.animationDuration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  State<CustomProgressIndicator> createState() => _CustomProgressIndicatorState();
}

class _CustomProgressIndicatorState extends State<CustomProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void didUpdateWidget(CustomProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));

      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircularProgressPainter(
                  progress: _progressAnimation.value,
                  progressColor: widget.progressColor ?? AppColors.primaryColor,
                  backgroundColor: widget.backgroundColor ?? Colors.grey[300]!,
                  strokeWidth: widget.strokeWidth,
                ),
              );
            },
          ),
          if (widget.showPercentage || widget.label != null)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.showPercentage)
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Text(
                        '${(_progressAnimation.value * 100).round()}%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.progressColor ?? AppColors.primaryColor,
                        ),
                      );
                    },
                  ),
                if (widget.label != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.label!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// Linear Progress Indicator with Animation
class AnimatedLinearProgress extends StatefulWidget {
  final double progress;
  final Color? progressColor;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final Duration animationDuration;
  final String? label;
  final bool showPercentage;

  const AnimatedLinearProgress({
    Key? key,
    required this.progress,
    this.progressColor,
    this.backgroundColor,
    this.height = 8.0,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 800),
    this.label,
    this.showPercentage = false,
  }) : super(key: key);

  @override
  State<AnimatedLinearProgress> createState() => _AnimatedLinearProgressState();
}

class _AnimatedLinearProgressState extends State<AnimatedLinearProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void didUpdateWidget(AnimatedLinearProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));

      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null || widget.showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (widget.showPercentage)
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Text(
                        '${(_progressAnimation.value * 100).round()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.progressColor ?? AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.grey[300],
            borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.progressColor ?? AppColors.primaryColor,
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Multi-level Progress Indicator
class MultiLevelProgress extends StatelessWidget {
  final List<ProgressLevel> levels;
  final double height;
  final BorderRadius? borderRadius;

  const MultiLevelProgress({
    Key? key,
    required this.levels,
    this.height = 12.0,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
        child: Row(
          children: levels.map((level) {
            return Expanded(
              flex: (level.value * 100).round(),
              child: Container(
                color: level.color,
                child: level.showLabel && level.label != null
                    ? Center(
                  child: Text(
                    level.label!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: height * 0.6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ProgressLevel {
  final double value;
  final Color color;
  final String? label;
  final bool showLabel;

  const ProgressLevel({
    required this.value,
    required this.color,
    this.label,
    this.showLabel = false,
  });
}

// Skill Progress Widget
class SkillProgressWidget extends StatelessWidget {
  final String skillName;
  final double progress;
  final int currentLevel;
  final int maxLevel;
  final Color? progressColor;
  final IconData? skillIcon;

  const SkillProgressWidget({
    Key? key,
    required this.skillName,
    required this.progress,
    required this.currentLevel,
    required this.maxLevel,
    this.progressColor,
    this.skillIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (skillIcon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (progressColor ?? AppColors.primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    skillIcon,
                    color: progressColor ?? AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skillName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ระดับ $currentLevel/$maxLevel',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: progressColor ?? AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedLinearProgress(
            progress: progress,
            progressColor: progressColor ?? AppColors.primaryColor,
            height: 6,
          ),
        ],
      ),
    );
  }
}

// Progress Stats Widget
class ProgressStatsWidget extends StatelessWidget {
  final List<ProgressStat> stats;
  final EdgeInsetsGeometry? padding;

  const ProgressStatsWidget({
    Key? key,
    required this.stats,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: stats.length > 2 ? 2 : stats.length,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return _buildStatCard(context, stat);
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, ProgressStat stat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stat.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stat.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            stat.icon,
            color: stat.color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: stat.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ProgressStat {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const ProgressStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}