import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/theme/colors.dart';
import '../../data/models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../providers/voice_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isComposing = false;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    _setupVoiceCallbacks();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final showButton = _scrollController.offset > 200;
      if (_showScrollToBottom != showButton) {
        setState(() {
          _showScrollToBottom = showButton;
        });
      }
    });
  }

  void _setupVoiceCallbacks() {
    final voiceProvider = Provider.of<VoiceProvider>(context, listen: false);

    voiceProvider.setSpeechResultCallback((result) {
      _messageController.text = result;
      setState(() {
        _isComposing = result.isNotEmpty;
      });
      _sendMessage(MessageType.voice);
    });

    voiceProvider.setSpeechErrorCallback((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $error'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    });
  }

  void _initializeChat() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      chatProvider.initialize(authProvider.uid);
    }
  }

  void _sendMessage([MessageType type = MessageType.text]) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendMessage(text, type: type);

    _messageController.clear();
    setState(() {
      _isComposing = false;
    });

    _focusNode.unfocus();
    _scrollToBottom();
  }

  void _startVoiceInput() async {
    final voiceProvider = Provider.of<VoiceProvider>(context, listen: false);

    if (!voiceProvider.canUseVoiceInput) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถใช้งานเสียงได้')),
      );
      return;
    }

    try {
      if (voiceProvider.isListening) {
        await voiceProvider.stopListening();
      } else {
        await voiceProvider.startListening();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  void _scrollToBottom() {
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

  void _handleQuickReply(String reply) {
    _messageController.text = reply;
    setState(() {
      _isComposing = reply.isNotEmpty;
    });
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แชทบอท Linux'),
        elevation: 1,
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.hasMessages) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'clear':
                        _showClearChatDialog(chatProvider);
                        break;
                      case 'favorites':
                        _showFavoriteMessages(chatProvider);
                        break;
                      case 'search':
                        _showSearchDialog(chatProvider);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'search',
                      child: ListTile(
                        leading: Icon(Icons.search),
                        title: Text('ค้นหา'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'favorites',
                      child: ListTile(
                        leading: Icon(Icons.favorite),
                        title: Text('ข้อความที่ชอบ'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: ListTile(
                        leading: Icon(Icons.clear_all),
                        title: Text('ล้างการสนทนา'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.state == ChatState.loading && !chatProvider.hasMessages) {
                  return const Center(child: LoadingWidget());
                }

                if (!chatProvider.hasMessages) {
                  return _buildWelcomeMessage();
                }

                return Stack(
                  children: [
                    AnimationLimiter(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: chatProvider.messages.length + (chatProvider.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < chatProvider.messages.length) {
                            final message = chatProvider.messages[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _buildMessageBubble(message, chatProvider),
                                ),
                              ),
                            );
                          } else {
                            return _buildTypingIndicator();
                          }
                        },
                      ),
                    ),

                    // Scroll to bottom button
                    if (_showScrollToBottom)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.small(
                          onPressed: _scrollToBottom,
                          backgroundColor: AppColors.primaryColor,
                          child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _buildInputArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.psychology,
                size: 50,
                color: AppColors.primaryColor,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'สวัสดี! ฉันคือแชทบอท Linux',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              'ถามฉันเกี่ยวกับคำสั่ง Linux หรือขอคำแนะนำการเรียนรู้ได้เลย',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                'คำสั่ง ls คืออะไร?',
                'สอนใช้ cd หน่อย',
                'แนะนำเส้นทางการเรียน',
                'ทำแบบทดสอบ',
              ].map((suggestion) => ActionChip(
                label: Text(suggestion),
                onPressed: () => _handleQuickReply(suggestion),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ChatProvider chatProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.android, color: Colors.white, size: 20),
            ),

          if (!message.isUser) const SizedBox(width: 12),

          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? AppColors.userBubble
                        : AppColors.botBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser
                              ? AppColors.userBubbleText
                              : AppColors.botBubbleText,
                          fontSize: 16,
                        ),
                      ),

                      if (message.hasMetadata && message.messageType == MessageType.linuxCommand)
                        _buildCommandInfo(message),

                      if (message.hasQuickReplies)
                        _buildQuickReplies(message),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.formattedTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),

                    if (!message.isUser) ...[
                      const SizedBox(width: 8),

                      // Voice playback button
                      Consumer<VoiceProvider>(
                        builder: (context, voiceProvider, child) {
                          return InkWell(
                            onTap: () => voiceProvider.speakBotResponse(message.text),
                            child: Icon(
                              Icons.volume_up,
                              size: 16,
                              color: AppColors.mutedText,
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 8),

                      // Favorite button
                      InkWell(
                        onTap: () => chatProvider.toggleFavorite(message.id),
                        child: Icon(
                          message.isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: message.isFavorite ? AppColors.errorColor : AppColors.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (message.isUser) const SizedBox(width: 12),

          if (message.isUser)
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.accentColor,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildCommandInfo(ChatMessage message) {
    final metadata = message.metadata!;
    final examples = metadata['examples'] as List<String>? ?? [];
    final relatedCommands = metadata['relatedCommands'] as List<String>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (examples.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'ตัวอย่าง:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          ...examples.map((example) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              example,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          )),
        ],

        if (relatedCommands.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'คำสั่งที่เกี่ยวข้อง:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: relatedCommands.map((cmd) => ActionChip(
              label: Text(cmd),
              onPressed: () => _handleQuickReply('อธิบายคำสั่ง $cmd'),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickReplies(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: message.quickReplies!.map((reply) => ActionChip(
            label: Text(reply),
            onPressed: () => _handleQuickReply(reply),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryColor,
            child: const Icon(Icons.android, color: Colors.white, size: 20),
          ),

          const SizedBox(width: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.botBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTypingDot(0),
                      _buildTypingDot(1),
                      _buildTypingDot(2),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'กำลังพิมพ์...',
                  style: TextStyle(
                    color: AppColors.botBubbleText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      )..repeat(),
      builder: (context, child) {
        final controller = context.widget as AnimatedBuilder;
        final animationController = controller.animation as AnimationController;

        return Transform.translate(
          offset: Offset(0, -4 *
              (0.5 - 0.5 * ((animationController.value + index * 0.2) % 1.0 - 0.5).abs() * 4)),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          decoration: const InputDecoration(
                            hintText: 'พิมพ์ข้อความ...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onChanged: (text) {
                            setState(() {
                              _isComposing = text.isNotEmpty;
                            });
                          },
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),

                      // Voice input button
                      Consumer<VoiceProvider>(
                        builder: (context, voiceProvider, child) {
                          return IconButton(
                            onPressed: voiceProvider.canUseVoiceInput
                                ? _startVoiceInput
                                : null,
                            icon: Icon(
                              voiceProvider.isListening ? Icons.mic : Icons.mic_none,
                              color: voiceProvider.isListening
                                  ? AppColors.errorColor
                                  : (voiceProvider.canUseVoiceInput
                                  ? AppColors.primaryColor
                                  : AppColors.mutedText),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              Container(
                decoration: BoxDecoration(
                  color: _isComposing ? AppColors.primaryColor : AppColors.mutedText,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed: _isComposing ? _sendMessage : null,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),

          // Voice status indicator
          Consumer<VoiceProvider>(
            builder: (context, voiceProvider, child) {
              if (!voiceProvider.isListening) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mic,
                      size: 16,
                      color: AppColors.errorColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'กำลังฟัง... (แตะเพื่อหยุด)',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.errorColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog(ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ล้างการสนทนา'),
        content: const Text('คุณต้องการลบข้อความทั้งหมดหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              chatProvider.clearMessages();
              Navigator.of(context).pop();
            },
            child: const Text('ล้าง'),
          ),
        ],
      ),
    );
  }

  void _showFavoriteMessages(ChatProvider chatProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'ข้อความที่ชอบ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: chatProvider.favoriteMessages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.favoriteMessages[index];
                    return ListTile(
                      title: Text(message.text),
                      subtitle: Text(message.formattedTime),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite),
                        onPressed: () => chatProvider.toggleFavorite(message.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ค้นหาข้อความ'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'ใส่คำที่ต้องการค้นหา',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (query) {
            Navigator.of(context).pop();
            final results = chatProvider.searchMessages(query);

            // Show search results
            showModalBottomSheet(
              context: context,
              builder: (context) => Container(
                height: 400,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ผลการค้นหา "${query}" (${results.length} รายการ)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final message = results[index];
                          return ListTile(
                            title: Text(message.text),
                            subtitle: Text(message.formattedTime),
                            onTap: () {
                              Navigator.of(context).pop();
                              // Scroll to message (implementation depends on requirements)
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }
}