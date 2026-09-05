import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class CustomerNavigation2Screen extends StatelessWidget {
  const CustomerNavigation2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'My jobs',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Track every gig from request to payment.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              StatusPill('Active'),
              SizedBox(width: 8),
              StatusPill('Upcoming'),
              SizedBox(width: 8),
              StatusPill('Completed'),
            ],
          ),
          const SizedBox(height: 16),
          const SurfaceCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: Icon(Icons.water_damage_outlined),
              ),
              title: Text(
                'Kitchen sink leak repair',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Accepted candidates · Today, 5:00 PM'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
