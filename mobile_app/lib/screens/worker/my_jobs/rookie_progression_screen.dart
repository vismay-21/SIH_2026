import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

/// SRS 15.2: Rookie Learning Progression & Co-Worker Credit Screen
/// Tracks apprentice / rookie milestone progress (0.5 credit per shadowed gig)
/// towards independent certified worker status.
class RookieProgressionScreen extends StatelessWidget {
  const RookieProgressionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const int completedGigs = 6;
    const int targetGigs = 10;
    const double progress = completedGigs / targetGigs;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rookie Progression',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          // Header Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apprentice Track: Level 1',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Plumbing & Sanitation Guild',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const StatusPill('Active'),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Credits: 3.0 / 5.0 (6 Mentored Gigs)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Complete 4 more shadowed gigs with certified cooperative mentors to graduate to Full Independent Worker status.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Policy Explanation Card (SRS 15.2)
          SurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'How Rookie Progression Works (SRS 15.2)',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Each shadowed job awards 0.5 verified cooperative job credits.\n'
                        '• Mentors review technical accuracy, tool safety, and punctuality.\n'
                        '• Zero customer commission deducted during learning phase.\n'
                        '• Instant certificate upon completing 10 supervised jobs.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const SectionTitle('Mentored Job History'),
          const SizedBox(height: 8),

          _buildHistoryTile(
            jobTitle: 'Commercial kitchen drainage overhaul',
            mentorName: 'Amit Sharma (Master Plumber)',
            date: 'Yesterday · 4 hrs',
            credits: '+0.5 Credits',
            feedback:
                'Excellent assistance with heavy cast pipe cutting and joint leveling.',
            rating: 5,
          ),
          const SizedBox(height: 12),
          _buildHistoryTile(
            jobTitle: 'Overhead PVC water tank pipeline',
            mentorName: 'Manoj Verma (Certified Plumber)',
            date: '4 Sep 2026 · 3 hrs',
            credits: '+0.5 Credits',
            feedback:
                'Very attentive to solvent cementing standards and leak checking.',
            rating: 5,
          ),
          const SizedBox(height: 12),
          _buildHistoryTile(
            jobTitle: 'Concealed valve fitting in bathroom',
            mentorName: 'Ravi Kumar (Lead Technician)',
            date: '28 Aug 2026 · 2.5 hrs',
            credits: '+0.5 Credits',
            feedback:
                'Good work ethic, remember to carry pipe-thread tape in primary kit.',
            rating: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile({
    required String jobTitle,
    required String mentorName,
    required String date,
    required String credits,
    required String feedback,
    required int rating,
  }) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  jobTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  credits,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            mentorName,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            date,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const Divider(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.format_quote_rounded,
                size: 16,
                color: AppColors.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  feedback,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
