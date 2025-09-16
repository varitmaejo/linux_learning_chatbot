import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/theme/colors.dart';
import '../../data/models/linux_command.dart';
import '../providers/learning_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/loading_widget.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({Key? key}) : super(key: key);

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: const Text('เรียนรู้'),
            floating: true,
            pinned: true,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildSearchBar(),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'เส้นทางการเรียน'),
                Tab(text: 'คำสั่งทั้งหมด'),
                Tab(text: 'แนะนำสำหรับคุณ'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLearningPathsTab(),
            _buildAllCommandsTab(),
            _buildRecommendationsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'ค้นหาคำสั่ง...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: () {
              _searchController.clear();
              _clearSearch();
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
        onChanged: _performSearch,
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildLearningPathsTab() {
    return Consumer<LearningProvider>(
      builder: (context, learningProvider, child) {
        if (learningProvider.state == LearningState.loading) {
          return const Center(child: LoadingWidget());
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: learningProvider.learningPaths.length,
            itemBuilder: (context, index) {
              final path = learningProvider.learningPaths[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildLearningPathCard(path),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLearningPathCard(LearningPath path) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showLearningPathDetail(path),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: path.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      path.icon,
                      color: path.color,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          path.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          path.estimatedDuration,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(path.difficulty).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getDifficultyText(path.difficulty),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getDifficultyColor(path.difficulty),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                path.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'คำสั่งในเส้นทางนี้ (${path.commands.length} คำสั่ง)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: path.commands.take(5).map((command) => Chip(
                  label: Text(
                    command,
                    style: const TextStyle(fontSize: 12),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),

              if (path.commands.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'และอีก ${path.commands.length - 5} คำสั่ง...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllCommandsTab() {
    return Consumer<LearningProvider>(
      builder: (context, learningProvider, child) {
        if (learningProvider.state == LearningState.loading) {
          return const Center(child: LoadingWidget());
        }

        return Column(
          children: [
            // Filters
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCategoryFilter(learningProvider),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDifficultyFilter(learningProvider),
                  ),
                ],
              ),
            ),

            // Commands list
            Expanded(
              child: AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: learningProvider.filteredCommands.length,
                  itemBuilder: (context, index) {
                    final command = learningProvider.filteredCommands[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildCommandCard(command),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryFilter(LearningProvider learningProvider) {
    return DropdownButtonFormField<String>(
      value: learningProvider.selectedCategory,
      decoration: const InputDecoration(
        labelText: 'หมวดหมู่',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: learningProvider.categories.map((category) => DropdownMenuItem(
        value: category,
        child: Text(_getCategoryDisplayText(category)),
      )).toList(),
      onChanged: (value) {
        if (value != null) {
          learningProvider.setCategory(value);
        }
      },
    );
  }

  Widget _buildDifficultyFilter(LearningProvider learningProvider) {
    return DropdownButtonFormField<String>(
      value: learningProvider.selectedDifficulty,
      decoration: const InputDecoration(
        labelText: 'ระดับความยาก',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: ['all', ...learningProvider.difficulties].map((difficulty) => DropdownMenuItem(
        value: difficulty,
        child: Text(_getDifficultyText(difficulty)),
      )).toList(),
      onChanged: (value) {
        if (value != null) {
          learningProvider.setDifficulty(value);
        }
      },
    );
  }

  Widget _buildCommandCard(LinuxCommand command) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        final progress = progressProvider.getProgressForCommand(command.id);
        final isCompleted = progress?.isCompleted ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showCommandDetail(command),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Command icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(command.difficulty.toString().split('.').last).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        command.categoryIcon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Command info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              command.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),

                            const SizedBox(width: 8),

                            if (isCompleted)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.successColor,
                                size: 20,
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          command.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(command.difficulty.toString().split('.').last).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                command.difficultyDisplayText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getDifficultyColor(command.difficulty.toString().split('.').last),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.chipBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                command.categoryDisplayText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (progress != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(
                              value: progress.progressPercentage / 100,
                              backgroundColor: AppColors.progressBackground,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.progressActive,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationsTab() {
    return Consumer<LearningProvider>(
      builder: (context, learningProvider, child) {
        if (learningProvider.state == LearningState.loading) {
          return const Center(child: LoadingWidget());
        }

        final recommendations = learningProvider.recommendedCommands;

        if (recommendations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 64,
                  color: AppColors.mutedText,
                ),
                const SizedBox(height: 16),
                Text(
                  'ยังไม่มีคำแนะนำ',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'เริ่มเรียนรู้คำสั่งเพื่อรับคำแนะนำที่เหมาะสม',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'แนะนำสำหรับคุณ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'คำสั่งที่เหมาะกับระดับการเรียนรู้ของคุณ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),

              const SizedBox(height: 24),

              AnimationLimiter(
                child: Column(
                  children: recommendations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final commandName = entry.value;
                    final command = learningProvider.getCommandByName(commandName);

                    if (command == null) return const SizedBox.shrink();

                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildRecommendationCard(command, index + 1),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecommendationCard(LinuxCommand command, int priority) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showCommandDetail(command),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Priority number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    priority.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Command info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          command.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),

                        const SizedBox(width: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.recommend,
                                size: 12,
                                color: AppColors.accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'แนะนำ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      command.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _startLearning(command),
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('เริ่มเรียน'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        OutlinedButton.icon(
                          onPressed: () => _showCommandDetail(command),
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('รายละเอียด'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return AppColors.beginnerColor;
      case 'intermediate':
        return AppColors.intermediateColor;
      case 'advanced':
        return AppColors.advancedColor;
      case 'expert':
        return AppColors.expertColor;
      default:
        return AppColors.beginnerColor;
    }
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
      case 'all':
        return 'ทั้งหมด';
      case 'beginner':
        return 'ง่าย';
      case 'intermediate':
        return 'ปานกลาง';
      case 'advanced':
        return 'ยาก';
      case 'expert':
        return 'ผู้เชี่ยวชาญ';
      default:
        return difficulty;
    }
  }

  String _getCategoryDisplayText(String category) {
    switch (category) {
      case 'all':
        return 'ทั้งหมด';
      case 'fileSystem':
        return 'ระบบไฟล์';
      case 'textProcessing':
        return 'ประมวลผลข้อความ';
      case 'systemInfo':
        return 'ข้อมูลระบบ';
      case 'network':
        return 'เครือข่าย';
      case 'process':
        return 'โปรเซส';
      case 'permission':
        return 'สิทธิ์การเข้าถึง';
      default:
        return category;
    }
  }

  void _performSearch(String query) {
    final learningProvider = Provider.of<LearningProvider>(context, listen: false);
    learningProvider.setSearchQuery(query);
  }

  void _clearSearch() {
    final learningProvider = Provider.of<LearningProvider>(context, listen: false);
    learningProvider.setSearchQuery('');
  }

  void _startLearning(LinuxCommand command) {
    final learningProvider = Provider.of<LearningProvider>(context, listen: false);
    learningProvider.startLearningCommand(command.id, LearningMode.tutorial);

    // Navigate to command detail screen
    Navigator.pushNamed(
      context,
      '/command-detail',
      arguments: {'command': command},
    );
  }

  void _showCommandDetail(LinuxCommand command) {
    Navigator.pushNamed(
      context,
      '/command-detail',
      arguments: {'command': command},
    );
  }

  void _showLearningPathDetail(LearningPath path) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: path.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        path.icon,
                        color: path.color,
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            path.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            path.estimatedDuration,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Text(
                      path.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.secondaryText,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'คำสั่งในเส้นทางนี้',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    ...path.commands.asMap().entries.map((entry) {
                      final index = entry.key;
                      final commandName = entry.value;
                      final learningProvider = Provider.of<LearningProvider>(context);
                      final command = learningProvider.getCommandByName(commandName);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: path.color.withOpacity(0.1),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: path.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          commandName,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: command != null ? Text(command.description) : null,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: command != null ? () => _showCommandDetail(command) : null,
                      );
                    }).toList(),

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Start the learning path
                        _startLearningPath(path);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: path.color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'เริ่มเส้นทางการเรียนนี้',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startLearningPath(LearningPath path) {
    if (path.commands.isNotEmpty) {
      final learningProvider = Provider.of<LearningProvider>(context, listen: false);
      final firstCommand = learningProvider.getCommandByName(path.commands.first);

      if (firstCommand != null) {
        _startLearning(firstCommand);
      }
    }
  }
}