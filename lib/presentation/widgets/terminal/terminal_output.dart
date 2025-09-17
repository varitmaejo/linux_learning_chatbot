import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';

class TerminalOutput extends StatefulWidget {
  final List<TerminalOutputLine> outputs;
  final bool allowSelection;
  final bool showTimestamps;
  final Function(String)? onCommandClick;
  final ScrollController? scrollController;
  final double fontSize;
  final bool autoScroll;

  const TerminalOutput({
    Key? key,
    required this.outputs,
    this.allowSelection = true,
    this.showTimestamps = false,
    this.onCommandClick,
    this.scrollController,
    this.fontSize = 14.0,
    this.autoScroll = true,
  }) : super(key: key);

  @override
  State<TerminalOutput> createState() => _TerminalOutputState();
}

class _TerminalOutputState extends State<TerminalOutput>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _lastOutputCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _setupAnimation();
    _lastOutputCount = widget.outputs.length;
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void didUpdateWidget(TerminalOutput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.outputs.length > _lastOutputCount) {
      _animationController.forward(from: 0.0);

      if (widget.autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }

    _lastOutputCount = widget.outputs.length;
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: widget.outputs.length,
        itemBuilder: (context, index) {
          final output = widget.outputs[index];
          final isLastItem = index == widget.outputs.length - 1;

          return AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: isLastItem ? _fadeAnimation.value : 1.0,
                child: _buildOutputLine(output, index),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOutputLine(TerminalOutputLine output, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTimestamps) ...[
            Text(
              _formatTimestamp(output.timestamp),
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'monospace',
                fontSize: widget.fontSize - 2,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: _buildContent(output),
          ),
          if (output.type == TerminalOutputType.command)
            _buildActionButtons(output),
        ],
      ),
    );
  }

  Widget _buildContent(TerminalOutputLine output) {
    Widget content = _buildTextContent(output);

    if (widget.allowSelection) {
      content = SelectableText.rich(
        _buildTextSpan(output),
        style: _getTextStyle(output.type),
      );
    } else {
      content = RichText(
        text: _buildTextSpan(output),
      );
    }

    // Add click handler for commands
    if (output.type == TerminalOutputType.command && widget.onCommandClick != null) {
      content = GestureDetector(
        onTap: () => widget.onCommandClick!(output.text),
        child: content,
      );
    }

    return content;
  }

  Widget _buildTextContent(TerminalOutputLine output) {
    switch (output.type) {
      case TerminalOutputType.command:
        return _buildCommandLine(output);
      case TerminalOutputType.output:
        return _buildOutputText(output);
      case TerminalOutputType.error:
        return _buildErrorText(output);
      case TerminalOutputType.directory:
        return _buildDirectoryListing(output);
      case TerminalOutputType.file:
        return _buildFileContent(output);
      case TerminalOutputType.json:
        return _buildJsonContent(output);
      default:
        return _buildPlainText(output);
    }
  }

  Widget _buildCommandLine(TerminalOutputLine output) {
    final parts = output.text.split('\$ ');
    if (parts.length < 2) {
      return _buildPlainText(output);
    }

    final prompt = parts[0] + '\$ ';
    final command = parts[1];

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: prompt,
            style: TextStyle(
              color: Colors.green[400],
              fontFamily: 'monospace',
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: command,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: widget.fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputText(TerminalOutputLine output) {
    return Text(
      output.text,
      style: TextStyle(
        color: Colors.green[300],
        fontFamily: 'monospace',
        fontSize: widget.fontSize,
      ),
    );
  }

  Widget _buildErrorText(TerminalOutputLine output) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[300],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              output.text,
              style: TextStyle(
                color: Colors.red[300],
                fontFamily: 'monospace',
                fontSize: widget.fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryListing(TerminalOutputLine output) {
    final lines = output.text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) return const SizedBox(height: 4);

        return _buildDirectoryItem(line);
      }).toList(),
    );
  }

  Widget _buildDirectoryItem(String line) {
    // Parse ls -la output format
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 9) {
      return Text(
        line,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontSize: widget.fontSize,
        ),
      );
    }

    final permissions = parts[0];
    final size = parts[4];
    final date = '${parts[5]} ${parts[6]} ${parts[7]}';
    final name = parts.sublist(8).join(' ');

    Color nameColor = Colors.white;
    IconData? icon;

    // Determine color and icon based on permissions
    if (permissions.startsWith('d')) {
      nameColor = Colors.blue[300]!;
      icon = Icons.folder;
    } else if (permissions.contains('x')) {
      nameColor = Colors.green[300]!;
      icon = Icons.play_arrow;
    } else if (name.endsWith('.txt') || name.endsWith('.md')) {
      nameColor = Colors.yellow[300]!;
      icon = Icons.description;
    } else {
      icon = Icons.insert_drive_file;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: nameColor, size: 16),
            const SizedBox(width: 4),
          ],
          SizedBox(
            width: 80,
            child: Text(
              permissions,
              style: TextStyle(
                color: Colors.grey[400],
                fontFamily: 'monospace',
                fontSize: widget.fontSize - 2,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              size,
              style: TextStyle(
                color: Colors.grey[400],
                fontFamily: 'monospace',
                fontSize: widget.fontSize - 2,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              date,
              style: TextStyle(
                color: Colors.grey[400],
                fontFamily: 'monospace',
                fontSize: widget.fontSize - 2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: nameColor,
                fontFamily: 'monospace',
                fontSize: widget.fontSize,
                fontWeight: permissions.startsWith('d') ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileContent(TerminalOutputLine output) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: Colors.blue[300],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'File Content',
                style: TextStyle(
                  color: Colors.blue[300],
                  fontFamily: 'monospace',
                  fontSize: widget.fontSize - 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            output.text,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: widget.fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonContent(TerminalOutputLine output) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.code,
                color: Colors.amber[300],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'JSON Output',
                style: TextStyle(
                  color: Colors.amber[300],
                  fontFamily: 'monospace',
                  fontSize: widget.fontSize - 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSyntaxHighlightedJson(output.text),
        ],
      ),
    );
  }

  Widget _buildSyntaxHighlightedJson(String jsonText) {
    // Simple JSON syntax highlighting
    final lines = jsonText.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        return _buildJsonLine(line);
      }).toList(),
    );
  }

  Widget _buildJsonLine(String line) {
    final spans = <TextSpan>[];
    final trimmedLine = line.trimLeft();
    final indentation = line.length - trimmedLine.length;

    // Add indentation
    if (indentation > 0) {
      spans.add(TextSpan(
        text: ' ' * indentation,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontSize: widget.fontSize,
        ),
      ));
    }

    // Simple syntax highlighting
    if (trimmedLine.contains(':')) {
      final parts = trimmedLine.split(':');
      if (parts.length >= 2) {
        // Key
        spans.add(TextSpan(
          text: parts[0],
          style: TextStyle(
            color: Colors.lightBlue[300],
            fontFamily: 'monospace',
            fontSize: widget.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ));

        // Separator
        spans.add(TextSpan(
          text: ':',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: widget.fontSize,
          ),
        ));

        // Value
        final value = parts.sublist(1).join(':');
        Color valueColor = Colors.white;
        if (value.trim().startsWith('"')) {
          valueColor = Colors.green[300]!;
        } else if (value.trim() == 'true' || value.trim() == 'false') {
          valueColor = Colors.purple[300]!;
        } else if (RegExp(r'^\s*\d+').hasMatch(value)) {
          valueColor = Colors.orange[300]!;
        }

        spans.add(TextSpan(
          text: value,
          style: TextStyle(
            color: valueColor,
            fontFamily: 'monospace',
            fontSize: widget.fontSize,
          ),
        ));
      }
    } else {
      spans.add(TextSpan(
        text: trimmedLine,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontSize: widget.fontSize,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildPlainText(TerminalOutputLine output) {
    return Text(
      output.text,
      style: _getTextStyle(output.type),
    );
  }

  Widget _buildActionButtons(TerminalOutputLine output) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          color: Colors.grey[500],
          onPressed: () => _copyToClipboard(output.text),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Copy',
        ),
        const SizedBox(width: 4),
        if (widget.onCommandClick != null)
          IconButton(
            icon: const Icon(Icons.replay, size: 16),
            color: Colors.grey[500],
            onPressed: () => widget.onCommandClick!(output.text),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Run again',
          ),
      ],
    );
  }

  TextSpan _buildTextSpan(TerminalOutputLine output) {
    return TextSpan(
      text: output.text,
      style: _getTextStyle(output.type),
    );
  }

  TextStyle _getTextStyle(TerminalOutputType type) {
    Color color;
    FontWeight fontWeight = FontWeight.normal;

    switch (type) {
      case TerminalOutputType.command:
        color = Colors.white;
        fontWeight = FontWeight.w500;
        break;
      case TerminalOutputType.output:
        color = Colors.green[300]!;
        break;
      case TerminalOutputType.error:
        color = Colors.red[300]!;
        break;
      case TerminalOutputType.info:
        color = Colors.blue[300]!;
        break;
      case TerminalOutputType.system:
        color = Colors.yellow[300]!;
        break;
      case TerminalOutputType.warning:
        color = Colors.orange[300]!;
        break;
      case TerminalOutputType.directory:
        color = Colors.blue[300]!;
        break;
      case TerminalOutputType.file:
        color = Colors.white;
        break;
      case TerminalOutputType.json:
        color = Colors.amber[300]!;
        break;
      case TerminalOutputType.success:
        color = Colors.green[400]!;
        fontWeight = FontWeight.w500;
        break;
    }

    return TextStyle(
      color: color,
      fontFamily: 'monospace',
      fontSize: widget.fontSize,
      fontWeight: fontWeight,
    );
  }

  void _copyToClipboard(String text) {
    // Extract command from prompt if it's a command line
    String textToCopy = text;
    if (text.contains('\$ ')) {
      final parts = text.split('\$ ');
      if (parts.length > 1) {
        textToCopy = parts[1];
      }
    }

    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $textToCopy'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }
}

