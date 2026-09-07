import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class WorkerNavigation2Screen extends StatelessWidget {
  const WorkerNavigation2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Opportunities',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Exact wages are shown before you decide.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          const SurfaceCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.plumbing_rounded, color: AppColors.primary),
              title: Text(
                'Kitchen sink leak repair',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Today, 5:00 PM · 3.2 km'),
              trailing: Text(
                '₹680',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
