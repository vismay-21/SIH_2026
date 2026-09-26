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
  final ScrollController _scrollController = ScrollController();

  List<MessageDto> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadMessages() async {
    final gigId = widget.gigId;
    final isRealBackendGig = gigId != null && !gigId.startsWith('job-');

    if (!isRealBackendGig) {
      if (_messages.isEmpty) {
        final isWorker = TokenStorage.instance.currentUser?.role == 'worker';
        setState(() {
          _messages = [
            MessageDto(
              id: 'demo-msg-1',
              conversationId: gigId ?? 'demo',
              senderId: 'counterparty-id',
              senderName: widget.title,
              senderRole: isWorker ? 'customer' : 'worker',
              messageText: isWorker
                  ? 'Hello! Looking forward to having the job done. Let me know if you need any directions.'
                  : 'Hello! I am on my way to the site now.',
              isRead: true,
              createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
            ),
          ];
        });
        _scrollToBottom();
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messagesResp = await _chatRepo.getMessages(gigId);
      if (!mounted) return;
      setState(() {
        _messages = messagesResp.messages;
        _isLoading = false;
      });
      _scrollToBottom();
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
    if (text.isEmpty) return;

    final gigId = widget.gigId;
    final isRealBackendGig = gigId != null && !gigId.startsWith('job-');
    final currentUser = TokenStorage.instance.currentUser;
    final currentUserId = currentUser?.id ?? 'me';
    final currentUserName = currentUser?.fullName ?? 'You';
    final currentUserRole = currentUser?.role ?? 'worker';

    // Clear text field immediately for a fluid user experience
    _controller.clear();

    // Optimistically add message to screen right away
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = MessageDto(
      id: tempId,
      conversationId: gigId ?? 'demo',
      senderId: currentUserId,
      senderName: currentUserName,
      senderRole: currentUserRole,
      messageText: text,
      isRead: true,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(optimisticMsg);
    });
    _scrollToBottom();

    if (!isRealBackendGig) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        final replyMsg = MessageDto(
          id: 'reply-${DateTime.now().millisecondsSinceEpoch}',
          conversationId: gigId ?? 'demo',
          senderId: 'counterparty-id',
          senderName: widget.title,
          senderRole: currentUserRole == 'worker' ? 'customer' : 'worker',
          messageText: 'Got it, thank you for the update!',
          isRead: true,
          createdAt: DateTime.now(),
        );
        setState(() {
          _messages.add(replyMsg);
        });
        _scrollToBottom();
      });
      return;
    }

    // Deliver to server in background without blocking UI
    try {
      final realMsg = await _chatRepo.sendMessage(gigId, text);
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = realMsg;
        }
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to deliver message: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMe = msg.senderId == currentUserId ||
                                  (currentUserId == null &&
                                      msg.senderId != 'counterparty-id');

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
                  IconButton(
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
