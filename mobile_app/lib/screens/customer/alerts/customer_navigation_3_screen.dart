import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/customer_gig_workflow.dart';
import '../../../providers/customer_gigs_provider.dart';
import '../../../theme/app_theme.dart';
import '../my_jobs/gig_details_screen.dart';

class CustomerNavigation3Screen extends ConsumerWidget {
  const CustomerNavigation3Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gigsState = ref.watch(customerGigsProvider);
    final gigs = gigsState.allGigs;

    // Generate real notifications from live customer gigs
    final notices = <Widget>[];

    for (final gig in gigs) {
      if (gig.candidates.isNotEmpty && gig.selectedWorker == null) {
        notices.add(
          _Notice(
            icon: Icons.people_alt_outlined,
            title: 'Workers accepted your gig',
            body:
                '${gig.candidates.length} worker${gig.candidates.length == 1 ? '' : 's'} accepted "${gig.title}". Tap to review and choose.',
            time: 'Active now',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => GigDetailsScreen(gig: gig),
              ),
            ),
          ),
        );
      } else if (gig.stage == GigStage.active) {
        notices.add(
          _Notice(
            icon: Icons.play_circle_outline_rounded,
            title: 'Job In Progress',
            body: 'Work is currently in progress for "${gig.title}".',
            time: 'In progress',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => GigDetailsScreen(gig: gig),
              ),
            ),
          ),
        );
      } else if (gig.stage == GigStage.completed) {
        notices.add(
          _Notice(
            icon: Icons.check_circle_outline_rounded,
            title: 'Job Completed',
            body: 'Gig "${gig.title}" has been successfully completed.',
            time: gig.when,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => GigDetailsScreen(gig: gig),
              ),
            ),
          ),
        );
      }
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.read(customerGigsProvider.notifier).loadGigs(),
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
            if (gigsState.isLoading && gigs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (notices.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60.0),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 48,
                        color: AppColors.muted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'You will receive alerts here when workers accept your gigs or milestones occur.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...notices.map(
                (notice) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: notice,
                ),
              ),
          ],
        ),
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
