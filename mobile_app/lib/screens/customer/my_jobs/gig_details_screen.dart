import 'package:flutter/material.dart';

import '../../../models/customer_gig_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../home/emergency_tip_screen.dart';
import 'accepted_candidates_screen.dart';
import 'active_job_screen.dart';
import 'cancel_gig_screen.dart';
import 'material_bill_viewer_screen.dart';
import 'reschedule_gig_screen.dart';
import 'review_worker_screen.dart';
import 'waiting_for_candidates_screen.dart';

class GigDetailsScreen extends StatelessWidget {
  const GigDetailsScreen({super.key, required this.gig});

  final CustomerGig gig;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gig details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gig.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      gig.category,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusPill(gig.stage.label, warning: gig.isEmergency),
            ],
          ),
          const SizedBox(height: 18),
          _GigStageTracker(current: gig.stage),
          const SizedBox(height: 18),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gig.description, style: const TextStyle(height: 1.35)),
                const SizedBox(height: 14),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  value: gig.when,
                ),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  value: gig.location,
                ),
                _DetailRow(icon: Icons.schedule_outlined, value: gig.duration),
                _DetailRow(
                  icon: Icons.shopping_cart_outlined,
                  value: gig.materials,
                ),
                _DetailRow(
                  icon: Icons.info_outline_rounded,
                  value: gig.instructions,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Next actions'),
          const SizedBox(height: 8),
          if (gig.stage == GigStage.seeking || gig.candidates.isEmpty) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'No workers accepted yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No worker has responded to this gig request so far. You can add a voluntary tip incentive to increase acceptance speed and re-notify nearby workers.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => EmergencyTipScreen(gig: gig),
                        ),
                      ),
                      icon: const Icon(
                        Icons.volunteer_activism_rounded,
                        size: 18,
                      ),
                      label: const Text('Add tip incentive & re-notify'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _ActionRow(
              icon: Icons.radar_rounded,
              title: 'Waiting for candidates',
              subtitle: 'Track worker broadcast & response window',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WaitingForCandidatesScreen(gig: gig),
                ),
              ),
            ),
          ],
          if (gig.stage == GigStage.accepted ||
              gig.stage == GigStage.responding)
            _ActionRow(
              icon: Icons.people_alt_outlined,
              title: 'Accepted candidates',
              subtitle: '${gig.candidates.length} workers to review',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AcceptedCandidatesScreen(gig: gig),
                ),
              ),
            ),
          if (gig.selectedWorker != null) ...[
            _ActionRow(
              icon: Icons.work_history_outlined,
              title: 'Active job workspace',
              subtitle: 'Details, chat, status, and completion evidence',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ActiveJobScreen(gig: gig),
                ),
              ),
            ),
            _ActionRow(
              icon: Icons.receipt_long_outlined,
              title: 'View material bill / proof',
              subtitle: gig.materials,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MaterialBillViewerScreen(),
                ),
              ),
            ),
          ],
          if (gig.stage == GigStage.completed)
            _ActionRow(
              icon: Icons.rate_review_outlined,
              title: 'Review worker',
              subtitle: 'Provide structured 3-4 MCQ feedback',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReviewWorkerScreen(
                    workerName: gig.selectedWorker?.name ?? 'Worker',
                    gigTitle: gig.title,
                  ),
                ),
              ),
            ),
          if (gig.stage != GigStage.completed) ...[
            _ActionRow(
              icon: Icons.edit_calendar_rounded,
              title: 'Request rescheduling',
              subtitle: 'Select new date or time for this gig',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RescheduleGigScreen(gig: gig),
                ),
              ),
            ),
            _ActionRow(
              icon: Icons.cancel_outlined,
              title: 'Cancel gig',
              subtitle: 'View cancellation policy & cancel request',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CancelGigScreen(gig: gig),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GigStageTracker extends StatelessWidget {
  const _GigStageTracker({required this.current});

  final GigStage current;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Job status', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        ...GigStage.values.map(
          (stage) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 18,
                child: Column(
                  children: [
                    Icon(
                      stage.index <= current.index
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: stage.index <= current.index
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    if (stage != GigStage.values.last)
                      Container(
                        width: 2,
                        height: 25,
                        color: stage.index < current.index
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 1, bottom: 11),
                child: Text(
                  stage.label,
                  style: TextStyle(
                    color: stage == current
                        ? AppColors.primary
                        : AppColors.text,
                    fontWeight: stage == current
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: const TextStyle(height: 1.3))),
      ],
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SurfaceCard(
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );
}