// Terminal Output Line Model
class TerminalOutputLine {
  final String text;
  final TerminalOutputType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const TerminalOutputLine({
    required this.text,
    required this.type,
    required this.timestamp,
    this.metadata,
  });

  factory TerminalOutputLine.command(String text) {
    return TerminalOutputLine(
      text: text,
      type: TerminalOutputType.command,
      timestamp: DateTime.now(),
    );
  }

  factory TerminalOutputLine.output(String text) {
    return TerminalOutputLine(
      text: text,
      type: TerminalOutputType.output,
      timestamp: DateTime.now(),
    );
  }

  factory TerminalOutputLine.error(String text) {
    return TerminalOutputLine(
      text: text,
      type: TerminalOutputType.error,
      timestamp: DateTime.now(),
    );
  }

  factory TerminalOutputLine.info(String text) {
    return TerminalOutputLine(
      text: text,
      type: TerminalOutputType.info,
      timestamp: DateTime.now(),
    );
  }

  factory TerminalOutputLine.system(String text) {
    return TerminalOutputLine(
      text: text,
      type: TerminalOutputType.system,
      timestamp: DateTime.now(),
    );
  }

  factory TerminalOutputLine.success(String text) {
    return TerminalOutputLine(
      text: text,
      type: TerminalOutputType.success,
      timestamp: DateTime.now(),
    );
  }
}

