import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

/// Worker Earnings & Cooperative Dividends Screen
/// Displays daily/weekly/monthly earnings breakdown, zero-commission audit,
/// guild patronage dividend credits, and payout transaction history.
class WorkerEarningsScreen extends StatefulWidget {
  const WorkerEarningsScreen({super.key});

  @override
  State<WorkerEarningsScreen> createState() => _WorkerEarningsScreenState();
}

class _WorkerEarningsScreenState extends State<WorkerEarningsScreen> {
  String _selectedPeriod = 'This Month';

  final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'Kitchen sink leak repair',
      'amount': '₹680',
      'date': 'Today · 6:30 PM',
      'method': 'UPI Direct · UTR #2893849102',
      'category': 'Plumbing',
    },
    {
      'title': 'Emergency bathroom clog clearing',
      'amount': '₹760',
      'date': 'Yesterday · 8:15 PM',
      'method': 'UPI Direct · UTR #2891920194',
      'category': 'Plumbing',
    },
    {
      'title': 'Ceiling fan installation & wiring',
      'amount': '₹520',
      'date': '4 Sep 2026',
      'method': 'Cash in Hand',
      'category': 'Electrical',
    },
    {
      'title': 'Quarterly Patronage Society Dividend',
      'amount': '₹1,240',
      'date': '1 Sep 2026',
      'method': 'Cooperative Guild Direct Credit',
      'category': 'Dividend',
      'isDividend': true,
    },
    {
      'title': 'Overhead water tank pipe repair',
      'amount': '₹850',
      'date': '29 Aug 2026',
      'method': 'UPI Direct · UTR #2874910291',
      'category': 'Plumbing',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Earnings & Dividends',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          // Period Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Today', 'This Week', 'This Month', 'All Time'].map((
                p,
              ) {
                final isSelected = _selectedPeriod == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(p),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.text,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedPeriod = p);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Total Earnings Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Payout ($_selectedPeriod)',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '0% Deductions',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '₹18,450',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '100% of labour wages disbursed directly to your linked UPI VPA.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cooperative Society Surplus Share (Unique Value Proposition)
          SurfaceCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    color: AppColors.primaryDark,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Patronage Dividend: ₹1,240',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Quarterly profit share credited from Bangalore Artisans Guild Society.',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const StatusPill('Credited'),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const SectionTitle('Earnings Distribution'),
          const SizedBox(height: 8),

          // Distribution breakdown
          SurfaceCard(
            child: Column(
              children: [
                _buildBreakdownRow(
                  label: 'Direct Labor Wages',
                  amount: '₹16,800',
                  percent: '91%',
                  color: AppColors.primary,
                ),
                const Divider(height: 16),
                _buildBreakdownRow(
                  label: 'Emergency Surcharges & Tips',
                  amount: '₹1,650',
                  percent: '9%',
                  color: AppColors.accent,
                ),
                const Divider(height: 16),
                _buildBreakdownRow(
                  label: 'Aggregator Platform Cuts',
                  amount: '₹0 (Saved ~₹4,500)',
                  percent: '0%',
                  color: AppColors.success,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const SectionTitle('Recent Payout Transactions'),
          const SizedBox(height: 8),

          ..._transactions.map((tx) {
            final isDiv = tx['isDividend'] == true;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDiv
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDiv
                        ? Icons.military_tech_rounded
                        : Icons.payments_rounded,
                    color: isDiv ? AppColors.primaryDark : AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  tx['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${tx['date']} · ${tx['method']}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                trailing: Text(
                  tx['amount'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isDiv ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String label,
    required String amount,
    required String percent,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(width: 8),
        Text(
          '($percent)',
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}
