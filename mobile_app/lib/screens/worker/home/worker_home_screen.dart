import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

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
                    'Your work, your choice',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Namaste, Ravi',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {},
                icon: const Badge(
                  label: Text('3'),
                  child: Icon(Icons.notifications_none_rounded, size: 27),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are available',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'New eligible opportunities can reach you.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Switch(value: true, onChanged: null),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              StatTile(
                icon: Icons.explore_outlined,
                value: '4',
                label: 'New opportunities',
              ),
              SizedBox(width: 10),
              StatTile(
                icon: Icons.work_outline_rounded,
                value: '1',
                label: 'Current job',
              ),
              SizedBox(width: 10),
              StatTile(
                icon: Icons.star_outline_rounded,
                value: '4.8',
                label: 'Quality score',
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionTitle('New opportunities', action: 'See all'),
          const SizedBox(height: 4),
          const _OpportunityCard(
            title: 'Kitchen sink leak repair',
            category: 'Plumbing repair',
            wage: '₹680',
            when: 'Today · 5:00 PM',
            distance: '3.2 km away',
            urgent: false,
          ),
          const SizedBox(height: 12),
          const _OpportunityCard(
            title: 'Emergency bathroom clog',
            category: 'Emergency plumbing',
            wage: '₹760',
            when: 'Immediate',
            distance: '2.1 km away',
            urgent: true,
          ),
          const SizedBox(height: 22),
          const SectionTitle('Upcoming job'),
          SurfaceCard(
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.handyman_outlined),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ceiling fan installation',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tomorrow · 11:00 AM · ₹520',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const StatusPill('Selected'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.title,
    required this.category,
    required this.wage,
    required this.when,
    required this.distance,
    required this.urgent,
  });
  final String title, category, wage, when, distance;
  final bool urgent;
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
            StatusPill(urgent ? 'Emergency' : 'Eligible', warning: urgent),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.payments_outlined,
              size: 17,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              wage,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              when,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: AppColors.muted,
            ),
            const SizedBox(width: 4),
            Text(
              distance,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const Spacer(),
            OutlinedButton(onPressed: null, child: const Text('Details')),
          ],
        ),
      ],
    ),
  );
}
