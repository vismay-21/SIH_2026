import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../../common/about_help_screen.dart';
import '../../common/settings_screen.dart';
import 'customer_account_screens.dart';

class CustomerNavigation4Screen extends StatelessWidget {
  const CustomerNavigation4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Your profile',
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
                    'B',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                  ),
                ),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bhagya Rao',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Customer · Bengaluru',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CustomerJobHistoryScreen(),
                    ),
                  ),
                  leading: Icon(Icons.history_rounded),
                  title: Text('Job history'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
                Divider(height: 1),
                ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const SettingsScreen(userRole: 'Customer'),
                    ),
                  ),
                  leading: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                const Divider(height: 1),
                ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AboutHelpScreen(),
                    ),
                  ),
                  leading: const Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Help and support'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => showCustomerSignOutDialog(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
