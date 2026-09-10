import 'package:flutter/material.dart';

import '../../../models/worker_job_workflow.dart';
import '../../../repositories/worker_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import 'rookie_progression_screen.dart';
import 'worker_active_job_screen.dart';

class WorkerNavigation3Screen extends StatefulWidget {
  const WorkerNavigation3Screen({super.key});

  @override
  State<WorkerNavigation3Screen> createState() =>
      _WorkerNavigation3ScreenState();
}

class _WorkerNavigation3ScreenState extends State<WorkerNavigation3Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _workerRepo = WorkerRepository();

  List<WorkerJob> _activeAndScheduled = [];
  List<WorkerJob> _completedJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch assigned active and upcoming gigs
      final activeResp = await _workerRepo.getWorkerGigs(tab: 'active');
      final upcomingResp = await _workerRepo.getWorkerGigs(tab: 'upcoming');
      final completedResp = await _workerRepo.getWorkerGigs(tab: 'completed');

      final activeJobs = activeResp.data.map(WorkerJob.fromDto).toList();
      final upcomingJobs = upcomingResp.data.map(WorkerJob.fromDto).toList();
      final completedJobs = completedResp.data.map(WorkerJob.fromDto).toList();

      // 2. Fetch accepted opportunities currently awaiting customer selection
      List<WorkerJob> awaitingJobs = [];
      try {
        final oppResp = await _workerRepo.getOpportunities(status: 'ACCEPTED');
        awaitingJobs = oppResp.data
            .map((dto) => WorkerJob.fromOpportunity(
                  WorkerOpportunity.fromDto(dto),
                  status: WorkerJobStatus.awaitingSelection,
                ))
            .toList();
      } catch (_) {}

      final allActive = [...awaitingJobs, ...activeJobs, ...upcomingJobs];

      if (!mounted) return;
      setState(() {
        _activeAndScheduled = allActive;
        _completedJobs = completedJobs;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Jobs',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
          ),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            tabs: [
              Tab(text: 'Active & Upcoming (${_activeAndScheduled.length})'),
              Tab(text: 'Completed (${_completedJobs.length})'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Rookie Badges Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RookieProgressionScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.school_rounded,
                              size: 18,
                              color: AppColors.primaryDark,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cooperative Artisan Growth & Rookie Track',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.primaryDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Tab Views
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadJobs,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildJobList(_activeAndScheduled, isCompletedTab: false),
                          _buildJobList(_completedJobs, isCompletedTab: true),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobList(List<WorkerJob> jobs, {required bool isCompletedTab}) {
    if (jobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 60),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    isCompletedTab
                        ? Icons.history_rounded
                        : Icons.work_history_outlined,
                    size: 44,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isCompletedTab
                        ? 'No completed gigs yet'
                        : 'No active or upcoming gigs',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCompletedTab
                        ? 'Gigs you complete will appear here with proof of payment.'
                        : 'Accept opportunities from the feed to begin work.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = jobs[index];
        final isCompleted = job.status == WorkerJobStatus.completed;

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => WorkerActiveJobScreen(job: job),
              ),
            ).then((_) => _loadJobs());
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
                      child: Text(
                        job.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    StatusPill(job.status.label),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${job.category} · Customer: ${job.customerName}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.when,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      job.wage,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isCompleted
                            ? AppColors.muted
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (job.additionalWorkerName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'With: ${job.additionalWorkerName}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
