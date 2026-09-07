import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';

/// Common About & Help/Support Screen (Common Screen #11)
class AboutHelpScreen extends StatelessWidget {
  const AboutHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About & Help Support',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          // Brand Header
          SurfaceCard(
            child: Column(
              children: [
                const BrandMark(),
                const SizedBox(height: 12),
                const Text(
                  'Sahakaar Seva Cooperative',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Artisan-Owned Household Services Platform',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Version 1.0.0 · SIH 2026',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Cooperative Society Charter
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Cooperative Society Charter',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                SizedBox(height: 8),
                Text(
                  'Sahakaar Seva is built on democratic cooperative principles. Unlike corporate aggregator apps that take 25%–35% cuts from unorganized workers, our platform charges 0% commission on worker labor and distributes surplus dividends back to cooperative guild members.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.text,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const SectionTitle('Frequently Asked Questions (FAQ)'),
          const SizedBox(height: 8),

          _buildFaqTile(
            question: 'How are gig tariffs calculated?',
            answer:
                'Wages are predetermined democratically by the artisan trade guilds based on job scope, skill difficulty tier, and duration. Predatory worker bidding and undercutting are strictly prohibited.',
          ),
          const SizedBox(height: 8),
          _buildFaqTile(
            question: 'What is the Rookie Mentorship Track (SRS 15.2)?',
            answer:
                'New apprentices earn 0.5 verified cooperative job credits by shadowing experienced master technicians on complex jobs, gaining practical skills with zero customer commission deductions.',
          ),
          const SizedBox(height: 8),
          _buildFaqTile(
            question: 'How does Emergency Tipping work (SRS 18.1)?',
            answer:
                'If no nearby worker accepts an emergency post, the customer can voluntarily add an incentive tip. 100% of the tip amount goes directly to the responding technician.',
          ),
          const SizedBox(height: 8),
          _buildFaqTile(
            question: 'What happens if a job needs to be rescheduled?',
            answer:
                'Either customer or worker can propose a new date/time slot with clear reason selection. If the new slot is not workable, the job is re-dispatched safely through the cooperative algorithm without penalties.',
          ),

          const SizedBox(height: 20),
          const SectionTitle('Cooperative Support Helpline'),
          const SizedBox(height: 8),

          SurfaceCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.phone_in_talk_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Toll-Free Helpline',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    '1800-425-7382 · Mon–Sat (8 AM to 8 PM)',
                  ),
                  trailing: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Calling Toll-Free Support...'),
                        ),
                      );
                    },
                    child: const Text('Call'),
                  ),
                ),
                const Divider(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  title: const Text(
                    'WhatsApp Helpdesk',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    '+91 94480 12345 · Instant support assistant',
                  ),
                  trailing: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening WhatsApp Helpdesk...'),
                        ),
                      );
                    },
                    child: const Text('Chat'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile({required String question, required String answer}) {
    return Card(
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
