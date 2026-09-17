import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api/api_models.dart';
import '../models/api/api_response.dart';
import '../models/worker_job_workflow.dart';
import '../repositories/worker_repository.dart';

class WorkerJobsState {
  final List<WorkerJob> activeJobs;
  final List<WorkerJob> upcomingJobs;
  final List<WorkerJob> completedJobs;
  final List<WorkerJob> awaitingSelectionJobs;
  final bool isLoading;
  final String? errorMessage;

  const WorkerJobsState({
    this.activeJobs = const [],
    this.upcomingJobs = const [],
    this.completedJobs = const [],
    this.awaitingSelectionJobs = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// The single prioritized active/upcoming job for the home screen header.
  WorkerJob? get currentJob {
    final active = activeJobs.where((j) => j.status != WorkerJobStatus.cancelled);
    if (active.isNotEmpty) return active.first;
    final upcoming = upcomingJobs.where((j) => j.status != WorkerJobStatus.cancelled);
    if (upcoming.isNotEmpty) return upcoming.first;
    final awaiting = awaitingSelectionJobs.where((j) => j.status != WorkerJobStatus.cancelled);
    if (awaiting.isNotEmpty) return awaiting.first;
    return null;
  }

  /// All non-completed active & scheduled jobs unified for My Jobs Tab 0.
  List<WorkerJob> get allActiveAndScheduled {
    return [...upcomingJobs, ...activeJobs, ...awaitingSelectionJobs]
        .where((j) => j.status != WorkerJobStatus.cancelled)
        .toList();
  }

  WorkerJobsState copyWith({
    List<WorkerJob>? activeJobs,
    List<WorkerJob>? upcomingJobs,
    List<WorkerJob>? completedJobs,
    List<WorkerJob>? awaitingSelectionJobs,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WorkerJobsState(
      activeJobs: activeJobs ?? this.activeJobs,
      upcomingJobs: upcomingJobs ?? this.upcomingJobs,
      completedJobs: completedJobs ?? this.completedJobs,
      awaitingSelectionJobs:
          awaitingSelectionJobs ?? this.awaitingSelectionJobs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class WorkerJobsNotifier extends Notifier<WorkerJobsState> {
  final WorkerRepository _workerRepo = WorkerRepository();

  @override
  WorkerJobsState build() {
    // Initial fetch on mount
    Future.microtask(() => loadJobs());
    return const WorkerJobsState(isLoading: true);
  }

  Future<void> loadJobs({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final results = await Future.wait([
        _workerRepo
            .getWorkerGigs(tab: 'active')
            .then((r) => r.data.map(WorkerJob.fromDto).toList())
            .catchError((_) => <WorkerJob>[]),
        _workerRepo
            .getWorkerGigs(tab: 'upcoming')
            .then((r) => r.data.map(WorkerJob.fromDto).toList())
            .catchError((_) => <WorkerJob>[]),
        _workerRepo
            .getWorkerGigs(tab: 'completed')
            .then((r) => r.data.map(WorkerJob.fromDto).toList())
            .catchError((_) => <WorkerJob>[]),
        _workerRepo
            .getOpportunities(status: 'ACCEPTED')
            .then((r) => r.data)
            .catchError((_) => <OpportunityDto>[]),
      ]);

      final active = (results[0] as List<WorkerJob>)
          .where((j) => j.status != WorkerJobStatus.cancelled)
          .toList();
      final upcoming = (results[1] as List<WorkerJob>)
          .where((j) => j.status != WorkerJobStatus.cancelled)
          .toList();
      final completed = results[2] as List<WorkerJob>;
      final acceptedOpps = (results[3] as List<OpportunityDto>)
          .where((o) => o.status.toUpperCase() == 'ACCEPTED')
          .toList();

      final assignedGigIds = {
        ...active.map((j) => j.gigId ?? j.id),
        ...upcoming.map((j) => j.gigId ?? j.id),
        ...completed.map((j) => j.gigId ?? j.id),
      };

      final awaiting = <WorkerJob>[];
      for (final dto in acceptedOpps) {
        if (dto.status.toUpperCase() != 'ACCEPTED') continue;
        final gId = dto.gigId;
        if (!assignedGigIds.contains(gId)) {
          awaiting.add(
            WorkerJob.fromOpportunity(
              WorkerOpportunity.fromDto(dto),
              status: WorkerJobStatus.awaitingSelection,
            ),
          );
        }
      }

      state = state.copyWith(
        activeJobs: active,
        upcomingJobs: upcoming,
        completedJobs: completed,
        awaitingSelectionJobs: awaiting,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> startWork(String gigId) async {
    await _workerRepo.startWork(gigId);
    await loadJobs(silent: true);
  }
}

final workerJobsProvider =
    NotifierProvider<WorkerJobsNotifier, WorkerJobsState>(
  () => WorkerJobsNotifier(),
);

// ============================================================================
// WORKER OPPORTUNITIES PROVIDER
// ============================================================================

class WorkerOpportunitiesState {
  final List<WorkerOpportunity> opportunities;
  final bool isLoading;
  final String? errorMessage;

  const WorkerOpportunitiesState({
    this.opportunities = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  WorkerOpportunitiesState copyWith({
    List<WorkerOpportunity>? opportunities,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WorkerOpportunitiesState(
      opportunities: opportunities ?? this.opportunities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class WorkerOpportunitiesNotifier extends Notifier<WorkerOpportunitiesState> {
  final WorkerRepository _workerRepo = WorkerRepository();

  @override
  WorkerOpportunitiesState build() {
    Future.microtask(() => loadOpportunities());
    return const WorkerOpportunitiesState(isLoading: true);
  }

  Future<void> loadOpportunities({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final oppResp = await _workerRepo
          .getOpportunities(pageSize: 20)
          .catchError(
            (_) => PaginatedResponse<OpportunityDto>(
              data: [],
              pagination: const PaginationMeta(
                total: 0,
                page: 1,
                pageSize: 20,
                totalPages: 0,
              ),
            ),
          );

      const hiddenStatuses = {
        'ACCEPTED',
        'REJECTED',
        'NOT_SELECTED',
        'EXPIRED',
        'CANCELLED'
      };

      final opps = oppResp.data
          .map((d) => WorkerOpportunity.fromDto(d))
          .where((o) => !hiddenStatuses.contains(o.status.toUpperCase()))
          .toList();

      state = state.copyWith(
        opportunities: opps,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> accept(String oppId) async {
    await _workerRepo.acceptOpportunity(oppId);
    // Refresh both opportunities and jobs
    await loadOpportunities(silent: true);
    ref.read(workerJobsProvider.notifier).loadJobs(silent: true);
  }

  Future<void> decline(String oppId) async {
    await _workerRepo.rejectOpportunity(oppId);
    await loadOpportunities(silent: true);
  }
}

final workerOpportunitiesProvider =
    NotifierProvider<WorkerOpportunitiesNotifier, WorkerOpportunitiesState>(
  () => WorkerOpportunitiesNotifier(),
);
