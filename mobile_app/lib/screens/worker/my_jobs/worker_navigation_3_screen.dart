import 'package:flutter/material.dart';

import '../../../models/worker_job_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import 'incoming_join_request_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeAndScheduled = demoWorkerJobs
        .where((j) => j.status != WorkerJobStatus.completed)
        .toList();
    final completedJobs = demoWorkerJobs
        .where((j) => j.status == WorkerJobStatus.completed)
        .toList();

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
              Tab(text: 'Active & Upcoming (${activeAndScheduled.length})'),
              Tab(text: 'Completed (${completedJobs.length})'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Collaboration & Rookie Badges Bar
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
                            builder: (_) => IncomingJoinRequestScreen(
                              request: demoJoinRequests.first,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.handshake_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '2 Join Requests',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.school_rounded,
                              size: 16,
                              color: AppColors.primaryDark,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Rookie Track (3.0 cr)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
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
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildJobList(activeAndScheduled),
                  _buildJobList(completedJobs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobList(List<WorkerJob> jobs) {
    if (jobs.isEmpty) {
      return const Center(
        child: Text(
          'No gigs in this category.',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return ListView.separated(
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
