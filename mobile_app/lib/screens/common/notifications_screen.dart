import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

/// Common Notifications List Screen (Common Screen #7)
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'New opportunity matches your guild',
        'subtitle':
            'Kitchen sink leak repair in Indiranagar (₹680 net payout).',
        'time': '10 min ago',
        'unread': true,
        'icon': Icons.explore_outlined,
      },
      {
        'title': 'Cooperative dividend credited',
        'subtitle':
            'Quarterly patronage bonus of ₹420 added to cooperative balance.',
        'time': '2 hours ago',
        'unread': true,
        'icon': Icons.savings_outlined,
      },
      {
        'title': 'Mentor feedback received',
        'subtitle': 'Master Plumber Amit Sharma approved +0.5 rookie credits.',
        'time': 'Yesterday',
        'unread': false,
        'icon': Icons.school_outlined,
      },
      {
        'title': 'Verification renewal reminder',
        'subtitle':
            'Your police antecedent clearance is valid for 11 more months.',
        'time': '3 days ago',
        'unread': false,
        'icon': Icons.verified_user_outlined,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = notifications[index];
          final unread = item['unread'] as bool;

          return SurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: unread
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.border.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: unread ? AppColors.primary : AppColors.muted,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title'] as String,
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
                        item['subtitle'] as String,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['time'] as String,
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
          );
        },
      ),
    );
  }
}
