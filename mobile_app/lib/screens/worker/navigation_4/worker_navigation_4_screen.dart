import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class WorkerNavigation4Screen extends StatelessWidget {
  const WorkerNavigation4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Worker profile',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          const SurfaceCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Text(
                    'R',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ravi Kumar',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Plumber · 4 years experience',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                StatusPill('Verified'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.schedule_rounded),
                  title: Text('Availability'),
                  subtitle: Text('Mon–Sat · 9:00 AM to 6:00 PM'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.verified_user_outlined),
                  title: Text('Verification status'),
                  subtitle: Text('Identity and skill verified'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
