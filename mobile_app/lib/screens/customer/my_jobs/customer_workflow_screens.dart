import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/api/api_models.dart';
import '../../../models/customer_gig_workflow.dart';
import '../../../repositories/gig_repository.dart';
import '../../../repositories/payment_repository.dart';
import '../../../repositories/review_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/phone_dialer_helper.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../../../widgets/common/sos_dialog.dart';
import '../../common/chat_screen.dart';
import '../profile/customer_account_screens.dart';
import 'reschedule_gig_screen.dart';
import 'review_worker_screen.dart';

class AcceptedCandidatesScreen extends StatefulWidget {
  const AcceptedCandidatesScreen({super.key, required this.gig});
  final CustomerGig gig;

  @override
  State<AcceptedCandidatesScreen> createState() =>
      _AcceptedCandidatesScreenState();
}

class _AcceptedCandidatesScreenState extends State<AcceptedCandidatesScreen> {
  final _gigRepo = GigRepository();
  bool _isLoading = false;
  String? _error;
  List<GigCandidate> _candidates = [];

  @override
  void initState() {
    super.initState();
    _candidates = widget.gig.candidates;
    _fetchCandidates();
  }

  Future<void> _fetchCandidates() async {
    if (widget.gig.id == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dtoList = await _gigRepo.getCandidates(widget.gig.id!);
      if (mounted) {
        setState(() {
          _candidates = dtoList
              .map((d) =>
                  GigCandidate.fromDto(d, categoryName: widget.gig.category))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Accepted candidates',
    subtitle: 'Compare workers who accepted this gig before choosing one.',
    child: Column(
      children: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null && _candidates.isEmpty)
          SurfaceCard(
            child: Column(
              children: [
                Text(
                  'Could not load candidates: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _fetchCandidates,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (_candidates.isEmpty)
          const SurfaceCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No candidates have accepted this gig yet.\nCheck back soon!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ),
          )
        else
          ..._candidates.map(
            (candidate) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CandidateTile(candidate: candidate, gig: widget.gig),
            ),
          ),
      ],
    ),
  );
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({required this.candidate, required this.gig});
  final GigCandidate candidate;
  final CustomerGig gig;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Text(candidate.initials),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${candidate.skill} · ${candidate.experience}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (candidate.isRecommended) const StatusPill('Recommended'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          candidate.summary,
          style: const TextStyle(color: AppColors.muted, height: 1.3),
        ),
        const SizedBox(height: 10),
        Text(
          '${candidate.wage} labour · ★ ${candidate.rating} · ${candidate.jobs}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: FilledButton(
                onPressed: () => _handleSelectCandidate(context),
                child: const Text('Select Worker'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        WorkerProfileScreen(candidate: candidate, gig: gig),
                  ),
                ),
                child: const Text('Profile'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Future<void> _handleSelectCandidate(BuildContext context) async {
    if (gig.id != null && candidate.workerId != null) {
      try {
        await GigRepository().selectWorker(
          gigId: gig.id!,
          workerId: candidate.workerId!,
        );
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => FinalWorkerSelectedScreen(
                candidate: candidate,
                gig: gig,
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to select worker: $e')),
          );
        }
      }
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FinalWorkerSelectedScreen(
            candidate: candidate,
            gig: gig,
          ),
        ),
      );
    }
  }
}

class WorkerComparisonScreen extends StatelessWidget {
  const WorkerComparisonScreen({super.key, required this.gig});
  final CustomerGig gig;

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Compare workers',
    subtitle: 'The recommendation is guidance, not automatic assignment.',
    child: Column(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Cooperative recommendation',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Amit is recommended for the strongest skill match, availability, and reliability signals.',
                style: TextStyle(color: AppColors.muted, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...gig.candidates.map(
          (candidate) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ComparisonRow(candidate: candidate, gig: gig),
          ),
        ),
      ],
    ),
  );
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.candidate, required this.gig});
  final GigCandidate candidate;
  final CustomerGig gig;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                candidate.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              candidate.wage,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          '${candidate.experience} · ★ ${candidate.rating} · ${candidate.jobs}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: candidate.factors
              .map((factor) => StatusPill(factor))
              .toList(),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    WorkerProfileScreen(candidate: candidate, gig: gig),
              ),
            ),
            child: const Text('View profile'),
          ),
        ),
      ],
    ),
  );
}

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({
    super.key,
    required this.candidate,
    required this.gig,
  });
  final GigCandidate candidate;
  final CustomerGig gig;

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  bool _isSelecting = false;

  Future<void> _handleSelect() async {
    if (widget.gig.id != null && widget.candidate.workerId != null) {
      setState(() => _isSelecting = true);
      try {
        await GigRepository().selectWorker(
          gigId: widget.gig.id!,
          workerId: widget.candidate.workerId!,
        );
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => FinalWorkerSelectedScreen(
                candidate: widget.candidate,
                gig: widget.gig,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to select worker: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSelecting = false);
      }
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FinalWorkerSelectedScreen(
            candidate: widget.candidate,
            gig: widget.gig,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.candidate;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 2.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            c.initials,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        c.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            c.skill,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          if (c.isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, size: 11, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text(
                                    'Recommended',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Row
                Row(
                  children: [
                    _StatBox(icon: Icons.star_rounded, label: 'Rating', value: '★ ${c.rating}', color: Colors.amber.shade700),
                    const SizedBox(width: 10),
                    _StatBox(icon: Icons.work_history_outlined, label: 'Jobs Done', value: c.jobs, color: AppColors.primary),
                    const SizedBox(width: 10),
                    _StatBox(icon: Icons.payments_outlined, label: 'Wage', value: c.wage, color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 16),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.contact_phone_outlined, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text('Contact & Settlement', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      ]),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Artisan Phone', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(c.phoneNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            ],
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => PhoneDialerHelper.launchDialer(context, c.phoneNumber),
                            icon: const Icon(Icons.call_rounded, size: 16),
                            label: const Text('Call'),
                            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Settlement UPI ID', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(c.upiId, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                            tooltip: 'Copy UPI ID',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: c.upiId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('UPI ID copied: ${c.upiId}')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.engineering_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text('Experience', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      ]),
                      const SizedBox(height: 8),
                      Text('${c.experience} of comparable household work.', style: const TextStyle(color: AppColors.muted, height: 1.35)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text('Cooperative Assessment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      ]),
                      const SizedBox(height: 8),
                      Text(c.summary, style: const TextStyle(color: AppColors.muted, height: 1.35)),
                    ],
                  ),
                ),
                if (c.factors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text('Key Strengths', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ]),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: c.factors.map((factor) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Text(factor, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppColors.success, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Zero Commission. Guaranteed.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            SizedBox(height: 2),
                            Text('Cooperative tariff — full wage to worker.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(c.wage, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.success)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: PrimaryAction(
            label: _isSelecting ? 'Selecting worker...' : 'Select ${c.name}',
            icon: _isSelecting ? Icons.hourglass_top_rounded : Icons.check_circle_outline_rounded,
            onPressed: _isSelecting ? null : _handleSelect,
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class FinalWorkerSelectedScreen extends StatelessWidget {
  const FinalWorkerSelectedScreen({
    super.key,
    required this.candidate,
    required this.gig,
  });
  final GigCandidate candidate;
  final CustomerGig gig;

  @override
  Widget build(BuildContext context) {
    final selectedGig = gig.copyWith(
      stage: GigStage.selected,
      selectedWorker: candidate,
    );

    return _WorkflowScaffold(
      title: 'Worker selected',
      subtitle: 'You have made the final choice for this gig.',
      child: Column(
        children: [
          SurfaceCard(
            child: Column(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.primary,
                  size: 44,
                ),
                const SizedBox(height: 10),
                Text(
                  candidate.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${candidate.skill} · ${candidate.wage} labour',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Job chat is now available after worker selection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: PrimaryAction(
              label: 'Open active job',
              icon: Icons.work_history_outlined,
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => ActiveJobScreen(gig: selectedGig),
                ),
                (route) => route.isFirst,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PreviousWorkerRequestScreen extends StatelessWidget {
  const PreviousWorkerRequestScreen({super.key});

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Request previous worker',
    subtitle: 'Amit Sharma is not selected until he accepts this request.',
    child: Column(
      children: [
        SurfaceCard(
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: Text('AS'),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amit Sharma',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Plumber · ★ 4.8 · 23 jobs',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const StatusPill('Available'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _InfoCard(
          title: 'What happens next',
          body:
              'Amit can accept, reject, or propose another time. If unavailable, you can return to open matching.',
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: PrimaryAction(
            label: 'Send request',
            icon: Icons.send_rounded,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request sent to Amit Sharma.')),
              );
              Navigator.of(context).pop();
            },
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Open matching instead'),
        ),
      ],
    ),
  );
}

class ActiveJobScreen extends StatelessWidget {
  const ActiveJobScreen({super.key, required this.gig});
  final CustomerGig gig;

  @override
  Widget build(BuildContext context) {
    final worker = gig.selectedWorker;
    final workerName = worker?.name ?? 'Assigned Artisan';
    final workerPhone = worker?.phoneNumber ?? '+91 98765 43210';
    final workerRating = worker?.rating ?? '4.0';
    final workerInitials = worker?.initials ??
        (workerName.isNotEmpty ? workerName[0].toUpperCase() : 'A');

    final isCompletionRequested = gig.stage == GigStage.completionRequested;
    final isCompleted = gig.stage == GigStage.completed;
    final isPayment = gig.stage == GigStage.payment;
    final isInProgress = gig.stage == GigStage.active;

    String screenTitle;
    String statusBadge;
    String statusDescription;
    int currentStep = 0;

    if (isCompleted) {
      screenTitle = 'Job Completed';
      statusBadge = 'Completed';
      statusDescription = 'This gig has been satisfactorily completed. Thank you for using Sahakaar Seva!';
      currentStep = 3;
    } else if (isPayment) {
      screenTitle = 'Payment Due';
      statusBadge = 'Payment Required';
      statusDescription = 'Work has been approved. Please release payment to the artisan.';
      currentStep = 3;
    } else if (isCompletionRequested) {
      screenTitle = 'Review Evidence';
      statusBadge = 'Evidence Submitted';
      statusDescription = 'Artisan has completed the task and uploaded evidence photos for your approval.';
      currentStep = 2;
    } else if (isInProgress) {
      screenTitle = 'Job In Progress';
      statusBadge = 'Work Underway';
      statusDescription = 'Artisan is actively working on the task on-site.';
      currentStep = 1;
    } else {
      screenTitle = 'Scheduled Job';
      statusBadge = 'Awaiting Arrival';
      statusDescription = 'Artisan has been assigned and is en route to your service address.';
      currentStep = 0;
    }

    void openChat() {
      if (gig.id != null) {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(
            builder: (_) => ChatScreen(
              title: workerName,
              subtitle: gig.title,
              gigId: gig.id,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CustomerChatThreadScreen(
              workerName: workerName,
              jobTitle: gig.title,
              enabled: gig.chatEnabled,
              gig: gig,
            ),
          ),
        );
      }
    }

    final steps = ['Accepted', 'In Progress', 'Evidence', 'Payment'];

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          // 1. Horizontal Status Tracker
          Row(
            children: List.generate(steps.length, (idx) {
              final isDone = idx < currentStep;
              final isCurrent = idx == currentStep;
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
          ),
          const SizedBox(height: 16),

          // 2. Main Job Summary Card
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        gig.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(statusBadge),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${gig.category} · ${gig.when} · ${gig.duration}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Confirmed Labour Price',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    Text(
                      gig.priceDisplay,
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
          ),
          const SizedBox(height: 12),

          // 3. Quick Actions: Material Bill & Reschedule
          Row(
            children: [
              Expanded(
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MaterialBillViewerScreen(),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
                          SizedBox(height: 6),
                          Text('Material Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (gig.stage == GigStage.completed || gig.stage == GigStage.payment) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cannot reschedule a completed or paying gig.')),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RescheduleGigScreen(gig: gig),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: 22),
                          SizedBox(height: 6),
                          Text('Reschedule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. Assigned Artisan Card
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assigned Artisan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        workerInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${gig.category} Specialist · ★ $workerRating',
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
                      onPressed: () => PhoneDialerHelper.launchDialer(context, workerPhone),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      tooltip: 'Chat',
                      onPressed: openChat,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5. Status Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusBadge,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusDescription,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. Action Buttons
          if (isInProgress) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => SosEmergencyDialog.show(context),
                icon: const Icon(Icons.emergency_rounded, color: Colors.white),
                label: const Text(
                  '🚨 SOS Emergency Assist',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.3),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else if (isCompletionRequested) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CompletionEvidenceReviewScreen(gig: gig),
                  ),
                ),
                icon: const Icon(Icons.fact_check_rounded),
                label: const Text('Review Work Evidence'),
              ),
            ),
          ] else if (isPayment) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PaymentScreen(gig: gig),
                  ),
                ),
                icon: const Icon(Icons.payment_rounded),
                label: const Text('Proceed to Payment'),
              ),
            ),
          ] else if (isCompleted) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReviewWorkerScreen(
                      workerName: workerName,
                      gigTitle: gig.title,
                    ),
                  ),
                ),
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Rate & Review Worker'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CompletionEvidenceReviewScreen extends StatefulWidget {
  const CompletionEvidenceReviewScreen({super.key, required this.gig});

  final CustomerGig gig;

  @override
  State<CompletionEvidenceReviewScreen> createState() =>
      _CompletionEvidenceReviewScreenState();
}

class _CompletionEvidenceReviewScreenState
    extends State<CompletionEvidenceReviewScreen> {
  GigCompletionDetailDto? _completion;

  @override
  void initState() {
    super.initState();
    _fetchEvidence();
  }

  Future<void> _fetchEvidence() async {
    if (widget.gig.id == null) return;
    try {
      final comp = await GigRepository().getCompletion(widget.gig.id!);
      if (mounted) setState(() => _completion = comp);
    } catch (_) {
      // Keep existing default display
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gig.stage != GigStage.completionRequested && _completion == null) {
      return _WorkflowScaffold(
        title: 'Completion evidence',
        subtitle: 'Evidence has not been submitted yet.',
        child: Column(
          children: [
            SurfaceCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.pending_actions_rounded,
                        size: 48,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Evidence Pending',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'The artisan has not submitted work completion photos yet. Once work is finished and photos are uploaded, you will be able to review and confirm them here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Job Details'),
              ),
            ),
          ],
        ),
      );
    }

    final photoCount = _completion?.submission?.evidenceFiles.length ?? 2;
    final notes = _completion?.submission?.description ??
        'Before and after photos from the selected worker are ready to review.';

    return _WorkflowScaffold(
      title: 'Completion evidence',
      subtitle: 'Review the worker evidence before confirming the work.',
      child: Column(
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                  size: 38,
                ),
                const SizedBox(height: 10),
                Text(
                  '$photoCount completion photo(s) uploaded',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  notes,
                  style: const TextStyle(color: AppColors.muted, height: 1.3),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Evidence viewer opened.')),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('View evidence'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: PrimaryAction(
              label: 'Confirm completion',
              icon: Icons.check_circle_outline_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompletionConfirmationScreen(gig: widget.gig),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You can contact the worker before confirming.'),
              ),
            ),
            child: const Text('Contact worker about the work'),
          ),
        ],
      ),
    );
  }
}

