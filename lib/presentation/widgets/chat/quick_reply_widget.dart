import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class QuickReplyWidget extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onReplySelected;
  final bool isVisible;

  const QuickReplyWidget({
    Key? key,
    required this.suggestions,
    required this.onReplySelected,
    this.isVisible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible || suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'คำตอบด่วน',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions
                  .map((suggestion) => _buildQuickReplyChip(
                context,
                suggestion,
                    () => onReplySelected(suggestion),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplyChip(
      BuildContext context,
      String text,
      VoidCallback onTap,
      ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.send,
                  size: 14,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Alternative design with category-based quick replies
class CategorizedQuickReplyWidget extends StatelessWidget {
  final Map<String, List<String>> categorizedSuggestions;
  final Function(String) onReplySelected;
  final bool isVisible;

  const CategorizedQuickReplyWidget({
    Key? key,
    required this.categorizedSuggestions,
    required this.onReplySelected,
    this.isVisible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible || categorizedSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'คำแนะนำ',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...categorizedSuggestions.entries
              .map((entry) => _buildCategorySection(
            context,
            entry.key,
            entry.value,
          ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
      BuildContext context,
      String category,
      List<String> suggestions,
      ) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              _getCategoryIcon(category),
              const SizedBox(width: 8),
              Text(
                category,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map((suggestion) => _buildSuggestionChip(
            context,
            suggestion,
                () => onReplySelected(suggestion),
          ))
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSuggestionChip(
      BuildContext context,
      String text,
      VoidCallback onTap,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData iconData;
    switch (category.toLowerCase()) {
      case 'คำสั่งพื้นฐาน':
      case 'basic commands':
        iconData = Icons.terminal;
        break;
      case 'การจัดการไฟล์':
      case 'file management':
        iconData = Icons.folder;
        break;
      case 'การค้นหา':
      case 'search':
        iconData = Icons.search;
        break;
      case 'สิทธิ์':
      case 'permissions':
        iconData = Icons.security;
        break;
      case 'เครือข่าย':
      case 'network':
        iconData = Icons.network_wifi;
        break;
      case 'กระบวนการ':
      case 'processes':
        iconData = Icons.memory;
        break;
      case 'ระบบ':
      case 'system':
        iconData = Icons.settings;
        break;
      default:
        iconData = Icons.help_outline;
    }

    return Icon(
      iconData,
      size: 16,
      color: AppColors.primaryColor,
    );
  }
}

// Expandable Quick Reply Widget
class ExpandableQuickReplyWidget extends StatefulWidget {
  final List<String> suggestions;
  final Function(String) onReplySelected;
  final bool isVisible;
  final int maxVisibleItems;

  const ExpandableQuickReplyWidget({
    Key? key,
    required this.suggestions,
    required this.onReplySelected,
    this.isVisible = true,
    this.maxVisibleItems = 3,
  }) : super(key: key);

  @override
  State<ExpandableQuickReplyWidget> createState() =>
      _ExpandableQuickReplyWidgetState();
}

class _ExpandableQuickReplyWidgetState
    extends State<ExpandableQuickReplyWidget>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || widget.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleSuggestions = _isExpanded
        ? widget.suggestions
        : widget.suggestions.take(widget.maxVisibleItems).toList();

    final hasMoreItems = widget.suggestions.length > widget.maxVisibleItems;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'คำตอบด่วน',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasMoreItems)
                GestureDetector(
                  onTap: _toggleExpanded,
                  child: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visibleSuggestions
                  .map((suggestion) => _buildQuickReplyChip(
                context,
                suggestion,
                    () => widget.onReplySelected(suggestion),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplyChip(
      BuildContext context,
      String text,
      VoidCallback onTap,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}