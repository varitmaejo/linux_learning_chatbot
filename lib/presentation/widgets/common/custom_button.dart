import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

enum ButtonType { primary, secondary, outline, text, danger, success }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? customColor;
  final Color? customTextColor;
  final double fontSize;
  final FontWeight? fontWeight;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height = 48,
    this.padding,
    this.borderRadius = 8,
    this.customColor,
    this.customTextColor,
    this.fontSize = 16,
    this.fontWeight,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
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

  bool get _isEnabled => widget.isEnabled && !widget.isLoading;

  void _onTapDown(TapDownDetails details) {
    if (_isEnabled) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_isEnabled) {
      _animationController.reverse();
    }
  }

  void _onTapCancel() {
    if (_isEnabled) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _isEnabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24),
              decoration: _getButtonDecoration(context),
              child: _buildButtonContent(),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _getButtonDecoration(BuildContext context) {
    Color backgroundColor;
    Color borderColor = Colors.transparent;
    double borderWidth = 0;

    switch (widget.type) {
      case ButtonType.primary:
        backgroundColor = _isEnabled
            ? (widget.customColor ?? AppColors.primaryColor)
            : Colors.grey[400]!;
        break;
      case ButtonType.secondary:
        backgroundColor = _isEnabled
            ? (widget.customColor ?? Colors.grey[200]!)
            : Colors.grey[100]!;
        break;
      case ButtonType.outline:
        backgroundColor = Colors.transparent;
        borderColor = _isEnabled
            ? (widget.customColor ?? AppColors.primaryColor)
            : Colors.grey[400]!;
        borderWidth = 1.5;
        break;
      case ButtonType.text:
        backgroundColor = Colors.transparent;
        break;
      case ButtonType.danger:
        backgroundColor = _isEnabled
            ? (widget.customColor ?? Colors.red)
            : Colors.grey[400]!;
        break;
      case ButtonType.success:
        backgroundColor = _isEnabled
            ? (widget.customColor ?? Colors.green)
            : Colors.grey[400]!;
        break;
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      border: borderWidth > 0
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      boxShadow: _isEnabled && widget.type != ButtonType.text && widget.type != ButtonType.outline
          ? [
        BoxShadow(
          color: backgroundColor.withOpacity(0.3),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ]
          : null,
    );
  }

  Widget _buildButtonContent() {
    Color textColor = _getTextColor();

    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(textColor),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            color: textColor,
            size: widget.fontSize + 2,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: TextStyle(
            color: textColor,
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight ?? FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getTextColor() {
    if (widget.customTextColor != null) {
      return widget.customTextColor!;
    }

    switch (widget.type) {
      case ButtonType.primary:
      case ButtonType.danger:
      case ButtonType.success:
        return Colors.white;
      case ButtonType.secondary:
        return _isEnabled ? Colors.black87 : Colors.grey[600]!;
      case ButtonType.outline:
      case ButtonType.text:
        return _isEnabled
            ? (widget.customColor ?? AppColors.primaryColor)
            : Colors.grey[600]!;
    }
  }
}

// Floating Action Button variant
class CustomFloatingButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final bool isExtended;
  final String? label;
  final bool showShadow;

  const CustomFloatingButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 56,
    this.isExtended = false,
    this.label,
    this.showShadow = true,
  }) : super(key: key);

  @override
  State<CustomFloatingButton> createState() => _CustomFloatingButtonState();
}

class _CustomFloatingButtonState extends State<CustomFloatingButton>
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
      end: 0.9,
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
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.isExtended ? null : widget.size,
              height: widget.size,
              padding: widget.isExtended
                  ? const EdgeInsets.symmetric(horizontal: 16)
                  : null,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? AppColors.primaryColor,
                borderRadius: BorderRadius.circular(widget.size / 2),
                boxShadow: widget.showShadow
                    ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    color: widget.foregroundColor ?? Colors.white,
                    size: 24,
                  ),
                  if (widget.isExtended && widget.label != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      widget.label!,
                      style: TextStyle(
                        color: widget.foregroundColor ?? Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Icon Button variant
class CustomIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final double iconSize;
  final String? tooltip;
  final bool showBackground;
  final EdgeInsetsGeometry? padding;

  const CustomIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 48,
    this.iconSize = 24,
    this.tooltip,
    this.showBackground = true,
    this.padding,
  }) : super(key: key);

  @override
  State<CustomIconButton> createState() => _CustomIconButtonState();
}

class _CustomIconButtonState extends State<CustomIconButton>
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
      end: 0.9,
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
    Widget button = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              padding: widget.padding ?? const EdgeInsets.all(8),
              decoration: widget.showBackground
                  ? BoxDecoration(
                color: widget.backgroundColor ?? Colors.grey[100],
                shape: BoxShape.circle,
              )
                  : null,
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: widget.foregroundColor ??
                    (widget.showBackground ? Colors.black87 : AppColors.primaryColor),
              ),
            ),
          );
        },
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

// Toggle Button
class CustomToggleButton extends StatefulWidget {
  final bool isSelected;
  final ValueChanged<bool> onChanged;
  final String text;
  final IconData? icon;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const CustomToggleButton({
    Key? key,
    required this.isSelected,
    required this.onChanged,
    required this.text,
    this.icon,
    this.selectedColor,
    this.unselectedColor,
    this.borderRadius = 8,
    this.padding,
  }) : super(key: key);

  @override
  State<CustomToggleButton> createState() => _CustomToggleButtonState();
}

class _CustomToggleButtonState extends State<CustomToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: widget.unselectedColor ?? Colors.grey[200],
      end: widget.selectedColor ?? AppColors.primaryColor,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isSelected) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CustomToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
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
      onTap: () => widget.onChanged(!widget.isSelected),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.padding ?? const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: widget.isSelected
                      ? (widget.selectedColor ?? AppColors.primaryColor)
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 16,
                      color: widget.isSelected ? Colors.white : Colors.black87,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: widget.isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
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
}

// Button Group
class CustomButtonGroup extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelectionChanged;
  final bool isMultiSelect;
  final List<int>? selectedIndices;
  final ValueChanged<List<int>>? onMultiSelectionChanged;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double borderRadius;

  const CustomButtonGroup({
    Key? key,
    required this.options,
    required this.selectedIndex,
    required this.onSelectionChanged,
    this.isMultiSelect = false,
    this.selectedIndices,
    this.onMultiSelectionChanged,
    this.selectedColor,
    this.unselectedColor,
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = isMultiSelect
              ? (selectedIndices?.contains(index) ?? false)
              : selectedIndex == index;
          final isFirst = index == 0;
          final isLast = index == options.length - 1;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (isMultiSelect) {
                  final currentSelection = List<int>.from(selectedIndices ?? []);
                  if (currentSelection.contains(index)) {
                    currentSelection.remove(index);
                  } else {
                    currentSelection.add(index);
                  }
                  onMultiSelectionChanged?.call(currentSelection);
                } else {
                  onSelectionChanged(index);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (selectedColor ?? AppColors.primaryColor)
                      : (unselectedColor ?? Colors.transparent),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isFirst ? borderRadius : 0),
                    bottomLeft: Radius.circular(isFirst ? borderRadius : 0),
                    topRight: Radius.circular(isLast ? borderRadius : 0),
                    bottomRight: Radius.circular(isLast ? borderRadius : 0),
                  ),
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Gradient Button
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color> gradientColors;
  final IconData? icon;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isLoading;

  const GradientButton({
    Key? key,
    required this.text,
    this.onPressed,
    required this.gradientColors,
    this.icon,
    this.width,
    this.height = 48,
    this.borderRadius = 8,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
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
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradientColors.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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