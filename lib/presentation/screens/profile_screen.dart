import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/progress_provider.dart';
import '../theme/colors.dart';
import '../constants/strings.dart';
import '../widgets/loading_widget.dart';
import '../widgets/custom_dialog.dart';
import '../utils/date_utils.dart' as utils;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initializeController() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = authProvider.currentUser?.displayName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<AuthProvider, ProgressProvider>(
          builder: (context, authProvider, progressProvider, child) {
            if (!authProvider.isInitialized || !progressProvider.isInitialized) {
              return const LoadingWidget(message: 'กำลังโหลดโปรไฟล์...');
            }

            final user = authProvider.currentUser;
            if (user == null) {
              return const Center(
                child: Text('ไม่พบข้อมูลผู้ใช้'),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await progressProvider.refresh();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(context, user, authProvider),
                    const SizedBox(height: 16),
                    _buildStatsCard(context, progressProvider),
                    const SizedBox(height: 16),
                    _buildAchievementsCard(context, progressProvider),
                    const SizedBox(height: 16),
                    _buildActivityCard(context, progressProvider),
                    const SizedBox(height: 16),
                    _buildSettingsCard(context, authProvider),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user, AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Strings.myProfile,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => _showEditProfileDialog(context, authProvider),
                icon: const Icon(Icons.edit, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: user.photoURL != null
                ? ClipOval(
              child: Image.network(
                user.photoURL!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.person, size: 50, color: Colors.white),
              ),
            )
                : const Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName ?? 'ผู้ใช้งาน',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (user.email?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              user.email!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip(
                context,
                'Level ${user.level}',
                Icons.emoji_events,
                AppColors.goldColor,
              ),
              _buildStatChip(
                context,
                '${user.xp} XP',
                Icons.stars,
                Colors.amber,
              ),
              _buildStatChip(
                context,
                '${user.streak} วัน',
                Icons.local_fire_department,
                AppColors.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'สมาชิกตั้งแต่: ${utils.DateUtils.formatThaiDate(user.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
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

  Widget _buildStatsCard(BuildContext context, ProgressProvider progressProvider) {
    final stats = progressProvider.getDetailedStatistics();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สถิติการเรียนรู้',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatItem(
                  context,
                  '${stats['completedLessons']}',
                  'บทเรียนจบแล้ว',
                  Icons.check_circle,
                  AppColors.successColor,
                ),
                _buildStatItem(
                  context,
                  '${(stats['averageAccuracy'] * 100).toStringAsFixed(0)}%',
                  'ความแม่นยำเฉลี่ย',
                  Icons.target,
                  AppColors.infoColor,
                ),
                _buildStatItem(
                  context,
                  utils.DateUtils.formatStudyTime(stats['totalTimeSpent']),
                  'เวลาเรียนรวม',
                  Icons.schedule,
                  AppColors.warningColor,
                ),
                _buildStatItem(
                  context,
                  '#${stats['ranking']}',
                  'อันดับในลีดเดอร์บอร์ด',
                  Icons.leaderboard,
                  AppColors.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      String value,
      String label,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard(BuildContext context, ProgressProvider progressProvider) {
    final unlockedAchievements = progressProvider.unlockedAchievements.take(6).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'ความสำเร็จ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
            if (unlockedAchievements.isEmpty)
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
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: unlockedAchievements.map((achievement) => Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.getAchievementColor(achievement.badgeColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        achievement.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
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
  }

  Widget _buildActivityCard(BuildContext context, ProgressProvider progressProvider) {
    final recentActivity = progressProvider.getRecentActivity(limit: 5);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'กิจกรรมล่าสุด',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (recentActivity.isEmpty)
              Center(
                child: Text(
                  'ยังไม่มีกิจกรรม',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentActivity.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final progress = recentActivity[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.successColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'เรียนจบ ${progress.commandName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${progress.categoryDisplayName} • ${progress.timeSpentDisplay}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${progress.xpEarned} XP',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          utils.DateUtils.getTimeAgo(progress.completedAt ?? DateTime.now()),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, AuthProvider authProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'การตั้งค่า',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.settings, color: AppColors.primaryColor),
              title: const Text('ตั้งค่าแอป'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.leaderboard, color: AppColors.accentColor),
              title: const Text('กระดานผู้นำ'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pushNamed(context, '/leaderboard');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.feedback, color: AppColors.infoColor),
              title: const Text('ข้อเสนอแนะ'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showFeedbackDialog(context);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info, color: AppColors.mutedText),
              title: const Text('เกี่ยวกับแอป'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showAboutDialog(context);
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout, color: AppColors.errorColor),
              title: Text(
                'ออกจากระบบ',
                style: TextStyle(color: AppColors.errorColor),
              ),
              onTap: () {
                _showLogoutDialog(context, authProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    _nameController.text = authProvider.currentUser?.displayName ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขโปรไฟล์'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'ชื่อที่แสดง',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(Strings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                final success = await authProvider.updateUserProfile(
                  displayName: name,
                );

                if (success && mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('อัพเดทโปรไฟล์สำเร็จ')),
                  );
                }
              }
            },
            child: const Text(Strings.save),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'ออกจากระบบ',
      content: 'คุณต้องการออกจากระบบหรือไม่?',
      confirmText: 'ออกจากระบบ',
      icon: Icons.logout,
      confirmColor: AppColors.errorColor,
    );

    if (confirmed) {
      await authProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ข้อเสนอแนะ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('เราต้องการฟังความคิดเห็นของคุณเพื่อปรับปรุงแอป'),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'พิมพ์ข้อเสนอแนะของคุณ...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(Strings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement feedback submission
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ขอบคุณสำหรับข้อเสนอแนะ')),
              );
            },
            child: const Text('ส่ง'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Linux Learning Chatbot',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.terminal, size: 64),
      children: [
        const Text('แอปเรียนรู้คำสั่ง Linux อย่างสนุกสนานด้วย AI Chatbot'),
        const SizedBox(height: 16),
        const Text('พัฒนาโดย: AI Learning Team'),
        const Text('อีเมล: support@linuxlearning.com'),
      ],
    );
  }
}