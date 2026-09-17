import 'dart:async';
import 'package:flutter/material.dart';

import '../../../models/api/api_models.dart';
import '../../../models/customer_gig_workflow.dart';
import '../../../repositories/gig_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/phone_dialer_helper.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../../../widgets/common/sos_dialog.dart';
import '../../common/chat_screen.dart';
import 'accepted_candidates_screen.dart';
import 'cancel_gig_screen.dart';
import 'completion_evidence_review_screen.dart';
import 'material_bill_viewer_screen.dart';
import 'payment_screen.dart';
import 'reschedule_gig_screen.dart';
import 'review_worker_screen.dart';

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
  Timer? _statusPollingTimer;
  VisitationResponseDto? _visitationDetails;

  @override
  void initState() {
    super.initState();
    _gig = widget.gig;
    _refreshGig();
    _startStatusPollingIfNeeded();
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    super.dispose();
  }

  void _startStatusPollingIfNeeded() {
    _statusPollingTimer?.cancel();
    // While gig is active (seeking workers, in progress, awaiting evidence/payment), poll every 3.5s so screen auto-updates
    if (_gig.stage != GigStage.completed) {
      _statusPollingTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) async {
        if (!mounted) return;
        await _refreshGig();
        if (_gig.stage == GigStage.completed) {
          _statusPollingTimer?.cancel();
        }
      });
    }
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
        candidates = candidateDtos
            .map((dto) =>
                GigCandidate.fromDto(dto, categoryName: gigDto.categoryName))
            .toList();
      } catch (_) {}

      VisitationResponseDto? vis;
      if (gigDto.gigType == 'VISITATION' ||
          _gig.gigType == 'VISITATION' ||
          _gig.category.toLowerCase().contains('visit')) {
        try {
          vis = await _gigRepo.getVisitationDetails(gigId);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _gig = CustomerGig.fromDto(gigDto, candidates: candidates);
        _visitationDetails = vis;
        _isRefreshing = false;
      });
      _startStatusPollingIfNeeded();
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

            // Incoming Visitation Proposal Card if any
            if (_visitationDetails?.activeProposal != null &&
                _visitationDetails!.activeProposal!.status == 'PENDING') ...[
              _buildVisitationProposalCard(),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 14),

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
            '${_gig.category} · ${_gig.duration}',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Schedule: ${_gig.scheduleDisplay}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isVisitation
                    ? 'Site Visit Charge'
                    : (_gig.selectedWorker != null ||
                            _gig.stage == GigStage.selected ||
                            _gig.stage == GigStage.scheduled ||
                            _gig.stage == GigStage.active ||
                            _gig.stage == GigStage.completionRequested ||
                            _gig.stage == GigStage.payment ||
                            _gig.stage == GigStage.completed
                        ? 'Confirmed Labour Price'
                        : 'Estimated Labour Range'),
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              Text(
                _gig.priceDisplay,
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

  /// Utility cards: Reschedule & Cancel Gig (plus Material Bill once worker is assigned)
  Widget _buildQuickActionCards(BuildContext context) {
    final hasWorker = _gig.selectedWorker != null ||
        _gig.stage == GigStage.selected ||
        _gig.stage == GigStage.scheduled ||
        _gig.stage == GigStage.active ||
        _gig.stage == GigStage.completionRequested ||
        _gig.stage == GigStage.payment ||
        _gig.stage == GigStage.completed;

    return Row(
      children: [
        // Card 1: Material Bill (only visible once worker is assigned)
        if (hasWorker) ...[
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
        ],

        // Card 2: Reschedule
        Expanded(
          child: _QuickCard(
            icon: Icons.edit_calendar_rounded,
            label: 'Reschedule',
            onTap: () {
              if (_gig.stage == GigStage.completed || _gig.stage == GigStage.payment) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot reschedule a completed or paying gig.')),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RescheduleGigScreen(gig: _gig),
                ),
              ).then((_) => _refreshGig());
            },
          ),
        ),
        const SizedBox(width: 8),

        // Card 3: Cancel Gig
        Expanded(
          child: _QuickCard(
            icon: Icons.cancel_outlined,
            label: 'Cancel Gig',
            isDanger: true,
            onTap: () {
              final canCancel = _gig.stage == GigStage.seeking ||
                  _gig.stage == GigStage.responding ||
                  _gig.stage == GigStage.accepted ||
                  _gig.stage == GigStage.selected ||
                  _gig.stage == GigStage.scheduled;
              if (!canCancel) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cannot cancel a gig after work has started or completed.'),
                  ),
                );
                return;
              }
              final nav = Navigator.of(context);
              nav.push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => CancelGigScreen(gig: _gig),
                ),
              ).then((cancelled) {
                if (cancelled == true && mounted) {
                  nav.pop(true);
                } else {
                  _refreshGig();
                }
              });
            },
          ),
        ),
      ],
    );
  }

  /// Context-aware status card
  Widget _buildContextCard(BuildContext context) {
    if (_gig.stage == GigStage.cancelled) {
      return SurfaceCard(
        color: AppColors.danger.withValues(alpha: 0.08),
        padding: const EdgeInsets.all(14),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.danger, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gig Cancelled',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'This gig was cancelled. It is no longer active.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

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
                  tooltip: 'Call Artisan',
                  onPressed: () {
                    PhoneDialerHelper.launchDialer(
                      context,
                      selectedWorker.phoneNumber,
                    );
                  },
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChatScreen(
                          title: selectedWorker.name,
                          subtitle: _gig.title,
                          gigId: _gig.id,
                        ),
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
                      'View ${_gig.candidates.length} Candidate${_gig.candidates.length > 1 ? 's' : ''} & Choose',
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



  /// Incoming Visitation Proposal Review Card
  Widget _buildVisitationProposalCard() {
    final proposal = _visitationDetails!.activeProposal!;

    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_turned_in_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Artisan Proposed Repair Scope',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'On-site inspection completed. Review diagnosed tasks below.',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...proposal.tasks.map((t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${t.taskName} (${t.standardDurationMinutesSnapshot} min)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '₹${t.basePriceSnapshot.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              )),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Labour Quote',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              Text(
                '₹${proposal.basePrice.toInt()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '₹100 diagnostic visit charge is absorbed into this total upon acceptance.',
                    style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    try {
                      await _gigRepo.rejectVisitationProposal(
                        gigId: _gig.id!,
                        proposalId: proposal.id,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Scope declined. Fixed ₹100 visit charge remains payable.'),
                        ),
                      );
                      _refreshGig();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: const Text('Decline Scope'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    try {
                      await _gigRepo.acceptVisitationProposal(
                        gigId: _gig.id!,
                        proposalId: proposal.id,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Scope accepted! Worker will now execute the tasks.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      _refreshGig();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: const Text('Accept Scope'),
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
      return const SizedBox.shrink();
    }

    if (_gig.stage == GigStage.completionRequested) {
      return PrimaryAction(
        label: 'Review Work Evidence',
        icon: Icons.fact_check_rounded,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CompletionEvidenceReviewScreen(gig: _gig),
          ),
        ).then((_) => _refreshGig()),
      );
    }

    // Payment stage: distinctly handle paid vs pending
    if (_gig.stage == GigStage.payment) {
      final isPaid = _gig.rawStatus == 'PAYMENT_CUSTOMER_PAID';
      if (isPaid) {
        return SurfaceCard(
          color: AppColors.success.withValues(alpha: 0.12),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Complete',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Awaiting ${_gig.selectedWorker?.name ?? "worker"} receipt confirmation.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PaymentScreen(gig: _gig),
                  ),
                ).then((_) => _refreshGig()),
                child: const Text('Details'),
              ),
            ],
          ),
        );
      }

      return PrimaryAction(
        label: 'Proceed to Payment',
        icon: Icons.payment_rounded,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PaymentScreen(gig: _gig),
          ),
        ).then((_) => _refreshGig()),
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
        ).then((_) => _refreshGig()),
      );
    }

    if (_gig.stage == GigStage.active && _gig.selectedWorker != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SurfaceCard(
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(
                  Icons.engineering_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Work in Progress · ${_gig.selectedWorker?.name ?? "Artisan"}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Artisan is currently performing the work at your location.',
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
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => SosEmergencyDialog.show(context),
              icon: const Icon(Icons.emergency_rounded, color: Colors.white),
              label: const Text(
                '🚨 SOS Emergency Assist',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Selected / Scheduled: Worker assigned, awaiting arrival
    if (_gig.stage == GigStage.selected || _gig.stage == GigStage.scheduled) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SurfaceCard(
            child: Row(
              children: [
                const Icon(
                  Icons.person_pin_circle_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Worker Assigned: ${_gig.selectedWorker?.name ?? "Specialist"}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Awaiting artisan arrival at your address.',
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
          ),
        ],
      );
    }

    if (_gig.stage == GigStage.cancelled) {
      return SurfaceCard(
        color: AppColors.danger.withValues(alpha: 0.08),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.danger),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This gig has been cancelled.',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Pre-matching seeking/responding: Cancel option is already in the quick actions row above
    return const SizedBox.shrink();
  }
}

/// Small rounded square card for quick actions row
class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDanger
              ? AppColors.danger.withValues(alpha: 0.06)
              : AppColors.surface,
          border: Border.all(
            color: isDanger
                ? AppColors.danger.withValues(alpha: 0.3)
                : AppColors.border.withValues(alpha: 0.6),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDanger ? AppColors.danger : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
