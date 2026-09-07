import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../../common/about_help_screen.dart';
import '../../common/settings_screen.dart';
import '../../common/splash_screen.dart';
import '../my_jobs/rookie_progression_screen.dart';
import 'worker_availability_screen.dart';
import 'worker_earnings_screen.dart';
import 'worker_verification_screen.dart';

class WorkerNavigation4Screen extends StatelessWidget {
  const WorkerNavigation4Screen({super.key});

  void _showSignOutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text(
          'Are you sure you want to sign out of your cooperative worker account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const SplashScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  void _showTariffDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Cooperative Tariffs'),
          ],
        ),
        content: const Text(
          'All wages are fixed democratically by the cooperative artisan guild.\n\n'
          '• Standard Plumbing: ₹250/hr base + difficulty tier\n'
          '• Emergency Surcharge: +₹150 guaranteed floor\n'
          '• Platform Commission: 0% deduction\n'
          '• Worker Bidding: Prohibited per SRS anti-exploitation guidelines.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

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

          // Profile Summary Card
          SurfaceCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Text(
                    'R',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
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
                      SizedBox(height: 2),
                      Text(
                        '4.8 ★ · 128 Gigs completed',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const StatusPill('Verified'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action List
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Weekly Availability'),
                  subtitle: const Text('Mon–Sat · 9:00 AM to 6:00 PM'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WorkerAvailabilityScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Verification Status'),
                  subtitle: const Text(
                    'Tier 4 Verified · Police & Skill cleared',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WorkerVerificationScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.school_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Rookie Progression'),
                  subtitle: const Text('Apprentice Track · 3.0 credits'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RookieProgressionScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Earnings & Dividends'),
                  subtitle: const Text(
                    'Payout history · 0% commission breakdown',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WorkerEarningsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Settings'),
                  subtitle: const Text('Theme, language & alert chimes'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const SettingsScreen(userRole: 'Worker'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('About & Help Support'),
                  subtitle: const Text(
                    'Society charter, guild FAQs & helpline',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AboutHelpScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.gavel_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Cooperative Tariff Guidelines'),
                  subtitle: const Text('Fair wages & anti-bidding rules'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showTariffDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.danger,
                  ),
                  title: const Text(
                    'Sign out',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _showSignOutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
