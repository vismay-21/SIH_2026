import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/api/api_models.dart';
import '../../../models/worker_job_workflow.dart';
import '../../../providers/active_job_sync_provider.dart';
import '../../../repositories/gig_repository.dart';
import '../../../repositories/worker_repository.dart';
import '../../../services/token_storage.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/phone_dialer_helper.dart';
import '../../../widgets/common/location_picker_dialog.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../../common/chat_screen.dart';
import 'completion_evidence_upload_screen.dart';
import 'material_bill_upload_screen.dart';
import 'multi_worker_invite_screen.dart';
import 'visitation_proposal_dialog.dart';
import 'waiting_confirmation_screen.dart';
import 'worker_cancel_reschedule_screen.dart';
import 'worker_payment_confirmation_screen.dart';

class WorkerActiveJobScreen extends ConsumerStatefulWidget {
  const WorkerActiveJobScreen({super.key, required this.job});

  final WorkerJob job;

  @override
  ConsumerState<WorkerActiveJobScreen> createState() => _WorkerActiveJobScreenState();
}

class _WorkerActiveJobScreenState extends ConsumerState<WorkerActiveJobScreen> {
  late WorkerJobStatus _status;
  int? _materialClaim;
  String? _invitedCoWorker;
  bool _isCheckingStatus = false;
  bool _isAnotherWorkerSelected = false;
  VisitationResponseDto? _visitationDetails;

  @override
  void initState() {
    super.initState();
    _status = widget.job.status;
    _invitedCoWorker = widget.job.additionalWorkerName;
    _checkSelectionStatus(silent: true);
  }

