import 'package:flutter/material.dart';

import '../../../models/worker_job_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../../common/chat_screen.dart';
import 'completion_evidence_upload_screen.dart';
import 'material_bill_upload_screen.dart';
import 'multi_worker_invite_screen.dart';
import 'waiting_confirmation_screen.dart';
import 'worker_cancel_reschedule_screen.dart';
import 'worker_payment_confirmation_screen.dart';

class WorkerActiveJobScreen extends StatefulWidget {
  const WorkerActiveJobScreen({super.key, required this.job});

  final WorkerJob job;

  @override
  State<WorkerActiveJobScreen> createState() => _WorkerActiveJobScreenState();
}

class _WorkerActiveJobScreenState extends State<WorkerActiveJobScreen> {
  late WorkerJobStatus _status;
  int? _materialClaim;
  String? _invitedCoWorker;

  @override
  void initState() {
    super.initState();
    _status = widget.job.status;
    _invitedCoWorker = widget.job.additionalWorkerName;
  }

  void _advanceProgress() {
    setState(() {
      if (_status == WorkerJobStatus.accepted ||
          _status == WorkerJobStatus.scheduled) {
        _status = WorkerJobStatus.active;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job marked In Progress. Customer has been alerted.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Active Job Workspace',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WorkerCancelRescheduleScreen(job: widget.job),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          // Status Progress Bar
          _buildStatusTracker(),
          const SizedBox(height: 16),

          // Main Header Card
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.job.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    StatusPill(_status.label),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.job.category} · ${widget.job.when}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fixed Wage',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
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
                if (_materialClaim != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Materials Reimbursed',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      Text(
                        '₹$_materialClaim',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Operations Row (SRS 16 & SRS 7.2 & SRS 21)
          Row(
            children: [
              Expanded(
                child: _buildOperationButton(
                  icon: Icons.group_add_rounded,
                  label: 'Invite Co-Worker',
                  onTap: () async {
                    final invited = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) =>
                            MultiWorkerInviteScreen(job: widget.job),
                      ),
                    );
                    if (invited == true) {
                      setState(
                        () => _invitedCoWorker = 'Suresh Kumar (Rookie)',
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOperationButton(
                  icon: Icons.receipt_long_rounded,
                  label: 'Material Bill',
                  onTap: () async {
                    final claim = await Navigator.of(context).push<int>(
                      MaterialPageRoute(
                        builder: (_) => MaterialBillUploadScreen(
                          jobTitle: widget.job.title,
                        ),
                      ),
                    );
                    if (claim != null) {
                      setState(() => _materialClaim = claim);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOperationButton(
                  icon: Icons.schedule_send_rounded,
                  label: 'Reschedule',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            WorkerCancelRescheduleScreen(job: widget.job),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Collaborating Co-Worker Banner if any
          if (_invitedCoWorker != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.handshake_rounded,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Collaborating Worker Assigned',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          _invitedCoWorker!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Customer Card with Actions
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Contact',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                      child: const Icon(Icons.person_outline_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.job.customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const Text(
                            'Verified Customer · Koramangala',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.call_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Calling ${widget.job.customerName}...',
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChatScreen(
                              title: widget.job.customerName,
                              subtitle: 'Customer · ${widget.job.title}',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Location & Navigation
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.job.location,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Instructions: ${widget.job.instructions}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
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
        child: _buildBottomActionButton(),
      ),
    );
  }

  Widget _buildStatusTracker() {
    final steps = ['Accepted', 'In Progress', 'Evidence', 'Payment'];
    int currentStep = 0;
    if (_status == WorkerJobStatus.active) currentStep = 1;
    if (_status == WorkerJobStatus.evidenceSubmitted) currentStep = 2;
    if (_status == WorkerJobStatus.paymentPending) currentStep = 3;
    if (_status == WorkerJobStatus.completed) currentStep = 4;

    return Row(
      children: List.generate(steps.length, (idx) {
        final isDone = idx < currentStep;
        final isCurrent = idx == currentStep;
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isDone || isCurrent
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[idx],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.normal,
                  color: isCurrent ? AppColors.primary : AppColors.muted,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOperationButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionButton() {
    if (_status == WorkerJobStatus.accepted ||
        _status == WorkerJobStatus.scheduled) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: _advanceProgress,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text(
            'Arrived & Start Work',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else if (_status == WorkerJobStatus.active) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CompletionEvidenceUploadScreen(job: widget.job),
              ),
            );
          },
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text(
            'Complete Work & Submit Evidence',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else if (_status == WorkerJobStatus.evidenceSubmitted) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => WaitingConfirmationScreen(job: widget.job),
              ),
            );
          },
          icon: const Icon(Icons.hourglass_empty_rounded),
          label: const Text(
            'Waiting for Customer Approval',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else if (_status == WorkerJobStatus.paymentPending) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    WorkerPaymentConfirmationScreen(job: widget.job),
              ),
            );
          },
          icon: const Icon(Icons.payments_rounded),
          label: const Text(
            'Confirm Payment Received',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Back to My Jobs'),
      ),
    );
  }
}
