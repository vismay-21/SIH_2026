import 'package:flutter/material.dart';

import '../../models/api/api_models.dart';
import '../../models/api/api_response.dart';
import '../../repositories/chat_repository.dart';
import '../../services/token_storage.dart';
import '../../theme/app_theme.dart';

/// Common Chat Screen shared between Customer and Worker (Common Screen #6)
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.gigId,
  });

  final String title;
  final String subtitle;
  final String? gigId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatRepo = ChatRepository();
  final TextEditingController _controller = TextEditingController();

  List<MessageDto> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.gigId != null) {
      _loadMessages();
    }
  }

  Future<void> _loadMessages() async {
    if (widget.gigId == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messagesResp = await _chatRepo.getMessages(widget.gigId!);
      if (!mounted) return;
      setState(() {
        _messages = messagesResp.messages;
        _isLoading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    if (widget.gigId == null) {
      _controller.clear();
      return;
    }

    setState(() => _isSending = true);

    try {
      final msg = await _chatRepo.sendMessage(widget.gigId!, text);
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
        _controller.clear();
        _isSending = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = TokenStorage.instance.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          if (widget.gigId != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadMessages,
              tooltip: 'Refresh messages',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 36, color: Colors.red),
                              const SizedBox(height: 8),
                              Text(_errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _loadMessages,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _messages.isEmpty
                        ? const Center(
                            child: Text(
                              'No messages yet. Send a message to start the conversation.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMe = msg.senderId == currentUserId;

                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppColors.primary
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(14),
                                      topRight: const Radius.circular(14),
                                      bottomLeft: Radius.circular(isMe ? 14 : 2),
                                      bottomRight: Radius.circular(isMe ? 2 : 14),
                                    ),
                                    border: Border.all(
                                      color: isMe
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe && msg.senderName != null) ...[
                                        Text(
                                          msg.senderName!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                      Text(
                                        msg.messageText,
                                        style: TextStyle(
                                          color: isMe ? Colors.white : AppColors.text,
                                          fontSize: 13,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white.withValues(alpha: 0.7)
                                              : AppColors.muted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  _isSending
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send_rounded),
                          color: AppColors.primary,
                          onPressed: _sendMessage,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
