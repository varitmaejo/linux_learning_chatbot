import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../core/theme/colors.dart';
import '../../core/services/voice_service.dart';

class VoiceInputWidget extends StatefulWidget {
  final Function(String) onVoiceInput;
  final Function()? onStartListening;
  final Function()? onStopListening;
  final bool isEnabled;
  final Color? primaryColor;
  final Color? backgroundColor;

  const VoiceInputWidget({
    Key? key,
    required this.onVoiceInput,
    this.onStartListening,
    this.onStopListening,
    this.isEnabled = true,
    this.primaryColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with TickerProviderStateMixin {
  bool _isListening = false;
  bool _isProcessing = false;
  String _currentTranscript = '';
  double _soundLevel = 0.0;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  Timer? _soundLevelTimer;
  final VoiceService _voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVoiceService();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeVoiceService() {
    _voiceService.initialize();

    _voiceService.onResult = (result) {
      if (mounted) {
        setState(() {
          _currentTranscript = result;
        });
      }
    };

    _voiceService.onFinalResult = (result) {
      if (mounted && result.isNotEmpty) {
        widget.onVoiceInput(result);
        _stopListening();
      }
    };

    _voiceService.onSoundLevelChange = (level) {
      if (mounted) {
        setState(() {
          _soundLevel = level;
        });
      }
    };

    _voiceService.onError = (error) {
      if (mounted) {
        _showErrorSnackBar(error);
        _stopListening();
      }
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _soundLevelTimer?.cancel();
    _voiceService.dispose();
    super.dispose();
  }

  void _startListening() async {
    if (!widget.isEnabled || _isListening) return;

    final hasPermission = await _voiceService.requestPermission();
    if (!hasPermission) {
      _showErrorSnackBar('ไม่สามารถเข้าถึงไมโครโฟนได้');
      return;
    }

    try {
      await _voiceService.startListening();

      if (mounted) {
        setState(() {
          _isListening = true;
          _currentTranscript = '';
        });

        _pulseController.repeat(reverse: true);
        _waveController.repeat(reverse: true);

        widget.onStartListening?.call();
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเริ่มต้นการฟัง: $e');
    }
  }

  void _stopListening() async {
    if (!_isListening) return;

    try {
      await _voiceService.stopListening();

      if (mounted) {
        setState(() {
          _isListening = false;
          _isProcessing = false;
          _currentTranscript = '';
          _soundLevel = 0.0;
        });

        _pulseController.stop();
        _pulseController.reset();
        _waveController.stop();
        _waveController.reset();

        widget.onStopListening?.call();
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการหยุดการฟัง: $e');
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isListening && _currentTranscript.isNotEmpty)
          _buildTranscriptDisplay(),

        const SizedBox(height: 16),

        _buildVoiceButton(),

        if (_isListening) ...[
          const SizedBox(height: 16),
          _buildSoundLevelIndicator(),
        ],
      ],
    );
  }

  Widget _buildTranscriptDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.primaryColor ?? AppColors.primaryColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                size: 16,
                color: widget.primaryColor ?? AppColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'กำลังฟัง...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: widget.primaryColor ?? AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentTranscript.isEmpty
                ? 'พูดอะไรสักอย่าง...'
                : _currentTranscript,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _currentTranscript.isEmpty
                  ? Colors.grey
                  : Theme.of(context).textTheme.bodyMedium?.color,
              fontStyle: _currentTranscript.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton() {
    return GestureDetector(
      onTap: widget.isEnabled ? _toggleListening : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
        builder: (context, child) {
          final scale = _isListening
              ? _pulseAnimation.value * _scaleAnimation.value
              : 1.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? (widget.primaryColor ?? AppColors.primaryColor)
                    : (widget.backgroundColor ?? Colors.grey[300]),
                boxShadow: _isListening
                    ? [
                  BoxShadow(
                    color: (widget.primaryColor ?? AppColors.primaryColor)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 32,
                color: _isListening
                    ? Colors.white
                    : (widget.isEnabled ? Colors.grey[600] : Colors.grey[400]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSoundLevelIndicator() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(20, (index) {
          final barHeight = _soundLevel > (index / 20)
              ? (20 + (index * 2)).toDouble()
              : 8.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 3,
            height: barHeight,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _soundLevel > (index / 20)
                  ? (widget.primaryColor ?? AppColors.primaryColor)
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
}

// Compact voice input button for use in text fields
class CompactVoiceButton extends StatefulWidget {
  final Function(String) onVoiceInput;
  final bool isEnabled;
  final Color? color;
  final double size;

  const CompactVoiceButton({
    Key? key,
    required this.onVoiceInput,
    this.isEnabled = true,
    this.color,
    this.size = 24.0,
  }) : super(key: key);

  @override
  State<CompactVoiceButton> createState() => _CompactVoiceButtonState();
}

class _CompactVoiceButtonState extends State<CompactVoiceButton>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  final VoiceService _voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeVoiceService();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeVoiceService() {
    _voiceService.initialize();

    _voiceService.onFinalResult = (result) {
      if (mounted && result.isNotEmpty) {
        widget.onVoiceInput(result);
        _stopListening();
      }
    };

    _voiceService.onError = (error) {
      if (mounted) {
        _stopListening();
      }
    };
  }

  @override
  void dispose() {
    _animationController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  void _startListening() async {
    if (!widget.isEnabled || _isListening) return;

    final hasPermission = await _voiceService.requestPermission();
    if (!hasPermission) return;

    try {
      await _voiceService.startListening();

      if (mounted) {
        setState(() {
          _isListening = true;
        });

        _animationController.repeat(reverse: true);
      }
    } catch (e) {
      // Handle error silently for compact button
    }
  }

  void _stopListening() async {
    if (!_isListening) return;

    try {
      await _voiceService.stopListening();

      if (mounted) {
        setState(() {
          _isListening = false;
        });

        _animationController.stop();
        _animationController.reset();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isEnabled ? _toggleListening : null,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isListening ? _pulseAnimation.value : 1.0,
            child: Container(
              width: widget.size + 8,
              height: widget.size + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? (widget.color ?? AppColors.primaryColor).withOpacity(0.2)
                    : Colors.transparent,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: widget.size,
                color: _isListening
                    ? (widget.color ?? AppColors.primaryColor)
                    : (widget.isEnabled
                    ? Colors.grey[600]
                    : Colors.grey[400]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Voice input dialog
class VoiceInputDialog extends StatefulWidget {
  final Function(String) onVoiceInput;
  final String? title;
  final String? hint;

  const VoiceInputDialog({
    Key? key,
    required this.onVoiceInput,
    this.title,
    this.hint,
  }) : super(key: key);

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog> {
  String _transcript = '';
  bool _isListening = false;

  void _onVoiceInput(String input) {
    widget.onVoiceInput(input);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title ?? 'การป้อนเสียง'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.hint != null)
            Text(
              widget.hint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(height: 24),
          VoiceInputWidget(
            onVoiceInput: _onVoiceInput,
            onStartListening: () {
              setState(() {
                _isListening = true;
              });
            },
            onStopListening: () {
              setState(() {
                _isListening = false;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
      ],
    );
  }

  static void show(
      BuildContext context, {
        required Function(String) onVoiceInput,
        String? title,
        String? hint,
      }) {
    showDialog(
      context: context,
      builder: (context) => VoiceInputDialog(
        onVoiceInput: onVoiceInput,
        title: title,
        hint: hint,
      ),
    );
  }
}