import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../core/services/terminal_service.dart';
import '../../data/models/terminal_command.dart';

class VirtualTerminal extends StatefulWidget {
  final String? initialDirectory;
  final List<String>? availableCommands;
  final Function(String)? onCommandExecuted;
  final Function(String)? onCommandOutput;
  final bool readOnly;
  final Map<String, String>? environment;

  const VirtualTerminal({
    Key? key,
    this.initialDirectory,
    this.availableCommands,
    this.onCommandExecuted,
    this.onCommandOutput,
    this.readOnly = false,
    this.environment,
  }) : super(key: key);

  @override
  State<VirtualTerminal> createState() => _VirtualTerminalState();
}

class _VirtualTerminalState extends State<VirtualTerminal>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late TerminalService _terminalService;
  List<TerminalOutput> _outputs = [];
  String _currentDirectory = '';
  String _username = 'user';
  String _hostname = 'linux-learning';
  int _commandHistoryIndex = -1;
  List<String> _commandHistory = [];
  bool _isProcessing = false;

  late AnimationController _cursorAnimationController;
  late Animation<double> _cursorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeTerminal();
    _setupAnimations();
  }

  void _initializeTerminal() {
    _terminalService = TerminalService();
    _currentDirectory = widget.initialDirectory ?? '/home/user';

    // Add welcome message
    _addOutput(TerminalOutput(
      text: 'Welcome to Linux Learning Terminal!',
      type: TerminalOutputType.system,
      timestamp: DateTime.now(),
    ));

    _addOutput(TerminalOutput(
      text: 'Type "help" to see available commands.',
      type: TerminalOutputType.info,
      timestamp: DateTime.now(),
    ));

    // Focus on input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.readOnly) {
        _focusNode.requestFocus();
      }
    });
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

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    _cursorAnimationController.dispose();
    super.dispose();
  }

  void _addOutput(TerminalOutput output) {
    setState(() {
      _outputs.add(output);
    });

    widget.onCommandOutput?.call(output.text);

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _executeCommand(String command) async {
    if (command.trim().isEmpty || widget.readOnly) return;

    setState(() {
      _isProcessing = true;
    });

    // Add command to history
    if (_commandHistory.isEmpty || _commandHistory.last != command) {
      _commandHistory.add(command);
    }
    _commandHistoryIndex = -1;

    // Add command to output
    _addOutput(TerminalOutput(
      text: '${_getPrompt()}$command',
      type: TerminalOutputType.command,
      timestamp: DateTime.now(),
    ));

    widget.onCommandExecuted?.call(command);

    try {
      final result = await _terminalService.executeCommand(
        command,
        _currentDirectory,
        environment: widget.environment,
      );

      // Update current directory if changed
      if (result.newDirectory != null) {
        _currentDirectory = result.newDirectory!;
      }

      // Add output
      if (result.output.isNotEmpty) {
        _addOutput(TerminalOutput(
          text: result.output,
          type: result.isError
              ? TerminalOutputType.error
              : TerminalOutputType.output,
          timestamp: DateTime.now(),
        ));
      }

      // Add error if exists
      if (result.error.isNotEmpty) {
        _addOutput(TerminalOutput(
          text: result.error,
          type: TerminalOutputType.error,
          timestamp: DateTime.now(),
        ));
      }

    } catch (e) {
      _addOutput(TerminalOutput(
        text: 'Error: $e',
        type: TerminalOutputType.error,
        timestamp: DateTime.now(),
      ));
    }

    setState(() {
      _isProcessing = false;
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _executeCommand(_inputController.text);
        _inputController.clear();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _navigateHistory(true);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _navigateHistory(false);
      } else if (event.logicalKey == LogicalKeyboardKey.tab) {
        _handleTabCompletion();
      }
    }
  }

  void _navigateHistory(bool up) {
    if (_commandHistory.isEmpty) return;

    if (up) {
      if (_commandHistoryIndex == -1) {
        _commandHistoryIndex = _commandHistory.length - 1;
      } else if (_commandHistoryIndex > 0) {
        _commandHistoryIndex--;
      }
    } else {
      if (_commandHistoryIndex < _commandHistory.length - 1) {
        _commandHistoryIndex++;
      } else {
        _commandHistoryIndex = -1;
        _inputController.clear();
        return;
      }
    }

    if (_commandHistoryIndex >= 0 && _commandHistoryIndex < _commandHistory.length) {
      _inputController.text = _commandHistory[_commandHistoryIndex];
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );
    }
  }

  void _handleTabCompletion() {
    // Simple tab completion implementation
    final currentText = _inputController.text;
    if (currentText.isEmpty) return;

    final availableCommands = widget.availableCommands ?? [
      'ls', 'cd', 'pwd', 'mkdir', 'rmdir', 'touch', 'rm', 'cp', 'mv',
      'cat', 'grep', 'find', 'chmod', 'chown', 'ps', 'top', 'kill',
      'man', 'help', 'clear', 'history', 'which', 'whoami'
    ];

    final matches = availableCommands
        .where((cmd) => cmd.startsWith(currentText))
        .toList();

    if (matches.length == 1) {
      _inputController.text = matches.first + ' ';
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );
    } else if (matches.length > 1) {
      _addOutput(TerminalOutput(
        text: matches.join('  '),
        type: TerminalOutputType.info,
        timestamp: DateTime.now(),
      ));
    }
  }

  String _getPrompt() {
    final shortPath = _currentDirectory.replaceAll('/home/$_username', '~');
    return '$_username@$_hostname:$shortPath\$ ';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTerminalHeader(),
          Expanded(
            child: _buildTerminalBody(),
          ),
          if (!widget.readOnly) _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTerminalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          _buildTrafficLight(Colors.red),
          const SizedBox(width: 6),
          _buildTrafficLight(Colors.yellow),
          const SizedBox(width: 6),
          _buildTrafficLight(Colors.green),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Terminal - $_currentDirectory',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_isProcessing) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrafficLight(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTerminalBody() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _outputs.length,
              itemBuilder: (context, index) {
                return _buildOutputLine(_outputs[index]);
              },
            ),
          ),
          if (!widget.readOnly && !_isProcessing)
            _buildCurrentPrompt(),
        ],
      ),
    );
  }

  Widget _buildOutputLine(TerminalOutput output) {
    Color textColor;
    FontWeight fontWeight = FontWeight.normal;

    switch (output.type) {
      case TerminalOutputType.command:
        textColor = Colors.white;
        fontWeight = FontWeight.w500;
        break;
      case TerminalOutputType.output:
        textColor = Colors.green[300]!;
        break;
      case TerminalOutputType.error:
        textColor = Colors.red[300]!;
        break;
      case TerminalOutputType.info:
        textColor = Colors.blue[300]!;
        break;
      case TerminalOutputType.system:
        textColor = Colors.yellow[300]!;
        break;
      case TerminalOutputType.warning:
        textColor = Colors.orange[300]!;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: SelectableText(
        output.text,
        style: TextStyle(
          color: textColor,
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: fontWeight,
        ),
      ),
    );
  }

  Widget _buildCurrentPrompt() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
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
          child: Text(
            _inputController.text,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _cursorAnimation,
          builder: (context, child) {
            return Container(
              width: 8,
              height: 16,
              color: Colors.white.withOpacity(_cursorAnimation.value),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: TextField(
          controller: _inputController,
          style: const TextStyle(
            color: Colors.transparent,
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          autofocus: true,
          enabled: !_isProcessing,
        ),
      ),
    );
  }
}

