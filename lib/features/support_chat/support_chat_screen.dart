import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = Dio();
  
  String _sessionId = '';
  String _webhookUrl = '';
  bool _isLoading = false;

  static const String _prefWebhookKey = 'n8n_webhook_url';
  static const String _prefSessionKey = 'n8n_session_id';
  static const String _prefHistoryKey = 'n8n_chat_history';

  static const String _defaultUrl = 'https://thegoat7.app.n8n.cloud/webhook/insight360-support';

  final List<String> _quickReplies = [
    "What is Insight 360?",
    "How can I save an article?",
    "How does the search screen work?",
    "Can I read news offline?",
  ];

  @override
  void initState() {
    super.initState();
    _loadSettingsAndHistory();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _webhookUrl = prefs.getString(_prefWebhookKey) ?? _defaultUrl;
    });

    String? storedSessionId = prefs.getString(_prefSessionKey);
    if (storedSessionId == null || storedSessionId.isEmpty) {
      storedSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}';
      await prefs.setString(_prefSessionKey, storedSessionId);
    }
    _sessionId = storedSessionId;

    // Load chat history
    final historyJson = prefs.getStringList(_prefHistoryKey);
    if (historyJson != null) {
      setState(() {
        _messages.clear();
        for (var item in historyJson) {
          try {
            _messages.add(ChatMessage.fromJson(jsonDecode(item)));
          } catch (e) {
            // Ignore malformed messages
          }
        }
      });
      _scrollToBottom();
    } else {
      // Add a welcoming message if the chat is completely fresh
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Hello! I am your Insight 360 Support Assistant. How can I help you today?",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyList = _messages.map((msg) => jsonEncode(msg.toJson())).toList();
    await prefs.setStringList(_prefHistoryKey, historyList);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefHistoryKey);
    
    // Generate new Session ID
    final newSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}';
    await prefs.setString(_prefSessionKey, newSessionId);

    setState(() {
      _sessionId = newSessionId;
      _messages.clear();
      _messages.add(
        ChatMessage(
          text: "Conversation cleared. How can I help you today?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _saveWebhookUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefWebhookKey, newUrl);
    setState(() {
      _webhookUrl = newUrl;
    });
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

  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    
    _textController.clear();
    _scrollToBottom();
    await _saveHistory();

    // Call n8n Webhook
    try {
      final response = await _dio.post(
        _webhookUrl,
        data: {
          'message': text,
          'session_id': _sessionId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 15),
          connectTimeout: const Duration(seconds: 15),
        ),
      );

      String botReply = '';
      if (response.data != null) {
        // Support common formats returned by n8n nodes (e.g. reply, output, response, message, text)
        if (response.data is Map) {
          botReply = response.data['reply'] ?? 
                     response.data['output'] ?? 
                     response.data['response'] ?? 
                     response.data['message'] ?? 
                     response.data['text'] ?? 
                     '';
        } else if (response.data is List && response.data.isNotEmpty) {
          final first = response.data.first;
          botReply = first is Map 
              ? (first['reply'] ?? first['output'] ?? first['response'] ?? first['message'] ?? first['text'] ?? '') 
              : first.toString();
        } else {
          botReply = response.data.toString();
        }
      }

      if (botReply.isEmpty) {
        botReply = "I received an empty response from the support workflow.";
      }

      setState(() {
        _messages.add(
          ChatMessage(
            text: botReply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } on DioException catch (e) {
      String errorMessage = "Network error: Failed to connect to support workflow.";
      if (e.response != null) {
        if (e.response!.statusCode == 404) {
          errorMessage = "Error 404: The n8n Webhook is not registered or the workflow is not active.\n\n"
              "Please make sure:\n"
              "1. You are calling the correct URL.\n"
              "2. If using the Production URL, the workflow is toggled ACTIVE in n8n.\n"
              "3. If using the Test URL, you have clicked 'Execute Workflow' in n8n before sending.";
        } else {
          errorMessage = "Server error (${e.response!.statusCode}): ${e.response!.statusMessage}";
        }
      }
      
      setState(() {
        _messages.add(
          ChatMessage(
            text: errorMessage,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "An unexpected error occurred: $e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
      await _saveHistory();
    }
  }

  void _showSettingsDialog() {
    final controller = TextEditingController(text: _webhookUrl);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Webhook Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your n8n Webhook URL:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'http://<host>:<port>/webhook/<webhook-name>',
                  helperText: 'Avoid spaces or newlines at the end.',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Current Session ID: $_sessionId',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final cleanedUrl = controller.text.trim();
                _saveWebhookUrl(cleanedUrl);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Webhook URL updated: $cleanedUrl')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.support_agent,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insight 360 Agent',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            tooltip: 'Clear Chat History',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat?'),
                  content: const Text('This will delete all message history and start a new session.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearHistory();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: _showSettingsDialog,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
        
          // Chat message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          // Typing Indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('AI Support is typing ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        SizedBox(width: 4),
                        TypingIndicator(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Quick Replies horizontal scroll list
          if (!_isLoading)
            _buildQuickRepliesSection(),
          // Input field
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUser = message.isUser;
    final String timeStr = TimeOfDay.fromDateTime(message.timestamp).format(context);
    
    final Widget bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.70,
      ),
      decoration: BoxDecoration(
        color: isUser ? AppColors.primary : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 0),
          bottomRight: Radius.circular(isUser ? 0 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
              fontSize: 15,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              timeStr,
              style: TextStyle(
                color: isUser ? Colors.white60 : Colors.black38,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: Alignment.centerRight,
          child: bubble,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              bubble,
            ],
          ),
        ),
      );
    }
  }

  Widget _buildQuickRepliesSection() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickReplies.length,
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ActionChip(
              backgroundColor: AppColors.fill,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              label: Text(
                reply,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _handleSendMessage(reply),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final text = _textController.text.trim();
                if (text.isNotEmpty) {
                  _handleSendMessage(text);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Typing Indicator Dot Animation
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double offset = (index * 0.2);
            double value = (math.sin((_controller.value * 2 * math.pi) - (offset * 2 * math.pi)) + 1) / 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3 + (0.7 * value)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
