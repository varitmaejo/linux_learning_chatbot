import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../data/models/linux_command.dart';

class CommandCard extends StatefulWidget {
  final LinuxCommand command;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onPractice;
  final bool isFavorite;
  final bool showActions;
  final bool isCompact;

  const CommandCard({
    Key? key,
    required this.command,
    this.onTap,
    this.onFavorite,
    this.onPractice,
    this.isFavorite = false,
    this.showActions = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  State<CommandCard> createState() => _CommandCardState();
}

class _CommandCardState extends State<CommandCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('คัดลอก "$text" แล้ว'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap ?? _toggleExpanded,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  if (_isExpanded && !widget.isCompact) _buildExpandedContent(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDifficultyBadge(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.command.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (widget.showActions) _buildHeaderActions(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.command.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            maxLines: widget.isCompact ? 2 : null,
            overflow: widget.isCompact ? TextOverflow.ellipsis : null,
          ),
          if (!widget.isCompact) ...[
            const SizedBox(height: 12),
            _buildSyntaxContainer(),
            if (widget.command.examples.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildQuickExample(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge() {
    Color badgeColor;
    String difficultyText;

    switch (widget.command.difficulty) {
      case CommandDifficulty.beginner:
        badgeColor = Colors.green;
        difficultyText = 'เริ่มต้น';
        break;
      case CommandDifficulty.intermediate:
        badgeColor = Colors.orange;
        difficultyText = 'ปานกลาง';
        break;
      case CommandDifficulty.advanced:
        badgeColor = Colors.red;
        difficultyText = 'ขั้นสูง';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        difficultyText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onFavorite != null)
          IconButton(
            icon: Icon(
              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.isFavorite ? Colors.red : Colors.grey[600],
            ),
            onPressed: widget.onFavorite,
            iconSize: 20,
          ),
        IconButton(
          icon: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.grey[600],
          ),
          onPressed: _toggleExpanded,
          iconSize: 20,
        ),
      ],
    );
  }

  Widget _buildSyntaxContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.command.syntax,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () => _copyToClipboard(widget.command.syntax),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickExample() {
    if (widget.command.examples.isEmpty) return const SizedBox.shrink();

    final firstExample = widget.command.examples.first;
    return Container(
      width: double.infinity,
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
              fontSize: 14,
              color: Colors.green[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              firstExample.command,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Colors.green[300],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
            onPressed: () => _copyToClipboard(firstExample.command),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),

          // Category and Tags
          if (widget.command.category.isNotEmpty || widget.command.tags.isNotEmpty)
            _buildCategoryAndTags(),

          // Parameters
          if (widget.command.parameters.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildParametersSection(),
          ],

          // Examples
          if (widget.command.examples.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildExamplesSection(),
          ],

          // Related Commands
          if (widget.command.relatedCommands.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildRelatedCommandsSection(),
          ],

          // Action Buttons
          if (widget.showActions) ...[
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryAndTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.command.category.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.category, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'หมวดหมู่: ${widget.command.category}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        if (widget.command.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.command.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildParametersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'พารามิเตอร์',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.command.parameters.map((param) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    param.name,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    param.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildExamplesSection() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Widget _buildExamplesSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ตัวอย่าง',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.command.examples.map((example) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
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
                            fontSize: 14,
                            color: Colors.green[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            example.command,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              color: Colors.green[300],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                          onPressed: () => _copyToClipboard(example.command),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  if (example.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      example.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (example.output.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        example.output,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      );
    }

    Widget _buildRelatedCommandsSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            children: widget.command.relatedCommands.map((relatedCommand) {
              return GestureDetector(
                onTap: () => _copyToClipboard(relatedCommand),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        relatedCommand,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.copy,
                        size: 12,
                        color: Colors.blue[700],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    Widget _buildActionButtons() {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.onPractice,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('ฝึกใช้'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _copyToClipboard(widget.command.syntax),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('คัดลอก'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side: BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

// Compact Command Card for lists
  class CompactCommandCard extends StatelessWidget {
  final LinuxCommand command;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavorite;

  const CompactCommandCard({
  Key? key,
  required this.command,
  this.onTap,
  this.isFavorite = false,
  this.onFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
  return Card(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  child: ListTile(
  leading: _buildDifficultyIcon(),
  title: Text(
  command.name,
  style: const TextStyle(
  fontFamily: 'monospace',
  fontWeight: FontWeight.bold,
  ),
  ),
  subtitle: Text(
  command.description,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  ),
  trailing: onFavorite != null
  ? IconButton(
  icon: Icon(
  isFavorite ? Icons.favorite : Icons.favorite_border,
  color: isFavorite ? Colors.red : Colors.grey[600],
  ),
  onPressed: onFavorite,
  )
      : const Icon(Icons.chevron_right),
  onTap: onTap,
  ),
  );
  }

  Widget _buildDifficultyIcon() {
  Color color;
  IconData icon;

  switch (command.difficulty) {
  case CommandDifficulty.beginner:
  color = Colors.green;
  icon = Icons.circle;
  break;
  case CommandDifficulty.intermediate:
  color = Colors.orange;
  icon = Icons.circle;
  break;
  case CommandDifficulty.advanced:
  color = Colors.red;
  icon = Icons.circle;
  break;
  }

  return Icon(icon, color: color, size: 12);
  }
  }

// Command Grid Card
  class CommandGridCard extends StatefulWidget {
  final LinuxCommand command;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavorite;

  const CommandGridCard({
  Key? key,
  required this.command,
  this.onTap,
  this.isFavorite = false,
  this.onFavorite,
  }) : super(key: key);

  @override
  State<CommandGridCard> createState() => _CommandGridCardState();
  }

  class _CommandGridCardState extends State<CommandGridCard>
  with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
  super.initState();
  _animationController = AnimationController(
  duration: const Duration(milliseconds: 150),
  vsync: this,
  );
  _scaleAnimation = Tween<double>(
  begin: 1.0,
  end: 0.95,
  ).animate(CurvedAnimation(
  parent: _animationController,
  curve: Curves.easeInOut,
  ));
  }

  @override
  void dispose() {
  _animationController.dispose();
  super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
  _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
  _animationController.reverse();
  }

  void _onTapCancel() {
  _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
  return GestureDetector(
  onTapDown: _onTapDown,
  onTapUp: _onTapUp,
  onTapCancel: _onTapCancel,
  onTap: widget.onTap,
  child: AnimatedBuilder(
  animation: _scaleAnimation,
  builder: (context, child) {
  return Transform.scale(
  scale: _scaleAnimation.value,
  child: Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  _buildDifficultyBadge(),
  if (widget.onFavorite != null)
  GestureDetector(
  onTap: widget.onFavorite,
  child: Icon(
  widget.isFavorite
  ? Icons.favorite
      : Icons.favorite_border,
  color: widget.isFavorite
  ? Colors.red
      : Colors.grey[600],
  size: 20,
  ),
  ),
  ],
  ),
  const SizedBox(height: 12),
  Text(
  widget.command.name,
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
  fontWeight: FontWeight.bold,
  fontFamily: 'monospace',
  ),
  ),
  const SizedBox(height: 8),
  Expanded(
  child: Text(
  widget.command.description,
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
  color: Colors.grey[600],
  ),
  maxLines: 3,
  overflow: TextOverflow.ellipsis,
  ),
  ),
  const SizedBox(height: 8),
  if (widget.command.tags.isNotEmpty)
  Wrap(
  spacing: 4,
  children: widget.command.tags.take(2).map((tag) {
  return Container(
  padding: const EdgeInsets.symmetric(
  horizontal: 6,
  vertical: 2,
  ),
  decoration: BoxDecoration(
  color: AppColors.primaryColor.withOpacity(0.1),
  borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
  tag,
  style: TextStyle(
  fontSize: 10,
  color: AppColors.primaryColor,
  fontWeight: FontWeight.w500,
  ),
  ),
  );
  }).toList(),
  ),
  ],
  ),
  ),
  ),
  );
  },
  ),
  );
  }

  Widget _buildDifficultyBadge() {
  Color badgeColor;
  String difficultyText;

  switch (widget.command.difficulty) {
  case CommandDifficulty.beginner:
  badgeColor = Colors.green;
  difficultyText = 'เริ่มต้น';
  break;
  case CommandDifficulty.intermediate:
  badgeColor = Colors.orange;
  difficultyText = 'ปานกลาง';
  break;
  case CommandDifficulty.advanced:
  badgeColor = Colors.red;
  difficultyText = 'ขั้นสูง';
  break;
  }

  return Container(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
  decoration: BoxDecoration(
  color: badgeColor.withOpacity(0.1),
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: badgeColor.withOpacity(0.3), width: 0.5),
  ),
  child: Text(
  difficultyText,
  style: TextStyle(
  color: badgeColor,
  fontSize: 10,
  fontWeight: FontWeight.w600,
  ),
  ),
  );
  }
  }