import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/customer_gig_workflow.dart';
import '../../../providers/customer_gigs_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../../../widgets/common/skeleton_loaders.dart';
import 'gig_details_screen.dart';

class CustomerNavigation2Screen extends ConsumerStatefulWidget {
  const CustomerNavigation2Screen({super.key, this.initialGig});

  final CustomerGig? initialGig;

  @override
  ConsumerState<CustomerNavigation2Screen> createState() =>
      _CustomerNavigation2ScreenState();
}

enum _GigFilter { activeUpcoming, completed }

class _CustomerNavigation2ScreenState extends ConsumerState<CustomerNavigation2Screen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _pollingTimer;
  bool _openedInitialGig = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        ref.read(customerGigsProvider.notifier).loadGigs(silent: true);
      }
    });
    _startPeriodicPolling();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialGig != null && !_openedInitialGig) {
      _openedInitialGig = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context)
              .push(
                MaterialPageRoute<void>(
                  builder: (_) => GigDetailsScreen(gig: widget.initialGig!),
                ),
              )
              .then((_) => ref.read(customerGigsProvider.notifier).loadGigs(silent: true));
        }
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startPeriodicPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      final gigsState = ref.read(customerGigsProvider);
      final hasActiveTransition = gigsState.allGigs.any((g) =>
          g.stage == GigStage.payment ||
          g.stage == GigStage.completionRequested ||
          g.stage == GigStage.selected ||
          g.rawStatus == 'PAYMENT_CUSTOMER_PAID');
      if (hasActiveTransition) {
        ref.read(customerGigsProvider.notifier).loadGigs(silent: true);
      }
    });
  }

  List<CustomerGig> _getFilteredGigs(CustomerGigsState state, _GigFilter filter) {
    return switch (filter) {
      _GigFilter.activeUpcoming => state.activeGigs,
      _GigFilter.completed => state.completedGigs,
    };
  }

  Widget _buildTabContent(CustomerGigsState state, _GigFilter filter) {
    final filtered = _getFilteredGigs(state, filter);

    if (state.isLoading && filtered.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: const [
          GigCardSkeleton(),
          GigCardSkeleton(),
          GigCardSkeleton(),
        ],
      );
    }

    if (state.errorMessage != null && filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.muted,
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.read(customerGigsProvider.notifier).loadGigs(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(customerGigsProvider.notifier).loadGigs(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Text(
                filter == _GigFilter.completed
                    ? 'No completed gigs yet.'
                    : 'No active or upcoming gigs currently.',
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(customerGigsProvider.notifier).loadGigs(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        itemCount: filtered.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _GigListTile(
          gig: filtered[index],
          onRefresh: () => ref.read(customerGigsProvider.notifier).loadGigs(silent: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gigsState = ref.watch(customerGigsProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My gigs',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () =>
                      ref.read(customerGigsProvider.notifier).loadGigs(),
                  tooltip: 'Refresh gigs',
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Track every gig from request to payment.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 18),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            tabs: [
              Tab(text: 'ACTIVE/UPCOMING (${gigsState.activeGigs.length})'),
              Tab(text: 'Completed (${gigsState.completedGigs.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(gigsState, _GigFilter.activeUpcoming),
                _buildTabContent(gigsState, _GigFilter.completed),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GigListTile extends StatelessWidget {
  const _GigListTile({required this.gig, this.onRefresh});

  final CustomerGig gig;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => GigDetailsScreen(gig: gig),
          ),
        )
        .then((_) => onRefresh?.call()),
    borderRadius: BorderRadius.circular(14),
    child: SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: gig.isEmergency
                ? AppColors.danger.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.12),
            foregroundColor: gig.isEmergency
                ? AppColors.danger
                : AppColors.primary,
            child: Icon(
              gig.isEmergency
                  ? Icons.warning_amber_rounded
                  : Icons.work_outline_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        gig.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      gig.priceDisplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  gig.category,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${gig.stage.label} · ${gig.when}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (gig.candidates.isNotEmpty && gig.selectedWorker == null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${gig.candidates.length} accepted',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    ),
  );
}
