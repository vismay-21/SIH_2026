import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api/api_models.dart';
import '../repositories/notification_repository.dart';
import '../services/token_storage.dart';

class CustomerNotificationsState {
  final List<NotificationDto> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;

  const CustomerNotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  CustomerNotificationsState copyWith({
    List<NotificationDto>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CustomerNotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class CustomerNotificationsNotifier
    extends Notifier<CustomerNotificationsState> {
  final NotificationRepository _notifRepo = NotificationRepository();
  Timer? _pollingTimer;

  @override
  CustomerNotificationsState build() {
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    // Initial load
    Future.microtask(() => loadNotifications());

    // Lightweight auto-polling every 8 seconds to catch worker acceptances
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      loadNotifications(silent: true);
    });

    return const CustomerNotificationsState(isLoading: true);
  }

  bool _isFetching = false;

  Future<void> loadNotifications({bool silent = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (!TokenStorage.instance.isAuthenticated) {
      if (!silent) {
        state = state.copyWith(isLoading: false);
      }
      _isFetching = false;
      return;
    }

    if (!silent) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final list = await _notifRepo.getNotifications(limit: 50);
      state = state.copyWith(
        notifications: list.items,
        unreadCount: list.unreadCount,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      if (!silent) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        );
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final index = state.notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || state.notifications[index].isRead) return;

    try {
      await _notifRepo.markAsRead(notificationId);
      final updatedList = List<NotificationDto>.from(state.notifications);
      final item = updatedList[index];
      updatedList[index] = NotificationDto(
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

      final newUnread = (state.unreadCount > 0) ? state.unreadCount - 1 : 0;
      state = state.copyWith(
        notifications: updatedList,
        unreadCount: newUnread,
      );
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _notifRepo.markAllAsRead();
      final updatedList = state.notifications.map((item) {
        return NotificationDto(
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
      }).toList();

      state = state.copyWith(
        notifications: updatedList,
        unreadCount: 0,
      );
    } catch (_) {}
  }
}

final customerNotificationsProvider = NotifierProvider<
    CustomerNotificationsNotifier, CustomerNotificationsState>(
  CustomerNotificationsNotifier.new,
);
