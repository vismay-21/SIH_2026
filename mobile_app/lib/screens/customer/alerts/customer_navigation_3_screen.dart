import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/api/api_models.dart';
import '../../../models/customer_gig_workflow.dart';
import '../../../providers/customer_gigs_provider.dart';
import '../../../providers/customer_notifications_provider.dart';
import '../../../repositories/gig_repository.dart';
import '../../../theme/app_theme.dart';
import '../my_jobs/gig_details_screen.dart';

class CustomerNavigation3Screen extends ConsumerStatefulWidget {
  const CustomerNavigation3Screen({super.key});

  @override
  ConsumerState<CustomerNavigation3Screen> createState() =>
      _CustomerNavigation3ScreenState();
}

class _CustomerNavigation3ScreenState
    extends ConsumerState<CustomerNavigation3Screen> {
  final _gigRepo = GigRepository();
  bool _isNavigating = false;

  Future<void> _handleRefresh() async {
    await Future.wait([
      ref.read(customerNotificationsProvider.notifier).loadNotifications(),
      ref.read(customerGigsProvider.notifier).loadGigs(silent: true),
    ]);
  }

  Future<void> _openGigForNotification(NotificationDto notif) async {
    if (_isNavigating) return;
    _isNavigating = true;

    // Mark as read
    ref.read(customerNotificationsProvider.notifier).markAsRead(notif.id);

    final gigId = notif.gigId;
    if (gigId == null) {
      _isNavigating = false;
      return;
    }

    try {
      // Look in active cache first
      final gigs = ref.read(customerGigsProvider).allGigs;
      var gig = gigs.where((g) => g.id == gigId).firstOrNull;

      if (gig == null) {
        // Fetch on demand
        final dto = await _gigRepo.getGig(gigId);
        List<GigCandidateDto> candDtos = [];
        try {
          candDtos = await _gigRepo.getCandidates(gigId);
        } catch (_) {}
        final candidates = candDtos
            .map((c) => GigCandidate.fromDto(c, categoryName: dto.categoryName))
            .toList();
        gig = CustomerGig.fromDto(dto, candidates: candidates);
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GigDetailsScreen(gig: gig!),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open gig details: $e')),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Recent';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final notifsState = ref.watch(customerNotificationsProvider);
    final gigsState = ref.watch(customerGigsProvider);
    final gigs = gigsState.allGigs;
    final notifications = notifsState.notifications;
    final unreadCount = notifsState.unreadCount;

    // Extract live candidate alerts directly from live customer gigs
    final candidateAlerts = <_CandidateAlertItem>[];
    for (final gig in gigs) {
      if (gig.candidates.isNotEmpty && gig.selectedWorker == null) {
        for (final candidate in gig.candidates) {
          candidateAlerts.add(
            _CandidateAlertItem(
              gig: gig,
              candidate: candidate,
            ),
          );
        }
      }
    }

    final hasContent = notifications.isNotEmpty || candidateAlerts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Alerts',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => ref
                  .read(customerNotificationsProvider.notifier)
                  .markAllAsRead(),
              child: const Text('Mark all read'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Live Worker Acceptance Highlights (Top Priority Action Cards)
            if (candidateAlerts.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.campaign_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'NEW WORKER RESPONSES (${candidateAlerts.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...candidateAlerts.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _WorkerAcceptedCard(
                    item: item,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GigDetailsScreen(gig: item.gig),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
            ],

            // In-App Notification Feed from Backend
            if (notifications.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'NOTIFICATIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.muted,
                  ),
                ),
              ),
              ...notifications.map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _NotificationCard(
                    notification: n,
                    timeText: _formatTime(n.createdAt),
                    onTap: () => _openGigForNotification(n),
                  ),
                ),
              ),
            ],

            // Empty State
            if (!hasContent && !notifsState.isLoading && !gigsState.isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 80.0),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 54,
                        color: AppColors.muted,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'No alerts yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 6),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          'When a worker accepts your gig, you will receive an instant alert here with their profile and wage offer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Loading indicator if empty
            if (!hasContent && (notifsState.isLoading || gigsState.isLoading))
              const Padding(
                padding: EdgeInsets.only(top: 80.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _CandidateAlertItem {
  final CustomerGig gig;
  final GigCandidate candidate;

  const _CandidateAlertItem({
    required this.gig,
    required this.candidate,
  });
}

class _WorkerAcceptedCard extends StatelessWidget {
  const _WorkerAcceptedCard({
    required this.item,
    required this.onTap,
  });

  final _CandidateAlertItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final candidate = item.candidate;
    final gig = item.gig;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  candidate.initials.isNotEmpty ? candidate.initials : 'W',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${candidate.name} accepted your gig',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ACCEPTED',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${candidate.name} (${candidate.skill}, ⭐ ${candidate.rating}) accepted "${gig.title}". Wage offer: ${candidate.wage}.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Tap to review profile & confirm',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.timeText,
    required this.onTap,
  });

  final NotificationDto notification;
  final String timeText;
  final VoidCallback onTap;

  IconData _iconForType(String type) {
    return switch (type) {
      'WORKER_ACCEPTED' => Icons.person_pin_rounded,
      'WORKER_SELECTED' => Icons.check_circle_outline_rounded,
      'GIG_STARTED' => Icons.play_circle_outline_rounded,
      'COMPLETION_SUBMITTED' => Icons.assignment_turned_in_outlined,
      'PAYMENT_CONFIRMED' => Icons.payment_rounded,
      'REVIEW_AVAILABLE' => Icons.star_rate_rounded,
      'GIG_CANCELLED' => Icons.cancel_outlined,
      _ => Icons.notifications_active_outlined,
    };
  }

  Color _colorForType(String type) {
    return switch (type) {
      'WORKER_ACCEPTED' => AppColors.primary,
      'WORKER_SELECTED' => Colors.teal,
      'GIG_STARTED' => Colors.blue,
      'COMPLETION_SUBMITTED' => Colors.orange,
      'PAYMENT_CONFIRMED' => Colors.green,
      'REVIEW_AVAILABLE' => Colors.amber,
      'GIG_CANCELLED' => Colors.red,
      _ => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final color = _colorForType(notification.type);

    return Card(
      elevation: unread ? 1.5 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: unread
              ? color.withValues(alpha: 0.35)
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(_iconForType(notification.type), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: unread ? null : AppColors.muted,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
