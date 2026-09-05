import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

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
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create a gig'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.warning_amber_rounded, size: 18),
                      label: const Text('Emergency'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                      ),
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
          const _GigCard(
            title: 'Kitchen sink leak repair',
            category: 'Plumbing repair',
            description:
                'Water is leaking below the sink and needs same-day repair.',
            when: 'Today · 5:00 PM',
            location: 'Indiranagar, Bengaluru',
            duration: 'Around 2 hours',
            status: 'Accepted candidates',
          ),
          const SizedBox(height: 12),
          const _GigCard(
            title: 'Emergency bathroom clog',
            category: 'Emergency plumbing',
            description: 'Urgent clog issue, needs faster nearby matching.',
            when: 'Today · Immediate',
            location: 'Ulsoor, Bengaluru',
            duration: '60–90 minutes',
            status: 'Emergency',
            warning: true,
          ),
          const SizedBox(height: 22),
          const SectionTitle('Previously used workers'),
          const SizedBox(height: 4),
          const _PreviousWorker(
            name: 'Amit Sharma',
            skill: 'Plumber',
            initials: 'AS',
          ),
          const SizedBox(height: 10),
          const _PreviousWorker(
            name: 'Rekha Patel',
            skill: 'Electrician',
            initials: 'RP',
          ),
        ],
      ),
    );
  }
}

class _GigCard extends StatelessWidget {
  const _GigCard({
    required this.title,
    required this.category,
    required this.description,
    required this.when,
    required this.location,
    required this.duration,
    required this.status,
    this.warning = false,
  });
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
            StatusPill(status, warning: warning),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(color: AppColors.muted, height: 1.35),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 8,
          runSpacing: 7,
          children: [
            _MetaChip(icon: Icons.calendar_today_outlined, text: when),
            _MetaChip(icon: Icons.location_on_outlined, text: location),
            _MetaChip(icon: Icons.schedule_outlined, text: duration),
          ],
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: null,
              icon: Icon(Icons.timeline_rounded, size: 16),
              label: Text('View lifecycle'),
            ),
            SizedBox(width: 8),
            FilledButton.icon(
              onPressed: null,
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: Text('Job chat'),
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
  });
  final String name, skill, initials;

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
            ],
          ),
        ),
        OutlinedButton(onPressed: null, child: const Text('Request')),
      ],
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
