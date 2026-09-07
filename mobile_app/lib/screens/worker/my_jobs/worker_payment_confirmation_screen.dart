import 'package:flutter/material.dart';

import '../../../models/worker_job_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import 'review_customer_screen.dart';

class WorkerPaymentConfirmationScreen extends StatefulWidget {
  const WorkerPaymentConfirmationScreen({super.key, required this.job});

  final WorkerJob job;

  @override
  State<WorkerPaymentConfirmationScreen> createState() =>
      _WorkerPaymentConfirmationScreenState();
}

class _WorkerPaymentConfirmationScreenState
    extends State<WorkerPaymentConfirmationScreen> {
  String _paymentMethod = 'UPI Direct';
  bool _confirmedReceipt = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Confirmation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // Header Card
          SurfaceCard(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Payment Released by Customer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.job.title,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Payout Breakdown (SRS 19.1)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Earnings Breakdown',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Base Labor Wage',
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      widget.job.wage,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cooperative Platform Fee',
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      '₹0 (Zero Deduction)',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Payout',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.job.wage,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const SectionTitle('Confirm Payment Channel'),
          const SizedBox(height: 8),

          InkWell(
            onTap: () => setState(() => _paymentMethod = 'UPI Direct'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _paymentMethod == 'UPI Direct'
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surface,
                border: Border.all(
                  color: _paymentMethod == 'UPI Direct'
                      ? AppColors.primary
                      : AppColors.border,
                  width: _paymentMethod == 'UPI Direct' ? 1.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _paymentMethod == 'UPI Direct'
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: _paymentMethod == 'UPI Direct'
                        ? AppColors.primary
                        : AppColors.muted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UPI Direct Transfer (GPay / PhonePe / Paytm)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Money sent directly to your linked UPI VPA',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _paymentMethod = 'Cash in Hand'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _paymentMethod == 'Cash in Hand'
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surface,
                border: Border.all(
                  color: _paymentMethod == 'Cash in Hand'
                      ? AppColors.primary
                      : AppColors.border,
                  width: _paymentMethod == 'Cash in Hand' ? 1.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _paymentMethod == 'Cash in Hand'
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: _paymentMethod == 'Cash in Hand'
                        ? AppColors.primary
                        : AppColors.muted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash in Hand',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Physical currency paid by customer upon completion',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          CheckboxListTile(
            value: _confirmedReceipt,
            onChanged: (val) =>
                setState(() => _confirmedReceipt = val ?? false),
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            title: const Text(
              'I confirm receipt of full payment without any discrepancy.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _confirmedReceipt
                ? () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => ReviewCustomerScreen(job: widget.job),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.star_rounded),
            label: const Text(
              'Confirm & Rate Customer',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
