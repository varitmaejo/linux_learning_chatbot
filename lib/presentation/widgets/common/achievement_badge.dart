import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../data/models/achievement.dart';

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final VoidCallback? onTap;
  final double size;
  final bool showProgress;

  const AchievementBadge({
    Key? key,
    required this.achievement,
    required this.isUnlocked,
    this.onTap,
    this.size = 80.0,
    this.showProgress = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size + (showProgress ? 20 : 0),
        child: Column(
          children: [
            _buildBadge(context),
            if (showProgress && !isUnlocked) _buildProgressBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isUnlocked
            ? _getGradientForType(achievement.type)
            : LinearGradient(
          colors: [Colors.grey[400]!, Colors.grey[300]!],
        ),
        border: Border.all(
          color: isUnlocked
              ? _getBorderColorForType(achievement.type)
              : Colors.grey[400]!,
          width: 2,
        ),
        boxShadow: [
          if (isUnlocked) BoxShadow(
            color: _getBorderColorForType(achievement.type).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _getIconForType(achievement.type),
            size: size * 0.4,
            color: isUnlocked ? Colors.white : Colors.grey[600],
          ),
          if (!isUnlocked)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.4),
              ),
              child: Icon(
                Icons.lock,
                size: size * 0.25,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = achievement.progress / achievement.maxProgress;
    return Container(
      width: size,
      height: 4,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: Colors.grey[300],
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }

  LinearGradient _getGradientForType(AchievementType type) {
    switch (type) {
      case AchievementType.bronze:
        return const LinearGradient(
          colors: [Color(0xFFCD7F32), Color(0xFFB8860B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AchievementType.silver:
        return const LinearGradient(
          colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AchievementType.gold:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AchievementType.platinum:
        return const LinearGradient(
          colors: [Color(0xFFE5E4E2), Color(0xFF9C9C9C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AchievementType.diamond:
        return const LinearGradient(
          colors: [Color(0xFFB9F2FF), Color(0xFF00BFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AchievementType.special:
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getBorderColorForType(AchievementType type) {
    switch (type) {
      case AchievementType.bronze:
        return const Color(0xFFCD7F32);
      case AchievementType.silver:
        return const Color(0xFFC0C0C0);
      case AchievementType.gold:
        return const Color(0xFFFFD700);
      case AchievementType.platinum:
        return const Color(0xFFE5E4E2);
      case AchievementType.diamond:
        return const Color(0xFFB9F2FF);
      case AchievementType.special:
        return const Color(0xFFFF6B6B);
    }
  }

  IconData _getIconForType(AchievementType type) {
    switch (type) {
      case AchievementType.bronze:
      case AchievementType.silver:
      case AchievementType.gold:
        return Icons.emoji_events;
      case AchievementType.platinum:
        return Icons.military_tech;
      case AchievementType.diamond:
        return Icons.diamond;
      case AchievementType.special:
        return Icons.star;
    }
  }
}

// Achievement card with details
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const AchievementCard({
    Key? key,
    required this.achievement,
    required this.isUnlocked,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AchievementBadge(
                achievement: achievement,
                isUnlocked: isUnlocked,
                size: 60,
                showProgress: !isUnlocked,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? null
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isUnlocked
                            ? Colors.grey[600]
                            : Colors.grey[500],
                      ),
                    ),
                    if (!isUnlocked) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${achievement.progress}/${achievement.maxProgress}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (isUnlocked && achievement.unlockedDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'ปลดล็อก: ${_formatDate(achievement.unlockedDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isUnlocked)
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Achievement notification popup
class AchievementNotification extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onDismiss;

  const AchievementNotification({
    Key? key,
    required this.achievement,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<AchievementNotification> createState() => _AchievementNotificationState();

  static void show(
      BuildContext context,
      Achievement achievement, {
        Duration duration = const Duration(seconds: 4),
      }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => AchievementNotification(
        achievement: achievement,
        onDismiss: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);

    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}

class _AchievementNotificationState extends State<AchievementNotification>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimations() async {
    await _slideController.forward();
    await _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber[400]!,
                    Colors.amber[600]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AchievementBadge(
                    achievement: widget.achievement,
                    isUnlocked: true,
                    size: 50,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ปลดล็อกความสำเร็จ!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.achievement.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Achievement progress widget
class AchievementProgress extends StatelessWidget {
  final List<Achievement> achievements;
  final Function(Achievement) onAchievementTap;

  const AchievementProgress({
    Key? key,
    required this.achievements,
    required this.onAchievementTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;
    final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ความสำเร็จ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$unlockedCount/$totalCount',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            minHeight: 6,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return AchievementBadge(
                achievement: achievement,
                isUnlocked: achievement.isUnlocked,
                showProgress: !achievement.isUnlocked,
                onTap: () => onAchievementTap(achievement),
              );
            },
          ),
        ],
      ),
    );
  }
}