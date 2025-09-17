import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class CustomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavigationItem> items;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double height;
  final bool showLabels;

  const CustomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.height = 60,
    this.showLabels = true,
  }) : super(key: key);

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      widget.items.length,
          (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();

    // Animate the initially selected item
    _animationControllers[widget.currentIndex].forward();
  }

  @override
  void didUpdateWidget(CustomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _animationControllers[oldWidget.currentIndex].reverse();
      _animationControllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == widget.currentIndex;

            return _buildNavItem(index, item, isSelected);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, NavigationItem item, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: AnimatedBuilder(
        animation: _scaleAnimations[index],
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _scaleAnimations[index].value,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (widget.selectedColor ?? AppColors.primaryColor).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      size: 24,
                      color: isSelected
                          ? (widget.selectedColor ?? AppColors.primaryColor)
                          : (widget.unselectedColor ?? Colors.grey[600]),
                    ),
                  ),
                ),
                if (widget.showLabels) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? (widget.selectedColor ?? AppColors.primaryColor)
                          : (widget.unselectedColor ?? Colors.grey[600]),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Color? color;
  final Widget? badge;

  const NavigationItem({
    required this.icon,
    required this.label,
    this.color,
    this.badge,
  });
}

// Floating Navigation Bar
class FloatingNavigationBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavigationItem> items;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const FloatingNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.borderRadius = 25,
    this.margin,
  }) : super(key: key);

  @override
  State<FloatingNavigationBar> createState() => _FloatingNavigationBarState();
}

class _FloatingNavigationBarState extends State<FloatingNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: widget.margin ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == widget.currentIndex;

              return _buildFloatingNavItem(index, item, isSelected);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem(int index, NavigationItem item, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (widget.selectedColor ?? AppColors.primaryColor)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius - 5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : (widget.unselectedColor ?? Colors.grey[600]),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Tab Navigation Bar
class TabNavigationBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavigationItem> items;
  final Color? backgroundColor;
  final Color? indicatorColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final bool isScrollable;

  const TabNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.indicatorColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.isScrollable = false,
  }) : super(key: key);

  @override
  State<TabNavigationBar> createState() => _TabNavigationBarState();
}

class _TabNavigationBarState extends State<TabNavigationBar>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.items.length,
      initialIndex: widget.currentIndex,
      vsync: this,
    );
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      widget.onTap(_tabController.index);
    }
  }

  @override
  void didUpdateWidget(TabNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _tabController.animateTo(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: widget.isScrollable,
        indicatorColor: widget.indicatorColor ?? AppColors.primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: widget.selectedTextColor ?? AppColors.primaryColor,
        unselectedLabelColor: widget.unselectedTextColor ?? Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        tabs: widget.items.map((item) {
          return Tab(
            icon: Icon(item.icon, size: 20),
            text: item.label,
          );
        }).toList(),
      ),
    );
  }
}

// Side Navigation Rail
class CustomNavigationRail extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationRailDestination> destinations;
  final Widget? leading;
  final Widget? trailing;
  final bool extended;
  final Color? backgroundColor;
  final Color? selectedIconTheme;
  final Color? unselectedIconTheme;

  const CustomNavigationRail({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.leading,
    this.trailing,
    this.extended = false,
    this.backgroundColor,
    this.selectedIconTheme,
    this.unselectedIconTheme,
  }) : super(key: key);

  @override
  State<CustomNavigationRail> createState() => _CustomNavigationRailState();
}

class _CustomNavigationRailState extends State<CustomNavigationRail>
    with TickerProviderStateMixin {
  late AnimationController _extendController;
  late Animation<double> _extendAnimation;

  @override
  void initState() {
    super.initState();
    _extendController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _extendAnimation = CurvedAnimation(
      parent: _extendController,
      curve: Curves.easeInOut,
    );

    if (widget.extended) {
      _extendController.forward();
    }
  }

  @override
  void didUpdateWidget(CustomNavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.extended != oldWidget.extended) {
      if (widget.extended) {
        _extendController.forward();
      } else {
        _extendController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _extendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _extendAnimation,
      builder: (context, child) {
        return Container(
          width: 72 + (180 * _extendAnimation.value),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.white,
            border: Border(
              right: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              if (widget.leading != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: widget.leading,
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.destinations.length,
                  itemBuilder: (context, index) {
                    final destination = widget.destinations[index];
                    final isSelected = index == widget.selectedIndex;

                    return _buildRailItem(destination, index, isSelected);
                  },
                ),
              ),
              if (widget.trailing != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: widget.trailing,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRailItem(
      NavigationRailDestination destination,
      int index,
      bool isSelected,
      ) {
    return GestureDetector(
      onTap: () => widget.onDestinationSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              destination.icon,
              size: 24,
              color: isSelected
                  ? AppColors.primaryColor
                  : Colors.grey[600],
            ),
            AnimatedBuilder(
              animation: _extendAnimation,
              builder: (context, child) {
                return SizeTransition(
                  sizeFactor: _extendAnimation,
                  axis: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      destination.label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryColor
                            : Colors.grey[600],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}