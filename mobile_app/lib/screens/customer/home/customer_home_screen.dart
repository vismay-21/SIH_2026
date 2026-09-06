import 'package:flutter/material.dart';

import '../../../models/customer_gig_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../customer_account_screens.dart';
import '../customer_main_screen.dart';
import '../create_gig_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning,',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Bhagya',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {},
                icon: const Badge(
                  label: Text('2'),
                  child: Icon(Icons.notifications_none_rounded, size: 27),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fair matching for household work',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Workers see exact wages. You choose from accepted candidates.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CreateGigScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create a gig'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.warning_amber_rounded, size: 18),
                      label: const Text('Emergency'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              StatTile(
                icon: Icons.assignment_outlined,
                value: '2',
                label: 'Active gigs',
              ),
              SizedBox(width: 10),
              StatTile(
                icon: Icons.people_outline_rounded,
                value: '3',
                label: 'Accepted workers',
              ),
              SizedBox(width: 10),
              StatTile(
                icon: Icons.verified_user_outlined,
                value: '1',
                label: 'Cooperative area',
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionTitle('Active and upcoming', action: 'View all'),
          const SizedBox(height: 4),
          _GigCard(
            gig: demoGigs[0],
            title: 'Kitchen sink leak repair',
            category: 'Plumbing repair',
            description: 'Leak under sink. Same-day repair required.',
            when: 'Today · 5:00 PM',
            location: 'Indiranagar, Bengaluru',
            duration: '2 hrs',
            status: '3 workers interested',
          ),
          const SizedBox(height: 12),
          _GigCard(
            gig: demoGigs[1],
            title: 'Emergency bathroom clog',
            category: 'Emergency plumbing',
            description: 'Urgent clog. Nearby worker matching enabled.',
            when: 'Today · Immediate',
            location: 'Ulsoor, Bengaluru',
            duration: '60–90 min',
            status: 'Emergency · Immediate',
            warning: true,
          ),
          const SizedBox(height: 22),
          const SectionTitle('Previously used workers'),
          const SizedBox(height: 4),
          const _PreviousWorker(
            name: 'Amit Sharma',
            skill: 'Plumber',
            initials: 'AS',
            rating: '4.8',
            completedJobs: '23 jobs',
          ),
          const SizedBox(height: 10),
          const _PreviousWorker(
            name: 'Rekha Patel',
            skill: 'Electrician',
            initials: 'RP',
            rating: '4.9',
            completedJobs: '18 jobs',
          ),
        ],
      ),
    );
  }
}

class _GigCard extends StatelessWidget {
  const _GigCard({
    required this.gig,
    required this.title,
    required this.category,
    required this.description,
    required this.when,
    required this.location,
    required this.duration,
    required this.status,
    this.warning = false,
  });
  final CustomerGig gig;
  final String title, category, description, when, location, duration, status;
  final bool warning;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    category,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            warning
                ? _EmergencyBadge(status)
                : StatusPill(status, warning: false),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(color: AppColors.muted, height: 1.35),
        ),
        const SizedBox(height: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetaChip(icon: Icons.calendar_today_outlined, text: when),
            const SizedBox(height: 7),
            _MetaChip(icon: Icons.location_on_outlined, text: location),
            const SizedBox(height: 7),
            _MetaChip(
              icon: Icons.schedule_outlined,
              text: 'Estimated · $duration',
            ),
          ],
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        CustomerMainScreen(initialIndex: 1, initialGig: gig),
                  ),
                ),
                icon: const Icon(Icons.timeline_rounded, size: 16),
                label: const Text('Track job'),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CustomerChatThreadScreen(
                    workerName: 'Amit Sharma',
                    jobTitle: 'Kitchen sink leak repair',
                  ),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('Chat'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PreviousWorker extends StatelessWidget {
  const _PreviousWorker({
    required this.name,
    required this.skill,
    required this.initials,
    required this.rating,
    required this.completedJobs,
  });
  final String name, skill, initials;
  final String rating, completedJobs;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: Text(
            initials,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                'Available now · $skill',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '★ $rating · $completedJobs',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Request sent to $name.'))),
          child: const Text('Request'),
        ),
      ],
    ),
  );
}

class _EmergencyBadge extends StatelessWidget {
  const _EmergencyBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.12),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.45)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.danger,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    ),
  );
}
