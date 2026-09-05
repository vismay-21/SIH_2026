import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class CustomerNavigation3Screen extends StatelessWidget {
  const CustomerNavigation3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Notifications',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          const _Notice(
            icon: Icons.people_alt_outlined,
            title: 'New worker accepted',
            body: 'Two workers accepted Kitchen sink leak repair.',
            time: '12 min ago',
          ),
          const SizedBox(height: 10),
          const _Notice(
            icon: Icons.check_circle_outline_rounded,
            title: 'Review available',
            body: 'Your last gig is complete. Share feedback with the worker.',
            time: 'Yesterday',
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
  });
  final IconData icon;
  final String title, body, time;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        foregroundColor: AppColors.primary,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(body),
      trailing: Text(
        time,
        style: const TextStyle(fontSize: 11, color: AppColors.muted),
      ),
    ),
  );
}
