import 'package:flutter/material.dart';

import '../../models/gig_draft.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/shared_widgets.dart';
import 'customer_main_screen.dart';

class LabourPricePreviewScreen extends StatelessWidget {
  const LabourPricePreviewScreen({super.key, required this.draft});

  final GigDraft draft;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review before posting')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepHeader(step: '3 of 3', title: 'Your labour price range'),
            const SizedBox(height: 10),
            const Text(
              'This is the cooperative estimate for the service work. Materials are separate.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            SurfaceCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Indicative labour range',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    '₹550 – ₹800',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    draft.isEmergency
                        ? 'Emergency jobs are prioritized for faster matching.'
                        : 'Workers will see the exact labour amount for this work after accepting.',
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('Gig summary'),
            const SizedBox(height: 8),
            SurfaceCard(
              child: Column(
                children: [
                  _SummaryRow(label: 'Category', value: draft.category),
                  _SummaryRow(label: 'Location', value: draft.location),
                  _SummaryRow(label: 'Duration', value: draft.duration),
                  _SummaryRow(
                    label: 'Materials',
                    value: draft.customerBuysMaterials
                        ? 'Customer purchases'
                        : 'Worker purchases',
                  ),
                  _SummaryRow(
                    label: 'Priority',
                    value: draft.isEmergency ? 'Emergency' : 'Standard',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: PrimaryAction(
                label: 'Post gig',
                icon: Icons.publish_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gig posted. Workers can now respond.'),
                    ),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const CustomerMainScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'You can review worker responses from My jobs.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.title});

  final String step;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        step,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