class CompletionConfirmationScreen extends StatefulWidget {
  const CompletionConfirmationScreen({super.key, required this.gig});

  final CustomerGig gig;

  @override
  State<CompletionConfirmationScreen> createState() =>
      _CompletionConfirmationScreenState();
}

class _CompletionConfirmationScreenState
    extends State<CompletionConfirmationScreen> {
  bool _isLoading = false;

  Future<void> _handleConfirm() async {
    if (widget.gig.id != null) {
      setState(() => _isLoading = true);
      try {
        await GigRepository().confirmCompletion(
          gigId: widget.gig.id!,
          confirmed: true,
        );
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PaymentScreen(gig: widget.gig),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to confirm completion: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PaymentScreen(gig: widget.gig),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Confirm completion',
    subtitle: 'Confirm only after checking that the work is complete.',
    child: Column(
      children: [
        SurfaceCard(
          child: Column(
            children: [
              const Icon(
                Icons.task_alt_rounded,
                color: AppColors.primary,
                size: 44,
              ),
              const SizedBox(height: 10),
              const Text(
                'Is the work complete?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              const Text(
                'This moves the gig to payment. Evidence alone does not complete a gig.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: PrimaryAction(
            label: _isLoading ? 'Confirming...' : 'Yes, confirm completion',
            icon: _isLoading
                ? Icons.hourglass_top_rounded
                : Icons.check_rounded,
            onPressed: _isLoading ? null : _handleConfirm,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not yet'),
        ),
      ],
    ),
  );
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.gig});

  final CustomerGig gig;
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _paymentRepo = PaymentRepository();
  final _reviewRepo = ReviewRepository();
  String _method = 'UPI';
  bool _isProcessing = false;
  bool _paid = false;
  bool _workerConfirmed = false;
  String? _displayAmount;
  Timer? _paymentCheckTimer;

  int _rating = 5;
  final _commentController = TextEditingController();
  final Set<String> _selectedTags = {'Punctual', 'Clean Work'};
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    _fetchPayment();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _paymentCheckTimer?.cancel();
    super.dispose();
  }

  void _startPaymentPolling() {
    _paymentCheckTimer?.cancel();
    _paymentCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || widget.gig.id == null) return;
      try {
        final payment = await _paymentRepo.getGigPayment(widget.gig.id!);
        if (payment.status == 'WORKER_CONFIRMED' || payment.status == 'COMPLETED') {
          _paymentCheckTimer?.cancel();
          _paymentCheckTimer = null;
          if (mounted) {
            setState(() {
              _workerConfirmed = true;
            });
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _fetchPayment() async {
    if (widget.gig.id == null) return;
    try {
      final payment = await _paymentRepo.getGigPayment(widget.gig.id!);
      if (mounted) {
        setState(() {
          _displayAmount = '₹${payment.amount.toStringAsFixed(0)}';
          if (payment.status == 'COMPLETED' || payment.status == 'WORKER_CONFIRMED' || payment.status == 'SUCCESS') {
            _paid = true;
            _workerConfirmed = true;
          } else if (payment.status == 'CUSTOMER_PAID') {
            _paid = true;
            _startPaymentPolling();
          }
        });
      }
    } catch (_) {
      // Payment record may not exist prior to creation, which is normal.
    }
  }

  Future<void> _handlePayment() async {
    final rawAmountStr = _displayAmount?.replaceAll(RegExp(r'[^0-9.]'), '') ??
        widget.gig.selectedWorker?.wage.replaceAll(RegExp(r'[^0-9.]'), '') ??
        '680';
    final amount = double.tryParse(rawAmountStr) ?? 680.0;

    if (_method == 'UPI') {
      const upiUri = 'upi://pay?pa=yugshah5253@oksbi&pn=Yug%20Shah&cu=INR&tn=Sahakaar%20Seva%20Payment';
      final formattedUri = '$upiUri&am=${amount.toStringAsFixed(2)}';
      try {
        const channel = MethodChannel('sahakaar_seva/upi');
        await channel.invokeMethod('launchUpi', {'uri': formattedUri});
      } catch (e) {
        debugPrint('Could not launch native UPI intent: $e');
      }
    }

    if (widget.gig.id != null) {
      setState(() => _isProcessing = true);
      try {
        await _paymentRepo.recordPayment(
          gigId: widget.gig.id!,
          paymentMethod: _method,
        );
        if (mounted) {
          setState(() {
            _paid = true;
          });
          _startPaymentPolling();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _method == 'UPI'
                    ? 'UPI payment initiated (₹${amount.toStringAsFixed(0)} to yugshah5253@oksbi). Worker confirmation is pending.'
                    : 'Payment recorded. Worker confirmation is pending.',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment recording failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    } else {
      if (!mounted) return;
      setState(() => _paid = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _method == 'UPI'
                ? 'UPI payment initiated (₹${amount.toStringAsFixed(0)} to yugshah5253@oksbi).'
                : 'Payment recorded. Worker confirmation is pending.',
          ),
        ),
      );
    }
  }

  String _ratingDescription(int rating) {
    switch (rating) {
      case 5:
        return '⭐⭐⭐⭐⭐ Excellent Service!';
      case 4:
        return '⭐⭐⭐⭐ Very Good Experience';
      case 3:
        return '⭐⭐⭐ Satisfactory Service';
      case 2:
        return '⭐⭐ Needs Improvement';
      default:
        return '⭐ Unsatisfactory';
    }
  }

  Future<void> _submitReviewAndGoHome() async {
    if (_isSubmittingReview) return;
    setState(() => _isSubmittingReview = true);

    try {
      final gigId = widget.gig.id;
      final workerId = widget.gig.selectedWorker?.workerId;

      if (gigId != null && workerId != null) {
        try {
          final questions = await _reviewRepo.getQuestions(targetRole: 'WORKER');
          final answers = questions
              .map((q) => ReviewAnswerItemDto(
                    questionId: q.id,
                    answerValue: _rating,
                  ))
              .toList();

          if (answers.isNotEmpty) {
            await _reviewRepo.submitReview(
              gigId: gigId,
              revieweeId: workerId,
              answers: answers,
            );
          }
        } catch (e) {
          debugPrint('Review submission through API error: $e');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted! Thank you for supporting our artisans.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Payment',
    subtitle: _paid
        ? 'Payment recorded. Please leave a review for the artisan.'
        : 'Pay the confirmed labour amount. Materials stay separate.',
    child: Column(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Amount due',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 5),
              Text(
                _displayAmount ?? widget.gig.selectedWorker?.wage ?? '₹680',
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              const Text(
                'Labour/service cost only',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!_paid) ...[
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'UPI',
                label: Text('UPI'),
                icon: Icon(Icons.account_balance_wallet_outlined),
              ),
              ButtonSegment(
                value: 'Cash',
                label: Text('Cash'),
                icon: Icon(Icons.payments_outlined),
              ),
            ],
            selected: {_method},
            onSelectionChanged: (selection) =>
                setState(() => _method = selection.first),
          ),
          const SizedBox(height: 8),
          Text(
            _method == 'UPI'
                ? 'Pay using a UPI app.'
                : 'Mark cash payment after handing it over.',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PrimaryAction(
              label: _isProcessing
                  ? 'Processing...'
                  : 'Pay with $_method',
              icon: Icons.lock_outline_rounded,
              onPressed: _isProcessing ? null : _handlePayment,
            ),
          ),
        ],
        if (_paid) ...[
          // Waiting for worker confirmation banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _workerConfirmed
                  ? AppColors.success.withValues(alpha: 0.12)
                  : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _workerConfirmed
                    ? AppColors.success.withValues(alpha: 0.3)
                    : const Color(0xFFFFB300).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _workerConfirmed
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_top_rounded,
                  color: _workerConfirmed ? AppColors.success : const Color(0xFFE65100),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _workerConfirmed
                            ? 'Payment verified by artisan · Job completed'
                            : 'Waiting for worker\'s confirmation',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _workerConfirmed ? AppColors.success : const Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _workerConfirmed
                            ? 'Artisan confirmed receipt of payment. Job completed successfully!'
                            : 'Payment recorded. Waiting for artisan to verify receipt.',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Inline Mandatory Review Section
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Rate & Review ${widget.gig.selectedWorker?.name ?? "Artisan"}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your rating ensures service quality and fair compensation across our guild.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),

                // Interactive 5-star rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      iconSize: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        starIndex <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: starIndex <= _rating ? Colors.amber : AppColors.muted,
                      ),
                      onPressed: () => setState(() => _rating = starIndex),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  _ratingDescription(_rating),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),

                // Compliment chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    'Punctual',
                    'Expert Work',
                    'Clean & Tidy',
                    'Polite & Respectful',
                    'Fair Pricing',
                  ].map((tag) {
                    final selected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: selected,
                      showCheckmark: false,
                      avatar: selected ? const Icon(Icons.check_rounded, size: 14) : null,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Optional feedback text
                TextField(
                  controller: _commentController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add an optional note or review feedback...',
                    hintStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Combined single action: Submit Review & Go to Home Screen
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _isSubmittingReview ? null : _submitReviewAndGoHome,
              icon: _isSubmittingReview
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(
                _isSubmittingReview
                    ? 'Submitting Review...'
                    : 'Submit Review & Return Home',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class MaterialBillViewerScreen extends StatelessWidget {
  const MaterialBillViewerScreen({super.key});

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Material bill / proof',
    subtitle: 'Review the worker-purchased material evidence.',
    child: Column(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Material purchase proof',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'PVC trap and sealant',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Uploaded by Amit Sharma · Today, 6:12 PM',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              Container(
                height: 180,
                width: double.infinity,
                color: AppColors.background,
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 58,
                    color: AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Total material amount',
                style: TextStyle(color: AppColors.muted),
              ),
              const Text(
                '₹420',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Legitimate material bills are expected to be honoured. Material disputes are outside the MVP.',
          style: TextStyle(color: AppColors.muted, height: 1.35),
        ),
      ],
    ),
  );
}

class _WorkflowScaffold extends StatelessWidget {
  const _WorkflowScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 15,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}


class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(color: AppColors.muted, height: 1.35),
          ),
        ],
      ),
    ),
  );
}
