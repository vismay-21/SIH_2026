import 'package:flutter/material.dart';

import '../../models/api/api_models.dart';
import '../../models/api/api_response.dart';
import '../../repositories/notification_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

/// Common Notifications List Screen (Common Screen #7) connected to NotificationRepository.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notifRepo = NotificationRepository();

  List<NotificationDto> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _notifRepo.getNotifications(limit: 50);
      if (!mounted) return;
      setState(() {
        _notifications = list.items;
        _unreadCount = list.unreadCount;
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

  Future<void> _markAsRead(NotificationDto item) async {
    if (item.isRead) return;
    try {
      await _notifRepo.markAsRead(item.id);
      if (!mounted) return;
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == item.id);
        if (index != -1) {
          _notifications[index] = NotificationDto(
            id: item.id,
            recipientId: item.recipientId,
            gigId: item.gigId,
            type: item.type,
            title: item.title,
            body: item.body,
            actionUrl: item.actionUrl,
            isRead: true,
            createdAt: item.createdAt,
            readAt: DateTime.now(),
          );
          if (_unreadCount > 0) _unreadCount--;
        }
      });
    } catch (_) {
      // Ignore network error on read mark
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notifRepo.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _notifications = _notifications.map((n) {
          return NotificationDto(
            id: n.id,
            recipientId: n.recipientId,
            gigId: n.gigId,
            type: n.type,
            title: n.title,
            body: n.body,
            actionUrl: n.actionUrl,
            isRead: true,
            createdAt: n.createdAt,
            readAt: DateTime.now(),
          );
        }).toList();
        _unreadCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark all read: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _unreadCount > 0
              ? 'Notifications ($_unreadCount unread)'
              : 'Notifications',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            size: 40, color: AppColors.muted),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadNotifications,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _notifications.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Text(
                              'No notifications yet.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final unread = !item.isRead;

                          return InkWell(
                            onTap: () => _markAsRead(item),
                            borderRadius: BorderRadius.circular(12),
                            child: SurfaceCard(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: unread
                                          ? AppColors.primary
                                              .withValues(alpha: 0.12)
                                          : AppColors.border
                                              .withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.notifications_outlined,
                                      color: unread
                                          ? AppColors.primary
                                          : AppColors.muted,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontWeight: unread
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            if (unread)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.body,
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${item.createdAt.day}/${item.createdAt.month} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
