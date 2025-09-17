import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';

class CommandInput extends StatefulWidget {
  final Function(String) onCommandSubmitted;
  final Function(String)? onTextChanged;
  final List<String>? commandHistory;
  final List<String>? availableCommands;
  final String? currentDirectory;
  final String? username;
  final String? hostname;
  final bool isEnabled;
  final bool showSuggestions;
  final String? placeholder;

  const CommandInput({
    Key? key,
    required this.onCommandSubmitted,
    this.onTextChanged,
    this.commandHistory,
    this.availableCommands,
    this.currentDirectory,
    this.username,
    this.hostname,
    this.isEnabled = true,
    this.showSuggestions = true,
    this.placeholder,
  }) : super(key: key);

  @override
  State<CommandInput> createState() => _CommandInputState();
}

class _CommandInputState extends State<CommandInput>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<String> _filteredSuggestions = [];
  int _historyIndex = -1;
  int _selectedSuggestionIndex = -1;

  late AnimationController _cursorAnimationController;
  late Animation<double> _cursorAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupListeners();
  }

  void _setupAnimations() {
    _cursorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cursorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_cursorAnimationController);

    _cursorAnimationController.repeat(reverse: true);
  }

  void _setupListeners() {
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    _cursorAnimationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    widget.onTextChanged?.call(text);

    if (widget.showSuggestions && text.isNotEmpty) {
      _updateSuggestions(text);
    } else {
      _removeOverlay();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _updateSuggestions(String text) {
    final commands = widget.availableCommands ?? _getDefaultCommands();
    _filteredSuggestions = commands
        .where((command) => command.toLowerCase().startsWith(text.toLowerCase()))
        .take(5)
        .toList();

    _selectedSuggestionIndex = -1;

    if (_filteredSuggestions.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _filteredSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _filteredSuggestions[index];
                  final isSelected = index == _selectedSuggestionIndex;

                  return _buildSuggestionItem(suggestion, isSelected, index);
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildSuggestionItem(String suggestion, bool isSelected, int index) {
    return InkWell(
      onTap: () => _selectSuggestion(suggestion),
      onHover: (hovering) {
        if (hovering) {
          setState(() {
            _selectedSuggestionIndex = index;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.2) : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.terminal,
              size: 16,
              color: isSelected ? AppColors.primaryColor : Colors.grey[400],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                suggestion,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryColor : Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.keyboard_return,
                size: 14,
                color: AppColors.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion + ' ';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    _removeOverlay();
    _focusNode.requestFocus();
  }

  void _navigateHistory(bool up) {
    final history = widget.commandHistory ?? [];
    if (history.isEmpty) return;

    if (up) {
      if (_historyIndex == -1) {
        _historyIndex = history.length - 1;
      } else if (_historyIndex > 0) {
        _historyIndex--;
      }
    } else {
      if (_historyIndex < history.length - 1) {
        _historyIndex++;
      } else {
        _historyIndex = -1;
        _controller.clear();
        return;
      }
    }

    if (_historyIndex >= 0 && _historyIndex < history.length) {
      _controller.text = history[_historyIndex];
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  void _navigateSuggestions(bool up) {
    if (_filteredSuggestions.isEmpty) return;

    setState(() {
      if (up) {
        _selectedSuggestionIndex = _selectedSuggestionIndex <= 0
            ? _filteredSuggestions.length - 1
            : _selectedSuggestionIndex - 1;
      } else {
        _selectedSuggestionIndex = _selectedSuggestionIndex >= _filteredSuggestions.length - 1
            ? 0
            : _selectedSuggestionIndex + 1;
      }
    });

    _showOverlay(); // Refresh overlay to show selection
  }

  void _handleTabCompletion() {
    if (_filteredSuggestions.isNotEmpty) {
      _selectSuggestion(_filteredSuggestions.first);
    }
  }

  void _submitCommand() {
    final command = _controller.text.trim();
    if (command.isNotEmpty) {
      widget.onCommandSubmitted(command);
      _controller.clear();
      _historyIndex = -1;
      _removeOverlay();
    }
  }

  String _getPrompt() {
    final user = widget.username ?? 'user';
    final host = widget.hostname ?? 'linux-learning';
    final dir = widget.currentDirectory?.replaceAll('/home/$user', '~') ?? '~';
    return '$user@$host:$dir\$ ';
  }

  List<String> _getDefaultCommands() {
    return [
      'ls', 'cd', 'pwd', 'mkdir', 'rmdir', 'touch', 'rm', 'cp', 'mv',
      'cat', 'grep', 'find', 'chmod', 'chown', 'ps', 'top', 'kill',
      'man', 'help', 'clear', 'history', 'which', 'whoami', 'date',
      'echo', 'head', 'tail', 'less', 'more', 'sort', 'uniq', 'wc',
      'tar', 'gzip', 'gunzip', 'zip', 'unzip', 'wget', 'curl', 'ssh',
      'scp', 'ping', 'netstat', 'ifconfig', 'df', 'du', 'free', 'uname',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(
            color: _focusNode.hasFocus
                ? AppColors.primaryColor
                : Colors.grey[700]!,
            width: _focusNode.hasFocus ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.enter) {
                if (_selectedSuggestionIndex >= 0 && _filteredSuggestions.isNotEmpty) {
                  _selectSuggestion(_filteredSuggestions[_selectedSuggestionIndex]);
                } else {
                  _submitCommand();
                }
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                if (_filteredSuggestions.isNotEmpty) {
                  _navigateSuggestions(true);
                } else {
                  _navigateHistory(true);
                }
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                if (_filteredSuggestions.isNotEmpty) {
                  _navigateSuggestions(false);
                } else {
                  _navigateHistory(false);
                }
              } else if (event.logicalKey == LogicalKeyboardKey.tab) {
                _handleTabCompletion();
              } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                _removeOverlay();
              }
            }
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _getPrompt(),
                style: TextStyle(
                  color: Colors.green[400],
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.isEnabled,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.placeholder,
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _submitCommand(),
                ),
              ),
              if (!widget.isEnabled)
                AnimatedBuilder(
                  animation: _cursorAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 2,
                      height: 16,
                      color: Colors.white.withOpacity(_cursorAnimation.value),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simplified Command Input for embedded use
class SimpleCommandInput extends StatefulWidget {
  final Function(String) onCommandSubmitted;
  final String? placeholder;
  final bool isEnabled;

  const SimpleCommandInput({
    Key? key,
    required this.onCommandSubmitted,
    this.placeholder,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  State<SimpleCommandInput> createState() => _SimpleCommandInputState();
}

class _SimpleCommandInputState extends State<SimpleCommandInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Text(
            '\$ ',
            style: TextStyle(
              color: Colors.green[400],
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.isEnabled,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.placeholder ?? 'Enter command...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (command) {
                if (command.trim().isNotEmpty) {
                  widget.onCommandSubmitted(command.trim());
                  _controller.clear();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.send,
              color: Colors.green,
              size: 20,
            ),
            onPressed: widget.isEnabled ? () {
              final command = _controller.text.trim();
              if (command.isNotEmpty) {
                widget.onCommandSubmitted(command);
                _controller.clear();
              }
            } : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Command Input with Autocomplete
class AutocompleteCommandInput extends StatefulWidget {
  final Function(String) onCommandSubmitted;
  final List<String> availableCommands;
  final Map<String, List<String>>? commandOptions;
  final String? currentDirectory;

  const AutocompleteCommandInput({
    Key? key,
    required this.onCommandSubmitted,
    required this.availableCommands,
    this.commandOptions,
    this.currentDirectory,
  }) : super(key: key);

  @override
  State<AutocompleteCommandInput> createState() => _AutocompleteCommandInputState();
}

class _AutocompleteCommandInputState extends State<AutocompleteCommandInput> {
  final TextEditingController _controller = TextEditingController();
  String _currentCompletion = '';

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        final text = textEditingValue.text;
        if (text.isEmpty) return const Iterable<String>.empty();

        final words = text.split(' ');
        final lastWord = words.last;

        if (words.length == 1) {
          // Complete command names
          return widget.availableCommands.where((command) {
            return command.toLowerCase().startsWith(lastWord.toLowerCase());
          });
        } else {
          // Complete command options
          final command = words.first;
          final options = widget.commandOptions?[command] ?? [];
          return options.where((option) {
            return option.toLowerCase().startsWith(lastWord.toLowerCase());
          });
        }
      },
      onSelected: (String selection) {
        final words = _controller.text.split(' ');
        words[words.length - 1] = selection;
        _controller.text = words.join(' ') + ' ';
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _controller.text = controller.text;
        return CommandInput(
          onCommandSubmitted: widget.onCommandSubmitted,
          availableCommands: widget.availableCommands,
          currentDirectory: widget.currentDirectory,
          placeholder: 'Type a command and press Enter...',
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 300,
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}