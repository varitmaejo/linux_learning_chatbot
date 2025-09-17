import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../chat/voice_input_widget.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final double borderRadius;
  final Color? fillColor;
  final Color? focusedBorderColor;
  final bool showVoiceInput;
  final Function(String)? onVoiceInput;

  const CustomTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
    this.borderRadius = 8.0,
    this.fillColor,
    this.focusedBorderColor,
    this.showVoiceInput = false,
    this.onVoiceInput,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _setupAnimations();
    _setupFocusListener();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _borderColorAnimation = ColorTween(
      begin: Colors.grey[300],
      end: widget.focusedBorderColor ?? AppColors.primaryColor,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupFocusListener() {
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (_isFocused) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.labelText!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        AnimatedBuilder(
          animation: _borderColorAnimation,
          builder: (context, child) {
            return TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              onTap: widget.onTap,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onEditingComplete: widget.onEditingComplete,
              inputFormatters: widget.inputFormatters,
              textCapitalization: widget.textCapitalization,
              decoration: InputDecoration(
                hintText: widget.hintText,
                errorText: widget.errorText,
                helperText: widget.helperText,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                  widget.prefixIcon,
                  color: _isFocused
                      ? (widget.focusedBorderColor ?? AppColors.primaryColor)
                      : Colors.grey[600],
                )
                    : null,
                suffixIcon: _buildSuffixIcon(),
                filled: true,
                fillColor: widget.enabled
                    ? (widget.fillColor ?? Colors.grey[50])
                    : Colors.grey[100],
                contentPadding: widget.contentPadding ??
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: _borderColorAnimation.value ?? AppColors.primaryColor,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  borderSide: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    List<Widget> suffixWidgets = [];

    // Add voice input if enabled
    if (widget.showVoiceInput && widget.onVoiceInput != null) {
      suffixWidgets.add(
        CompactVoiceButton(
          onVoiceInput: widget.onVoiceInput!,
          isEnabled: widget.enabled,
          size: 20,
        ),
      );
    }

    // Add custom suffix icon
    if (widget.suffixIcon != null) {
      suffixWidgets.add(widget.suffixIcon!);
    }

    if (suffixWidgets.isEmpty) return null;

    if (suffixWidgets.length == 1) {
      return suffixWidgets.first;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: suffixWidgets
          .map((widget) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: widget,
      ))
          .toList(),
    );
  }
}

// Search Text Field
class SearchTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool showVoiceInput;
  final Function(String)? onVoiceInput;

  const SearchTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.showVoiceInput = false,
    this.onVoiceInput,
  }) : super(key: key);

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  late TextEditingController _controller;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _showClearButton = _controller.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _clearText() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: _controller,
      hintText: widget.hintText ?? 'ค้นหา...',
      prefixIcon: Icons.search,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      showVoiceInput: widget.showVoiceInput,
      onVoiceInput: widget.onVoiceInput,
      suffixIcon: _showClearButton
          ? IconButton(
        icon: const Icon(Icons.clear),
        onPressed: _clearText,
        iconSize: 20,
      )
          : null,
    );
  }
}

// Password Text Field
class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool showStrengthIndicator;

  const PasswordTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.showStrengthIndicator = false,
  }) : super(key: key);

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;
  double _passwordStrength = 0.0;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _calculatePasswordStrength(String password) {
    if (!widget.showStrengthIndicator) return;

    double strength = 0;
    if (password.length >= 8) strength += 0.2;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

    setState(() {
      _passwordStrength = strength;
    });
  }

  Color _getStrengthColor() {
    if (_passwordStrength < 0.3) return Colors.red;
    if (_passwordStrength < 0.6) return Colors.orange;
    if (_passwordStrength < 0.8) return Colors.yellow;
    return Colors.green;
  }

  String _getStrengthText() {
    if (_passwordStrength < 0.3) return 'อ่อนแอ';
    if (_passwordStrength < 0.6) return 'ปานกลาง';
    if (_passwordStrength < 0.8) return 'แข็งแกร่ง';
    return 'แข็งแกร่งมาก';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: widget.controller,
          hintText: widget.hintText,
          labelText: widget.labelText,
          errorText: widget.errorText,
          obscureText: _obscureText,
          prefixIcon: Icons.lock,
          onChanged: (value) {
            _calculatePasswordStrength(value);
            widget.onChanged?.call(value);
          },
          onSubmitted: widget.onSubmitted,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: _togglePasswordVisibility,
          ),
        ),
        if (widget.showStrengthIndicator && widget.controller?.text.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: _passwordStrength,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor()),
                  minHeight: 4,
                ),
                const SizedBox(height: 4),
                Text(
                  'ความแข็งแกร่ง: ${_getStrengthText()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getStrengthColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Chat Input Field
class ChatInputField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final VoidCallback? onSend;
  final ValueChanged<String>? onChanged;
  final bool showVoiceInput;
  final Function(String)? onVoiceInput;
  final bool isEnabled;

  const ChatInputField({
    Key? key,
    this.controller,
    this.hintText,
    this.onSend,
    this.onChanged,
    this.showVoiceInput = true,
    this.onVoiceInput,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleSend() {
    if (_hasText && widget.isEnabled) {
      widget.onSend?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomTextField(
              controller: _controller,
              hintText: widget.hintText ?? 'พิมพ์ข้อความ...',
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              enabled: widget.isEnabled,
              showVoiceInput: widget.showVoiceInput,
              onVoiceInput: (text) {
                _controller.text = text;
                widget.onVoiceInput?.call(text);
                _handleSend();
              },
              borderRadius: 24,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _hasText && widget.isEnabled ? _handleSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasText && widget.isEnabled
                    ? AppColors.primaryColor
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: _hasText && widget.isEnabled
                    ? Colors.white
                    : Colors.grey[600],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}