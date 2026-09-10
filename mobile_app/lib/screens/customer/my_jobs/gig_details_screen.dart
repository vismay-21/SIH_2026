import 'package:flutter/material.dart';

import '../../../models/customer_gig_workflow.dart';
import '../../../repositories/gig_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import 'accepted_candidates_screen.dart';
import 'active_job_screen.dart';
import 'cancel_gig_screen.dart';
import 'completion_evidence_review_screen.dart';
import 'material_bill_viewer_screen.dart';
import 'reschedule_gig_screen.dart';
import 'review_worker_screen.dart';
import 'waiting_for_candidates_screen.dart';

class GigDetailsScreen extends StatefulWidget {
  const GigDetailsScreen({super.key, required this.gig});

  final CustomerGig gig;

  @override
  State<GigDetailsScreen> createState() => _GigDetailsScreenState();
}

class _GigDetailsScreenState extends State<GigDetailsScreen> {
  final _gigRepo = GigRepository();
  late CustomerGig _gig;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _gig = widget.gig;
    _refreshGig();
  }

  Future<void> _refreshGig() async {
    final gigId = _gig.id;
    if (gigId == null) return;

    setState(() => _isRefreshing = true);
    try {
      final gigDto = await _gigRepo.getGig(gigId);
      List<GigCandidate> candidates = [];
      try {
        final candidateDtos = await _gigRepo.getCandidates(gigId);
        candidates = candidateDtos.map(GigCandidate.fromDto).toList();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _gig = CustomerGig.fromDto(gigDto, candidates: candidates);
        _isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
    }
  }

  int _currentStepIndex() {
    if (_gig.stage == GigStage.completed) return 4;
    if (_gig.stage == GigStage.payment) return 3;
    if (_gig.stage == GigStage.completionRequested) return 2;
    if (_gig.stage == GigStage.active) return 1;
    if (_gig.candidates.isNotEmpty ||
        _gig.stage == GigStage.accepted ||
        _gig.stage == GigStage.selected ||
        _gig.stage == GigStage.scheduled) {
      return 0;
    }
    return -1; // Still seeking without candidates
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _currentStepIndex();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gig Details'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isRefreshing ? null : _refreshGig,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showMoreMenu(context),
            tooltip: 'More options',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshGig,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            // Top Horizontal Stepper (Matching Worker Side UI)
            _buildStatusTracker(currentStep),
            const SizedBox(height: 14),

            // Main Gig Summary Card (Compact & Modern)
            _buildMainSummaryCard(),
            const SizedBox(height: 12),

            // Quick Actions Row (3 side-by-side cards)
            _buildQuickActionCards(context),
            const SizedBox(height: 12),

            // Dynamic Context Card (Candidates alert / Assigned Worker / Seeking status)
            _buildContextCard(context),
            const SizedBox(height: 12),

            // Location & Instructions Card
            _buildLocationCard(),
            const SizedBox(height: 18),

            // Primary Bottom Action
            _buildPrimaryBottomAction(context),
          ],
        ),
      ),
    );
  }

  /// Horizontal 4-step progress bar matching the worker screen
  Widget _buildStatusTracker(int currentStep) {
    final steps = ['Accepted', 'In Progress', 'Evidence', 'Payment'];

    return Row(
      children: List.generate(steps.length, (idx) {
        final isDone = currentStep >= 0 && idx < currentStep;
        final isCurrent = currentStep >= 0 && idx == currentStep;
        final isActive = isDone || isCurrent;

        return Expanded(
          child: Column(
            children: [
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                steps[idx],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                  color: isActive ? AppColors.primary : AppColors.muted,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Compact header card with title, status pill, category/when/duration, and price
  Widget _buildMainSummaryCard() {
    final hasPrice = _gig.price != null && _gig.price! > 0;
    final isVisitation = _gig.gigType == 'VISITATION';

    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _gig.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                _gig.stage.label,
                warning: _gig.isEmergency,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_gig.category} · ${_gig.when} · ${_gig.duration}',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isVisitation ? 'Site Visit Charge' : 'Cooperative Labour Price',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              Text(
                hasPrice
                    ? '₹${_gig.price!.toInt()}'
                    : (isVisitation ? '₹100' : '₹550 – ₹800'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3 compact icon cards side by side
  Widget _buildQuickActionCards(BuildContext context) {
    final hasCandidates = _gig.candidates.isNotEmpty;
    final hasSelectedWorker = _gig.selectedWorker != null;

    return Row(
      children: [
        // Card 1: Candidates / Workspace / Radar
        Expanded(
          child: _QuickCard(
            icon: hasSelectedWorker
                ? Icons.work_history_rounded
                : (hasCandidates
                    ? Icons.people_alt_rounded
                    : Icons.radar_rounded),
            label: hasSelectedWorker
                ? 'Workspace'
                : (hasCandidates
                    ? 'Candidates (${_gig.candidates.length})'
                    : 'Worker Radar'),
            isHighlighted: hasCandidates && !hasSelectedWorker,
            onTap: () {
              if (hasSelectedWorker) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ActiveJobScreen(gig: _gig),
                  ),
                );
              } else if (hasCandidates) {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute<void>(
                        builder: (_) => AcceptedCandidatesScreen(gig: _gig),
                      ),
                    )
                    .then((_) => _refreshGig());
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WaitingForCandidatesScreen(gig: _gig),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 8),

        // Card 2: Material Bill
        Expanded(
          child: _QuickCard(
            icon: Icons.receipt_long_rounded,
            label: 'Material Bill',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MaterialBillViewerScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Card 3: Reschedule
        Expanded(
          child: _QuickCard(
            icon: Icons.edit_calendar_rounded,
            label: 'Reschedule',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RescheduleGigScreen(gig: _gig),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Context-aware status card
  Widget _buildContextCard(BuildContext context) {
    final hasCandidates = _gig.candidates.isNotEmpty;
    final selectedWorker = _gig.selectedWorker;

    if (selectedWorker != null) {
      // Worker Assigned Card (Matches "Customer Contact" in worker app)
      return SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assigned Worker',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Text(
                    selectedWorker.initials,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedWorker.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${selectedWorker.skill} · ★ ${selectedWorker.rating}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${selectedWorker.name}...')),
                    );
                  },
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ActiveJobScreen(gig: _gig),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (hasCandidates) {
      // Workers Have Accepted Banner
      return InkWell(
        onTap: () => Navigator.of(context)
            .push(
              MaterialPageRoute<void>(
                builder: (_) => AcceptedCandidatesScreen(gig: _gig),
              ),
            )
            .then((_) => _refreshGig()),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_gig.candidates.length} worker${_gig.candidates.length > 1 ? 's' : ''} accepted!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap to view ratings & choose your worker',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      );
    }

    // Still seeking workers
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.radar_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Searching nearby workers',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Workers are being notified. Pull down to refresh.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact location & details card
  Widget _buildLocationCard() {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _gig.location,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (_gig.instructions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Instructions: ${_gig.instructions}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Materials: ${_gig.materials}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Single primary context-aware action button
  Widget _buildPrimaryBottomAction(BuildContext context) {
    if (_gig.candidates.isNotEmpty && _gig.selectedWorker == null) {
      return PrimaryAction(
        label: 'View ${_gig.candidates.length} Candidate${_gig.candidates.length > 1 ? 's' : ''} & Choose',
        icon: Icons.check_circle_outline_rounded,
        onPressed: () => Navigator.of(context)
            .push(
              MaterialPageRoute<void>(
                builder: (_) => AcceptedCandidatesScreen(gig: _gig),
              ),
            )
            .then((_) => _refreshGig()),
      );
    }

    if (_gig.stage == GigStage.completionRequested) {
      return PrimaryAction(
        label: 'Review Work Evidence',
        icon: Icons.fact_check_rounded,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CompletionEvidenceReviewScreen(gig: _gig),
          ),
        ),
      );
    }

    if (_gig.stage == GigStage.completed) {
      return PrimaryAction(
        label: 'Review Worker Feedback',
        icon: Icons.rate_review_outlined,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReviewWorkerScreen(
              workerName: _gig.selectedWorker?.name ?? 'Worker',
              gigTitle: _gig.title,
            ),
          ),
        ),
      );
    }

    if (_gig.stage == GigStage.active && _gig.selectedWorker != null) {
      return PrimaryAction(
        label: 'Open Active Job Workspace',
        icon: Icons.work_history_rounded,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ActiveJobScreen(gig: _gig),
          ),
        ),
      );
    }

    // Default / Seeking state: Cancel option
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CancelGigScreen(gig: _gig),
          ),
        ),
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: const Text('Cancel Gig Request'),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Refresh gig status'),
                onTap: () {
                  Navigator.pop(context);
                  _refreshGig();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_calendar_rounded),
                title: const Text('Reschedule gig'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RescheduleGigScreen(gig: _gig),
                    ),
                  );
                },
              ),
              if (_gig.stage != GigStage.completed)
                ListTile(
                  leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                  title: const Text('Cancel gig', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CancelGigScreen(gig: _gig),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded square card for quick actions row
class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          border: Border.all(
            color: isHighlighted
                ? AppColors.primary
                : AppColors.border.withValues(alpha: 0.6),
            width: isHighlighted ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isHighlighted ? AppColors.primary : AppColors.text,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
                color: isHighlighted ? AppColors.primary : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