  Future<void> _checkSelectionStatus({bool silent = false}) async {
    final gigId = widget.job.gigId;
    if (gigId == null || gigId.startsWith('job-') || gigId.startsWith('opp-')) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waiting for customer to review and select you.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isCheckingStatus = true);
    try {
      final gig = await GigRepository().getGig(gigId);
      final currentUserId = TokenStorage.instance.currentUser?.id;

      if (gig.selectedWorkerId != null) {
        if (currentUserId == null || gig.selectedWorkerId == currentUserId) {
          final s = gig.status.toUpperCase();
          WorkerJobStatus newStatus = WorkerJobStatus.accepted;
          if (s == 'IN_PROGRESS') {
            newStatus = WorkerJobStatus.active;
          } else if (s == 'COMPLETION_SUBMITTED' || s == 'WORKER_COMPLETED') {
            newStatus = WorkerJobStatus.evidenceSubmitted;
          } else if (s == 'CUSTOMER_CONFIRMED' ||
              s == 'PAYMENT_PENDING' ||
              s == 'PAYMENT_CUSTOMER_PAID') {
            newStatus = WorkerJobStatus.paymentPending;
          } else if (s == 'COMPLETED' || s == 'PAYMENT_WORKER_CONFIRMED') {
            newStatus = WorkerJobStatus.completed;
          }

          setState(() {
            _isAnotherWorkerSelected = false;
            _status = newStatus;
          });

          if (gig.gigType == 'VISITATION' ||
              widget.job.gigType == 'VISITATION' ||
              widget.job.category.toLowerCase().contains('visit')) {
            try {
              final vis = await GigRepository().getVisitationDetails(gigId);
              if (mounted) {
                setState(() => _visitationDetails = vis);
              }
            } catch (_) {}
          }
          if (mounted && !silent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(newStatus == WorkerJobStatus.accepted
                    ? 'Great news! The customer selected you! You can now start work.'
                    : 'Gig status updated: ${_status.label}.'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          setState(() {
            _isAnotherWorkerSelected = true;
          });
          if (mounted && !silent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('The customer selected another worker for this gig.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        if (mounted && !silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Still waiting for customer to select you. Please check back shortly.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not check status: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _advanceProgress() async {
    final gigId = widget.job.gigId;
    if (gigId != null && !gigId.startsWith('job-')) {
      try {
        await WorkerRepository().startWork(gigId);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting work: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

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
    final gigId = widget.job.gigId ?? widget.job.id;
    if (!gigId.startsWith('job-') && !gigId.startsWith('opp-')) {
      ref.listen<AsyncValue<GigDto?>>(activeGigSyncProvider(gigId), (prev, next) {
        final gig = next.asData?.value;
        if (gig != null) {
          final currentUserId = TokenStorage.instance.currentUser?.id;
          if (gig.selectedWorkerId != null) {
            if (currentUserId == null || gig.selectedWorkerId == currentUserId) {
              final s = gig.status.toUpperCase();
              WorkerJobStatus newStatus = WorkerJobStatus.accepted;
              if (s == 'IN_PROGRESS') {
                newStatus = WorkerJobStatus.active;
              } else if (s == 'COMPLETION_SUBMITTED' || s == 'WORKER_COMPLETED') {
                newStatus = WorkerJobStatus.evidenceSubmitted;
              } else if (s == 'CUSTOMER_CONFIRMED' ||
                  s == 'PAYMENT_PENDING' ||
                  s == 'PAYMENT_CUSTOMER_PAID') {
                newStatus = WorkerJobStatus.paymentPending;
              } else if (s == 'COMPLETED' || s == 'PAYMENT_WORKER_CONFIRMED') {
                newStatus = WorkerJobStatus.completed;
              }

              if (mounted && (_status != newStatus || _isAnotherWorkerSelected)) {
                setState(() {
                  _status = newStatus;
                  _isAnotherWorkerSelected = false;
                });
              }
            } else {
              if (mounted && !_isAnotherWorkerSelected) {
                setState(() => _isAnotherWorkerSelected = true);
              }
            }
          }
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Active Job Workspace',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: _isCheckingStatus
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Status',
            onPressed: _isCheckingStatus ? null : () => _checkSelectionStatus(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          // Status Progress Bar
          _buildStatusTracker(),
          const SizedBox(height: 16),

          // Unselected Warning Banner if customer chose another worker
          if (_isAnotherWorkerSelected) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.deepOrange,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gig Assigned to Another Worker',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.deepOrange,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thank you for applying. The customer has reviewed the candidate pool and selected another technician for this request. You can check for other new opportunities.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text.withValues(alpha: 0.85),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_status == WorkerJobStatus.awaitingSelection) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    color: AppColors.primaryDark,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Waiting for Customer to Accept You',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You have accepted this gig! The customer is currently reviewing candidates. Once the customer confirms you, you will be notified and can arrive & start work.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text.withValues(alpha: 0.85),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

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
                  '${widget.job.category} · Customer: ${widget.job.customerName}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                          'Scheduled Work Time: ${widget.job.when}',
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

          // Quick Operations Row - Only when selected
          if (_status != WorkerJobStatus.awaitingSelection) ...[
            Builder(
              builder: (context) {
                final canInviteCoworker = _status == WorkerJobStatus.accepted || _status == WorkerJobStatus.scheduled;
                final canSubmitMaterialBill = widget.job.workerBringsMaterials;
                final canReschedule = _status != WorkerJobStatus.completed && _status != WorkerJobStatus.cancelled;

                final buttons = <Widget>[];

                if (canInviteCoworker) {
                  buttons.add(
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
                  );
                }

                if (canSubmitMaterialBill) {
                  buttons.add(
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
                  );
                }

                if (canReschedule) {
                  buttons.add(
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
                  );
                }

                if (buttons.isEmpty) return const SizedBox.shrink();

                final spacedChildren = <Widget>[];
                for (var i = 0; i < buttons.length; i++) {
                  if (i > 0) spacedChildren.add(const SizedBox(width: 10));
                  spacedChildren.add(buttons[i]);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(children: spacedChildren),
                );
              },
            ),
          ],

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
                          Text(
                            widget.job.location.isNotEmpty
                                ? 'Verified Customer · ${widget.job.location}'
                                : 'Verified Customer',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.call_rounded,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Call Customer',
                      onPressed: () {
                        PhoneDialerHelper.launchDialer(
                          context,
                          widget.job.customerPhone,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChatScreen(
                              title: widget.job.customerName,
                              subtitle: 'Customer · ${widget.job.title}',
                              gigId: widget.job.gigId,
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
                Builder(
                  builder: (context) {
                    final hasMapsLink = widget.job.googleMapsLink != null &&
                        widget.job.googleMapsLink!.isNotEmpty;
                    final mapUrl = hasMapsLink
                        ? widget.job.googleMapsLink!
                        : (widget.job.latitude != null && widget.job.longitude != null
                            ? PickedLocation.generateGoogleMapsLink(
                                widget.job.latitude!, widget.job.longitude!)
                            : (widget.job.location.isNotEmpty &&
                                    widget.job.location != 'Assigned location'
                                ? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.job.location)}'
                                : null));

                    if (mapUrl == null) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => launchGoogleMaps(context, mapUrl),
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text(
                          'Open in Google Maps',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    );
                  },
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
    if (_status == WorkerJobStatus.awaitingSelection) {
      final steps = ['Applied', 'Selection', 'In Progress', 'Evidence', 'Payment'];
      return Row(
        children: List.generate(steps.length, (idx) {
          final isDone = idx == 0;
          final isCurrent = idx == 1;
          return Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.primary
                        : (isCurrent ? AppColors.accent : AppColors.border),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[idx],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: (isCurrent || isDone) ? FontWeight.w800 : FontWeight.normal,
                    color: isCurrent
                        ? AppColors.primaryDark
                        : (isDone ? AppColors.primary : AppColors.muted),
                  ),
                ),
              ],
            ),
          );
        }),
      );
    }

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
    if (_isAnotherWorkerSelected) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text(
            'Return to My Jobs',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      );
    }

    if (_status == WorkerJobStatus.awaitingSelection) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.tonalIcon(
          onPressed: _isCheckingStatus ? null : _checkSelectionStatus,
          icon: _isCheckingStatus
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
          label: const Text(
            'Waiting for Customer to Accept You · Check Status',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      );
    }

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
        ),
      );
    } else if (_status == WorkerJobStatus.active) {
      final isVisitation = widget.job.gigType == 'VISITATION' ||
          widget.job.category == 'VISITATION' ||
          _visitationDetails?.isVisitation == true;

      if (isVisitation) {
        final hasPendingProposal =
            _visitationDetails?.activeProposal?.status == 'PENDING';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPendingProposal) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 16, color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Proposal Pending Customer Approval (₹${_visitationDetails!.activeProposal!.basePrice.toInt()})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  final proposed = await VisitationProposalDialog.show(
                    context,
                    gigId: widget.job.gigId ?? widget.job.id,
                    categoryId: widget.job.categoryId ?? '',
                    categoryName: widget.job.category,
                  );
                  if (proposed == true) {
                    _checkSelectionStatus(silent: true);
                  }
                },
                icon: const Icon(Icons.assignment_add),
                label: Text(
                  hasPendingProposal
                      ? 'Update Proposed Tasks & Quote'
                      : 'Propose Diagnostic Tasks & Quote',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CompletionEvidenceUploadScreen(job: widget.job),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text(
                  'Complete Visitation & Submit Evidence',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        );
      }

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
