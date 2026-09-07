import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

/// SRS 22: Multi-Tier Worker Verification Status
/// Displays audit trails for Identity, Skill guild, Cooperative membership,
/// and police background clearance.
class WorkerVerificationScreen extends StatelessWidget {
  const WorkerVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verification Status',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          // Trust Badge Card
          SurfaceCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.success,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Tier-4 Verified',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Cooperative Member ID: #KA-BLR-0419',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const StatusPill('Certified'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const SectionTitle('Verification Tiers (SRS 22)'),
          const SizedBox(height: 10),

          // Tier 1
          _buildTierTile(
            tierNumber: 'Tier 1',
            title: 'Identity & National ID',
            description: 'Aadhaar biometric KYC authenticated.',
            verifiedDate: 'Verified · 14 Jan 2026',
            icon: Icons.badge_outlined,
            isVerified: true,
          ),
          const SizedBox(height: 10),

          // Tier 2
          _buildTierTile(
            tierNumber: 'Tier 2',
            title: 'Trade Guild & Skill Assessment',
            description:
                'Practical plumbing guild field test passed with Grade A.',
            verifiedDate: 'Verified · 22 Jan 2026',
            icon: Icons.handyman_outlined,
            isVerified: true,
          ),
          const SizedBox(height: 10),

          // Tier 3
          _buildTierTile(
            tierNumber: 'Tier 3',
            title: 'Cooperative Society Membership',
            description:
                'Bengaluru Urban Cooperative Artisans Society (Active shareholder).',
            verifiedDate: 'Active · Share certificate #0932',
            icon: Icons.diversity_3_outlined,
            isVerified: true,
          ),
          const SizedBox(height: 10),

          // Tier 4
          _buildTierTile(
            tierNumber: 'Tier 4',
            title: 'Police Antecedent Verification',
            description:
                'Local jurisdictional station certificate submitted & clear.',
            verifiedDate: 'Valid through 2027',
            icon: Icons.shield_outlined,
            isVerified: true,
          ),

          const SizedBox(height: 24),

          // Cooperative Security Pledge
          SurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Multi-tier verification builds peer trust between customers and workers, ensuring fair wages and safe workplace conditions.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierTile({
    required String tierNumber,
    required String title,
    required String description,
    required String verifiedDate,
    required IconData icon,
    required bool isVerified,
  }) {
    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$tierNumber · $verifiedDate',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
