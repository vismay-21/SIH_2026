import 'package:flutter/material.dart';

import '../../../models/customer_gig_workflow.dart';
import '../../../theme/app_theme.dart';
import '../my_jobs/gig_details_screen.dart';
import '../my_jobs/review_worker_screen.dart';

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
          _Notice(
            icon: Icons.people_alt_outlined,
            title: 'New worker accepted',
            body: 'Two workers accepted Kitchen sink leak repair.',
            time: '12 min ago',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => GigDetailsScreen(gig: demoGigs[0]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Notice(
            icon: Icons.check_circle_outline_rounded,
            title: 'Review available',
            body: 'Your last gig is complete. Share feedback with the worker.',
            time: 'Yesterday',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ReviewWorkerScreen(
                  workerName: 'Amit Sharma',
                  gigTitle: 'Living room deep clean',
                ),
              ),
            ),
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
    required this.onTap,
  });
  final IconData icon;
  final String title, body, time;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
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
