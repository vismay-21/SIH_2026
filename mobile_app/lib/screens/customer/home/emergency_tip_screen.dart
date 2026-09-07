import 'package:flutter/material.dart';

import '../../../models/customer_gig_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class EmergencyTipScreen extends StatefulWidget {
  const EmergencyTipScreen({super.key, this.gig});

  final CustomerGig? gig;

  @override
  State<EmergencyTipScreen> createState() => _EmergencyTipScreenState();
}

class _EmergencyTipScreenState extends State<EmergencyTipScreen> {
  int _selectedTipAmount = 100;
  final _presetTips = const [50, 100, 150, 200];
  final int _baseAlgorithmicWage = 550;

  void _reNotifyWorkers() {
    final totalWage = _baseAlgorithmicWage + _selectedTipAmount;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Re-notified 8 nearby workers with ₹$_selectedTipAmount incentive! Total payout: ₹$totalWage.',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final totalPayout = _baseAlgorithmicWage + _selectedTipAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Response')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.accent),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.primaryDark,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'No workers accepted yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Your emergency gig was broadcast within 5 km. You can add a voluntary worker tip to incentivize immediate acceptance.',
                  style: TextStyle(height: 1.35, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Select Additional Tip Incentive'),
          const SizedBox(height: 10),
          Row(
            children: _presetTips.map((tip) {
              final isSelected = _selectedTipAmount == tip;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('+$tip'),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedTipAmount = tip);
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Compensation Breakdown'),
          const SizedBox(height: 8),
          SurfaceCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Algorithmic Labour Wage',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    Text(
                      '₹$_baseAlgorithmicWage',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Customer Voluntary Tip',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    Text(
                      '+₹$_selectedTipAmount',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Worker Payout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '₹$totalPayout',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Direct Payout',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'The entire tip amount goes directly to the responding worker. The cooperative platform takes ₹0 commission.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryAction(
            label: 'Re-notify workers with ₹$_selectedTipAmount tip',
            icon: Icons.notifications_active_rounded,
            onPressed: _reNotifyWorkers,
          ),
        ],
      ),
    );
  }
}
