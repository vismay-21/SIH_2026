import 'package:flutter/material.dart';

import '../../../models/worker_job_workflow.dart';
import '../../../repositories/worker_repository.dart';
import '../../../services/token_storage.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../../common/notifications_screen.dart';
import '../my_jobs/worker_active_job_screen.dart';
import '../opportunities/opportunity_details_screen.dart';
import '../profile/worker_availability_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key, this.onSelectTab});

  final ValueChanged<int>? onSelectTab;

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final _workerRepo = WorkerRepository();

  bool _isAvailable = true;
  List<WorkerOpportunity> _opportunities = [];
  WorkerJob? _currentJob;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final oppResp = await _workerRepo.getOpportunities();
      final opps = oppResp.data
          .map((d) => WorkerOpportunity.fromDto(d))
          .where((o) => o.status != 'ACCEPTED' && o.status != 'REJECTED')
          .toList();

      WorkerJob? activeJob;
      try {
        final gigsResp = await _workerRepo.getWorkerGigs(tab: 'active');
        if (gigsResp.data.isNotEmpty) {
          activeJob = WorkerJob.fromDto(gigsResp.data.first);
        } else {
          final upResp = await _workerRepo.getWorkerGigs(tab: 'upcoming');
          if (upResp.data.isNotEmpty) {
            activeJob = WorkerJob.fromDto(upResp.data.first);
          }
        }
      } catch (_) {
        // Gigs list fallback
      }

      if (!mounted) return;
      setState(() {
        _opportunities = opps;
        _currentJob = activeJob;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = TokenStorage.instance.currentUser;
    final workerName = user?.fullName ?? 'Worker';

    final oppsToDisplay = _opportunities;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your work, your choice',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Namaste, $workerName',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_none_rounded, size: 27),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Availability Status Card (SRS 10.1)
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WorkerAvailabilityScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: SurfaceCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isAvailable
                            ? AppColors.success.withValues(alpha: 0.13)
                            : AppColors.muted.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isAvailable
                            ? Icons.check_circle_outline_rounded
                            : Icons.do_not_disturb_on_outlined,
                        color:
                            _isAvailable ? AppColors.success : AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isAvailable
                                ? 'You are available'
                                : 'You are off-duty',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isAvailable
                                ? 'Tap to manage weekly hours (SRS 10.1)'
                                : 'Toggle on to receive eligible opportunities',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAvailable,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _isAvailable = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              val
                                  ? 'Status set to Available.'
                                  : 'Status set to Off-Duty.',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                StatTile(
                  icon: Icons.explore_outlined,
                  value: '${_opportunities.length}',
                  label: 'New opportunities',
                ),
                const SizedBox(width: 10),
                StatTile(
                  icon: Icons.work_outline_rounded,
                  value: _currentJob != null ? '1' : '0',
                  label: 'Current job',
                ),
                const SizedBox(width: 10),
                const StatTile(
                  icon: Icons.star_outline_rounded,
                  value: '4.8',
                  label: 'Quality score',
                ),
              ],
            ),

            const SizedBox(height: 22),
            SectionTitle(
              'New opportunities',
              action: 'See all',
              onAction: () => widget.onSelectTab?.call(1),
            ),
            const SizedBox(height: 8),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (oppsToDisplay.isEmpty)
              const SurfaceCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 36,
                          color: AppColors.muted,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No new opportunities nearby',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'New customer requests matching your skills will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...oppsToDisplay.take(2).map((opp) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      widget.onSelectTab?.call(1);
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              OpportunityDetailsScreen(opportunity: opp),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opp.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      opp.category,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusPill(
                                opp.isEmergency ? 'Emergency' : 'Eligible',
                                warning: opp.isEmergency,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                size: 17,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                opp.wage,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                opp.when,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                opp.distance,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Details →',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 18),
            const SectionTitle('Upcoming / Current job'),
            const SizedBox(height: 8),

            if (_currentJob != null)
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => WorkerActiveJobScreen(job: _currentJob!),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: SurfaceCard(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.handyman_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentJob!.title,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_currentJob!.when} · ${_currentJob!.wage}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusPill(_currentJob!.status.label),
                    ],
                  ),
                ),
              )
            else
              const SurfaceCard(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'No active job right now. Accept an opportunity above to start.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
