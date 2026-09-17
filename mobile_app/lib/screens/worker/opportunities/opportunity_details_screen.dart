import 'package:flutter/material.dart';

import '../../../models/worker_job_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../../../widgets/common/location_picker_dialog.dart';
import '../my_jobs/worker_active_job_screen.dart';
import 'conflict_warning_dialog.dart';

import '../../../models/api/api_response.dart';
import '../../../repositories/worker_repository.dart';

class OpportunityDetailsScreen extends StatefulWidget {
  const OpportunityDetailsScreen({super.key, required this.opportunity});

  final WorkerOpportunity opportunity;

  @override
  State<OpportunityDetailsScreen> createState() => _OpportunityDetailsScreenState();
}

class _OpportunityDetailsScreenState extends State<OpportunityDetailsScreen> {
  final _workerRepo = WorkerRepository();
  late WorkerOpportunity _opp = widget.opportunity;
  bool _isRefreshing = false;

  WorkerOpportunity get opportunity => _opp;

  @override
  void initState() {
    super.initState();
    _fetchOpportunity();
  }

  Future<void> _fetchOpportunity() async {
    if (_opp.id.isEmpty || _opp.id.startsWith('opp-')) return;
    setState(() => _isRefreshing = true);
    try {
      final dto = await _workerRepo.getOpportunity(_opp.id);
      if (!mounted) return;
      setState(() {
        _opp = WorkerOpportunity.fromDto(dto);
        _isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _handleAccept(BuildContext context) async {
    final workerRepo = _workerRepo;

    try {
      if (opportunity.id.isNotEmpty && !opportunity.id.startsWith('opp-')) {
        await workerRepo.acceptOpportunity(opportunity.id);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Accepted "${opportunity.title}". Waiting for customer selection.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      final newJob = WorkerJob.fromOpportunity(opportunity);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => WorkerActiveJobScreen(job: newJob),
        ),
      );
    } on ApiError catch (e) {
      if (!context.mounted) return;
      if (e.code == 'SCHEDULE_CONFLICT') {
        final proceed = await showConflictWarningDialog(
          context,
          conflictDetails: e.message,
        );
        if (proceed == true) {
          // Worker acknowledged conflict
        }
      } else if (e.code == 'INVALID_OPPORTUNITY_STATE' || e.code == 'GIG_NOT_OPEN') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This opportunity is no longer open for acceptance.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDecline(BuildContext context) async {
    final workerRepo = WorkerRepository();
    try {
      if (opportunity.id.isNotEmpty && !opportunity.id.startsWith('opp-')) {
        await workerRepo.rejectOpportunity(opportunity.id);
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Opportunity Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isRefreshing ? null : _fetchOpportunity,
            tooltip: 'Refresh',
          ),
          if (opportunity.isEmergency)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'EMERGENCY',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOpportunity,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
          // Conflict Warning Banner if any
          if (opportunity.hasScheduleConflict) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Schedule Conflict Detected',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'This slot overlaps with another scheduled commitment. Review before accepting.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text.withValues(alpha: 0.8),
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

          if (opportunity.isEmergency) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.danger),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🚨 Priority Emergency Dispatch',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.danger,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Immediate arrival requested by customer. Emergency priority rates apply.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (opportunity.gigType == 'VISITATION' ||
              opportunity.category == 'VISITATION' ||
              opportunity.title.toLowerCase().contains('visit')) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.home_repair_service_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Site Visit & Diagnostic Inspection',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Guaranteed ₹100 visit charge. Inspect on-site and propose repair tasks to the customer.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Title & Category
          Text(
            opportunity.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  opportunity.category,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                opportunity.distance,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Exact Wage Display (SRS: No worker bidding)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fixed Guaranteed Wage',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Cooperative Tariff',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      opportunity.wage,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'net payout',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
                const Divider(height: 20),
                const Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cooperative Rate · 0% commission deducted',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Schedule & Location
          SurfaceCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Timing & Duration',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_available_rounded, size: 15, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                opportunity.scheduleDisplay,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 15, color: AppColors.muted),
                            const SizedBox(width: 6),
                            Text(
                              'Estimated Duration: ${opportunity.duration}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Location',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opportunity.location),
                      Builder(
                        builder: (context) {
                          final hasMapsLink = opportunity.googleMapsLink != null &&
                              opportunity.googleMapsLink!.isNotEmpty;
                          final mapUrl = hasMapsLink
                              ? opportunity.googleMapsLink!
                              : (opportunity.latitude != null &&
                                      opportunity.longitude != null
                                  ? PickedLocation.generateGoogleMapsLink(
                                      opportunity.latitude!, opportunity.longitude!)
                                  : (opportunity.location.isNotEmpty &&
                                          opportunity.location != 'Customer location'
                                      ? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(opportunity.location)}'
                                      : null));

                          if (mapUrl == null) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: InkWell(
                              onTap: () => launchGoogleMaps(context, mapUrl),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.map_rounded,
                                        size: 14, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Open in Google Maps',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Description & Scope
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Work Description',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  opportunity.description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Customer Instructions',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  opportunity.instructions,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Materials Responsibility
          SurfaceCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Materials Responsibility',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        opportunity.materials,
                        style: const TextStyle(
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
        ],
      ),
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
        child: _buildBottomActions(context),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final status = opportunity.status.toUpperCase();

    if (status == 'ACCEPTED') {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: () {
            final job = WorkerJob.fromOpportunity(
              opportunity,
              status: WorkerJobStatus.awaitingSelection,
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => WorkerActiveJobScreen(job: job),
              ),
            );
          },
          icon: const Icon(Icons.hourglass_top_rounded),
          label: const Text(
            'You Accepted This Gig · View Workspace',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      );
    }

    if (status == 'NOT_SELECTED') {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.info_outline_rounded),
          label: const Text(
            'Customer Selected Another Worker · Back',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      );
    }

    if (status == 'REJECTED') {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          label: const Text(
            'Opportunity Declined · Back',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      );
    }

    if (status == 'EXPIRED' || status == 'CANCELLED') {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.block_rounded),
          label: const Text(
            'Gig Closed or Expired · Back',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      );
    }

    // Default / PENDING status: worker can accept or decline
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleDecline(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Decline'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: () => _handleAccept(context),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text(
              'Accept Gig',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),
      ],
    );
  }
}