// Terminal output model
class TerminalOutput {
  final String text;
  final TerminalOutputType type;
  final DateTime timestamp;

  const TerminalOutput({
    required this.text,
    required this.type,
    required this.timestamp,
  });
}

enum TerminalOutputType {
  command,
  output,
  error,
  info,
  system,
  warning,
}

// Compact Terminal Widget
class CompactTerminal extends StatefulWidget {
  final List<String> commands;
  final Function(String)? onCommandExecuted;
  final double height;

  const CompactTerminal({
    Key? key,
    required this.commands,
    this.onCommandExecuted,
    this.height = 200,
  }) : super(key: key);

  @override
  State<CompactTerminal> createState() => _CompactTerminalState();
}

class _CompactTerminalState extends State<CompactTerminal> {
  final PageController _pageController = PageController();
  int _currentCommandIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.commands.length,
              onPageChanged: (index) {
                setState(() {
                  _currentCommandIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildCommandPage(widget.commands[index]);
              },
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Terminal Example',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '${_currentCommandIndex + 1}/${widget.commands.length}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandPage(String command) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'user@linux-learning:~\$ ',
                style: TextStyle(
                  color: Colors.green[400],
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  command,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.green,
                  size: 20,
                ),
                onPressed: () {
                  widget.onCommandExecuted?.call(command);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Click the play button to execute this command',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white70),
            onPressed: _currentCommandIndex > 0 ? _previousCommand : null,
            iconSize: 20,
          ),
          const SizedBox(width: 16),
          ...List.generate(widget.commands.length, (index) {
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index == _currentCommandIndex
                    ? AppColors.primaryColor
                    : Colors.grey[600],
                shape: BoxShape.circle,
              ),
            );
          }),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white70),
            onPressed: _currentCommandIndex < widget.commands.length - 1
                ? _nextCommand
                : null,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  void _previousCommand() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextCommand() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}