enum TerminalOutputType {
  command,
  output,
  error,
  info,
  system,
  warning,
  directory,
  file,
  json,
  success,
}

// Live Terminal Output for real-time streaming
class LiveTerminalOutput extends StatefulWidget {
  final Stream<TerminalOutputLine> outputStream;
  final int maxLines;
  final bool autoScroll;
  final Function(String)? onCommandClick;

  const LiveTerminalOutput({
    Key? key,
    required this.outputStream,
    this.maxLines = 1000,
    this.autoScroll = true,
    this.onCommandClick,
  }) : super(key: key);

  @override
  State<LiveTerminalOutput> createState() => _LiveTerminalOutputState();
}

class _LiveTerminalOutputState extends State<LiveTerminalOutput> {
  final List<TerminalOutputLine> _outputs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.outputStream.listen(_onNewOutput);
  }

  void _onNewOutput(TerminalOutputLine output) {
    setState(() {
      _outputs.add(output);

      // Limit the number of lines
      if (_outputs.length > widget.maxLines) {
        _outputs.removeAt(0);
      }
    });

    if (widget.autoScroll) {
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
  }

  @override
  Widget build(BuildContext context) {
    return TerminalOutput(
      outputs: _outputs,
      scrollController: _scrollController,
      onCommandClick: widget.onCommandClick,
      autoScroll: widget.autoScroll,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}