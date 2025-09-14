import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/learning_provider.dart';
import '../providers/progress_provider.dart';
import '../theme/colors.dart';
import '../constants/strings.dart';
import '../widgets/loading_widget.dart';
import 'chat_screen.dart';
import 'learning_screen.dart';
import 'terminal_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _tabController = TabController(length: 5, vsync: this);
    _initializeProviders();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeProviders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final learningProvider = Provider.of<LearningProvider>(context, listen: false);
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      await Future.wait([
        learningProvider.initialize(authProvider.currentUser?.uid),
        progressProvider.initialize(authProvider.currentUser?.uid),
      ]);
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isInitialized) {
            return const LoadingWidget(message: 'กำลังเตรียมข้อมูล...');
          }

          return PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              _tabController.animateTo(index);
            },
            children: const [
              DashboardTab(),
              ChatScreen(),
              LearningScreen(),
              TerminalScreen(),
              ProfileScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isInitialized) return const SizedBox.shrink();

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primaryColor,
              unselectedItemColor: AppColors.mutedText,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              elevation: 0,
              backgroundColor: Colors.transparent,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: Strings.home,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_outlined),
                  activeIcon: Icon(Icons.chat),
                  label: Strings.chat,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.school_outlined),
                  activeIcon: Icon(Icons.school),
                  label: Strings.learning,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.terminal_outlined),
                  activeIcon: Icon(Icons.terminal),
                  label: Strings.terminal,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: Strings.profile,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final learningProvider = Provider.of<LearningProvider>(context, listen: false);
            final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
            await Future.wait([
              learningProvider.refresh(),
              progressProvider.refresh(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WelcomeCard(),
                  const SizedBox(height: 16),
                  const QuickStatsCard(),
                  const SizedBox(height: 16),
                  const RecommendedLessonsCard(),
                  const SizedBox(height: 16),
                  const RecentActivityCard(),
                  const SizedBox(height: 16),
                  const AchievementsCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final greeting = _getTimeGreeting();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.displayName ?? 'ผู้เรียน Linux',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatChip(
                    context,
                    'Level ${user?.level ?? 1}',
                    Icons.emoji_events,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    context,
                    '${user?.xp ?? 0} XP',
                    Icons.stars,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'สวัสดีตอนเช้า';
    if (hour < 17) return 'สวัสดีตอนบ่าย';
    if (hour < 20) return 'สวัสดีตอนเย็น';
    return 'สวัสดีตอนค่ำ';
  }
}

class QuickStatsCard extends StatelessWidget {
  const QuickStatsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        if (!progressProvider.isInitialized) {
          return const LoadingWidget();
        }

        final stats = progressProvider.getDetailedStatistics();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สถิติการเรียนรู้',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        '${stats['completedLessons']}',
                        'บทเรียนจบแล้ว',
                        Icons.check_circle,
                        AppColors.successColor,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        '${stats['currentStreak']}',
                        'วันต่อเนื่อง',
                        Icons.local_fire_department,
                        AppColors.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        '${(stats['averageAccuracy'] * 100).toStringAsFixed(0)}%',
                        'ความแม่นยำ',
                        Icons.target,
                        AppColors.infoColor,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        '#${stats['ranking']}',
                        'อันดับ',
                        Icons.leaderboard,
                        AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      String value,
      String label,
      IconData icon,
      Color color,
      ) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class RecommendedLessonsCard extends StatelessWidget {
  const RecommendedLessonsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LearningProvider>(
      builder: (context, learningProvider, child) {
        if (!learningProvider.isInitialized) {
          return const SkeletonLoader(height: 200);
        }

        final recommendations = learningProvider.recommendedCommands.take(3).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'แนะนำสำหรับคุณ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Navigate to learning screen
                        DefaultTabController.of(context)?.animateTo(2);
                      },
                      child: const Text('ดูทั้งหมด'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...recommendations.map((commandName) {
                  final command = learningProvider.getCommandByName(commandName);
                  if (command == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.getDifficultyColor(command.difficulty).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            command.categoryIcon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      title: Text(
                        command.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        command.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.mutedText,
                      ),
                      onTap: () {
                        // Navigate to lesson detail
                        Navigator.pushNamed(
                          context,
                          '/lesson-detail',
                          arguments: {'command': command},
                        );
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final recentActivity = progressProvider.getRecentActivity(limit: 3);

        if (recentActivity.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ยังไม่มีกิจกรรมล่าสุด',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      DefaultTabController.of(context)?.animateTo(2);
                    },
                    child: const Text('เริ่มเรียนเลย'),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'กิจกรรมล่าสุด',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        DefaultTabController.of(context)?.animateTo(3);
                      },
                      child: const Text('ดูเพิ่มเติม'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...recentActivity.map((progress) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.check,
                          color: AppColors.successColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'เรียนจบ ${progress.commandName}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              progress.formattedTime,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+${progress.xpEarned} XP',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AchievementsCard extends StatelessWidget {
  const AchievementsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final achievements = progressProvider.unlockedAchievements.take(3).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ความสำเร็จล่าสุด',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/achievements');
                      },
                      child: const Text('ดูทั้งหมด'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (achievements.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 48,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ยังไม่มีความสำเร็จ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                        Text(
                          'เริ่มเรียนเพื่อปลดล็อกความสำเร็จแรก!',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: achievements.map((achievement) => Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.getAchievementColor(achievement.badgeColor).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                achievement.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            achievement.title,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}