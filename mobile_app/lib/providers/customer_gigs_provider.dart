import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api/api_models.dart';
import '../models/customer_gig_workflow.dart';
import '../repositories/gig_repository.dart';

class CustomerGigsState {
  final List<CustomerGig> activeGigs;
  final List<CustomerGig> completedGigs;
  final bool isLoading;
  final String? errorMessage;

  const CustomerGigsState({
    this.activeGigs = const [],
    this.completedGigs = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// All non-cancelled gigs
  List<CustomerGig> get allGigs => [...activeGigs, ...completedGigs];

  /// Gigs currently seeking workers or actively executing (non-scheduled)
  List<CustomerGig> get activeNow =>
      activeGigs.where((g) => g.stage != GigStage.scheduled).toList();

  /// Gigs booked for a future scheduled time slot
  List<CustomerGig> get upcoming =>
      activeGigs.where((g) => g.stage == GigStage.scheduled).toList();

  /// Total count of open/active gigs
  int get activeCount => activeGigs.length;

  CustomerGigsState copyWith({
    List<CustomerGig>? activeGigs,
    List<CustomerGig>? completedGigs,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CustomerGigsState(
      activeGigs: activeGigs ?? this.activeGigs,
      completedGigs: completedGigs ?? this.completedGigs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class CustomerGigsNotifier extends Notifier<CustomerGigsState> {
  final GigRepository _gigRepo = GigRepository();

  @override
  CustomerGigsState build() {
    Future.microtask(() => loadGigs());
    return const CustomerGigsState(isLoading: true);
  }

  Future<void> loadGigs({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final gigsResp = await _gigRepo.getCustomerGigs(pageSize: 50);
      final active = <CustomerGig>[];
      final completed = <CustomerGig>[];

      for (final dto in gigsResp.data) {
        final status = dto.status.toUpperCase();
        List<GigCandidateDto> candDtos = [];
        if (dto.selectedWorkerId == null &&
            status != 'COMPLETED' &&
            status != 'CANCELLED') {
          try {
            candDtos = await _gigRepo.getCandidates(dto.id);
          } catch (_) {}
        }

        final candidates = candDtos
            .map((c) => GigCandidate.fromDto(c, categoryName: dto.categoryName))
            .toList();
        final gig = CustomerGig.fromDto(dto, candidates: candidates);

        final isCancelled =
            gig.stage == GigStage.cancelled || status == 'CANCELLED';
        final isCompleted = gig.stage == GigStage.completed ||
            status == 'COMPLETED' ||
            status == 'PAYMENT_WORKER_CONFIRMED' ||
            status == 'GIG_COMPLETED';

        if (isCancelled) {
          continue;
        } else if (isCompleted) {
          completed.add(gig);
        } else {
          active.add(gig);
        }
      }

      state = state.copyWith(
        activeGigs: active,
        completedGigs: completed,
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

  Future<void> refreshSilently() => loadGigs(silent: true);

  Future<void> cancelGig({
    required String gigId,
    required String reason,
  }) async {
    await _gigRepo.cancelGig(gigId: gigId, reason: reason);
    await loadGigs(silent: true);
  }

  Future<void> selectWorker({
    required String gigId,
    required String workerId,
  }) async {
    await _gigRepo.selectWorker(gigId: gigId, workerId: workerId);
    await loadGigs(silent: true);
  }
}

final customerGigsProvider =
    NotifierProvider<CustomerGigsNotifier, CustomerGigsState>(
  () => CustomerGigsNotifier(),
);
