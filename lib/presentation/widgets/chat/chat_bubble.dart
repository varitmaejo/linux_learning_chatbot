import 'package:flutter/material.dart';
import '../../data/models/chat_message.dart';
import '../../core/theme/colors.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTimestamp;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ChatBubble({
    Key? key,
    required this.message,
    this.showTimestamp = true,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 16,
        ),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) _buildAvatar(),
            if (!isUser) const SizedBox(width: 8),

            Flexible(
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _getBubbleColor(theme, isUser),
                      borderRadius: _getBorderRadius(isUser),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMessageContent(theme, isUser),
                        if (message.type == MessageType.linuxCommand)
                          _buildCommandActions(),
                      ],
                    ),
                  ),

                  if (showTimestamp)
                    _buildTimestamp(theme),
                ],
              ),
            ),

            if (isUser) const SizedBox(width: 8),
            if (isUser) _buildAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: message.isUser
          ? AppColors.primaryColor
          : AppColors.accentColor,
      child: Icon(
        message.isUser ? Icons.person : Icons.smart_toy,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMessageContent(ThemeData theme, bool isUser) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser ? Colors.white : Colors.black87,
          ),
        );

      case MessageType.linuxCommand:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            if (message.commandDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                message.commandDetails!.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isUser ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ],
        );

      case MessageType.quiz:
        return _buildQuizContent(theme, isUser);

      case MessageType.quizResult:
        return _buildQuizResultContent(theme, isUser);

      case MessageType.voice:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.volume_up,
              size: 20,
              color: isUser ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              'ข้อความเสียง',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isUser ? Colors.white : Colors.black87,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );

      case MessageType.suggestions:
        return _buildSuggestionsContent(theme, isUser);

      default:
        return Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser ? Colors.white : Colors.black87,
          ),
        );
    }
  }

  Widget _buildQuizContent(ThemeData theme, bool isUser) {
    if (message.quizDetails == null) {
      return Text(message.content);
    }

    final quiz = message.quizDetails!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          quiz.question,
          style: theme.textTheme.titleSmall?.copyWith(
            color: isUser ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...quiz.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  '${String.fromCharCode(65 + index)}. ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isUser ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    option,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildQuizResultContent(ThemeData theme, bool isUser) {
    if (message.quizResultDetails == null) {
      return Text(message.content);
    }

    final result = message.quizResultDetails!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              result.isCorrect ? Icons.check_circle : Icons.cancel,
              color: result.isCorrect ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              result.isCorrect ? 'ถูกต้อง!' : 'ผิด',
              style: theme.textTheme.titleSmall?.copyWith(
                color: result.isCorrect ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!result.isCorrect) ...[
          Text(
            'คำตอบที่ถูกต้อง: ${result.correctAnswer}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isUser ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          result.explanation,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsContent(ThemeData theme, bool isUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
        if (message.suggestions != null && message.suggestions!.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...message.suggestions!.map((suggestion) => Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isUser ? Colors.white : AppColors.primaryColor)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isUser ? Colors.white : AppColors.primaryColor)
                    .withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              suggestion,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isUser ? Colors.white70 : AppColors.primaryColor,
              ),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildCommandActions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: () {
              // Execute command in terminal
            },
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('เรียกใช้'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {
              // Copy command to clipboard
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('คัดลอก'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        _formatTimestamp(message.timestamp),
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.grey,
          fontSize: 11,
        ),
      ),
    );
  }

  Color _getBubbleColor(ThemeData theme, bool isUser) {
    if (isUser) {
      return AppColors.primaryColor;
    } else {
      return theme.brightness == Brightness.dark
          ? Colors.grey[800]!
          : Colors.grey[200]!;
    }
  }

  BorderRadius _getBorderRadius(bool isUser) {
    return BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isUser ? 16 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 16),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }
}