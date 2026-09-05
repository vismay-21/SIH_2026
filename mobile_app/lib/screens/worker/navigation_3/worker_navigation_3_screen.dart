import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class WorkerNavigation3Screen extends StatelessWidget {
  const WorkerNavigation3Screen({super.key});

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
          const SizedBox(height: 18),
          const SurfaceCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: Icon(Icons.handyman_outlined),
              ),
              title: Text(
                'Ceiling fan installation',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Selected · Tomorrow, 11:00 AM'),
              trailing: StatusPill('₹520'),
            ),
          ),
        ],
      ),
    );
  }
}
