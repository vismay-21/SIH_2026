import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/customer_gig_workflow.dart';
import '../../../providers/customer_gigs_provider.dart';
import '../../../providers/worker_jobs_provider.dart';
import '../../../repositories/gig_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class CancelGigScreen extends ConsumerStatefulWidget {
  const CancelGigScreen({super.key, required this.gig});

  final CustomerGig gig;

  @override
  ConsumerState<CancelGigScreen> createState() => _CancelGigScreenState();
}

class _CancelGigScreenState extends ConsumerState<CancelGigScreen> {
  final _gigRepo = GigRepository();
  int _selectedReasonIndex = 0;
  bool _isSubmitting = false;

  final _reasons = const [
    'My plans changed',
    'Issue resolved independently',
    'Selected time no longer suitable',
    'Worker unavailable at desired time',
    'Other reason',
  ];

  void _confirmCancellation() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Gig?'),
        content: Text(
          'Are you sure you want to cancel "${widget.gig.title}"? Nearby workers will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep Gig'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final gigId = widget.gig.id;
              if (gigId == null || gigId.isEmpty) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot cancel gig: Missing ID.')),
                );
                return;
              }

              Navigator.of(dialogContext).pop();
              setState(() => _isSubmitting = true);

              try {
                await _gigRepo.cancelGig(
                  gigId: gigId,
                  reason: _reasons[_selectedReasonIndex],
                );

                // Invalidate/refresh riverpod providers for both customer and worker
                ref.read(customerGigsProvider.notifier).loadGigs(silent: true);
                ref.read(workerJobsProvider.notifier).loadJobs(silent: true);
                ref.read(workerOpportunitiesProvider.notifier).loadOpportunities(silent: true);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gig "${widget.gig.title}" cancelled successfully.')),
                );
                Navigator.of(context).pop(true);
              } catch (e) {
                if (!mounted) return;
                setState(() => _isSubmitting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel gig: ${e.toString()}'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cancel Gig')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.gig.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.gig.category} · ${widget.gig.when}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Select Reason for Cancellation'),
          const SizedBox(height: 8),
          ...List.generate(_reasons.length, (index) {
            final isSelected = _selectedReasonIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: _isSubmitting
                    ? null
                    : () => setState(() => _selectedReasonIndex = index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.danger.withValues(alpha: 0.08)
                        : AppColors.surface,
                    border: Border.all(
                      color: isSelected ? AppColors.danger : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected ? AppColors.danger : AppColors.muted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _reasons[index],
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? AppColors.danger : AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 18),
          SurfaceCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.muted),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cooperative Policy',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Cancellations before worker confirmation incur ₹0 fee. After worker selection, a ₹50 cancellation fee applies.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: _isSubmitting ? null : _confirmCancellation,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text(_isSubmitting ? 'Cancelling...' : 'Cancel this gig'),
            ),
          ),
        ],
      ),
    );
  }
}
