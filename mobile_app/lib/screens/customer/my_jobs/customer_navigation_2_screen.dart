import 'package:flutter/material.dart';

import '../../../models/api/api_response.dart';
import '../../../models/customer_gig_workflow.dart';
import '../../../repositories/gig_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import 'gig_details_screen.dart';

class CustomerNavigation2Screen extends StatefulWidget {
  const CustomerNavigation2Screen({super.key, this.initialGig});

  final CustomerGig? initialGig;

  @override
  State<CustomerNavigation2Screen> createState() =>
      _CustomerNavigation2ScreenState();
}

class _CustomerNavigation2ScreenState extends State<CustomerNavigation2Screen> {
  bool _openedInitialGig = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialGig != null && !_openedInitialGig) {
      _openedInitialGig = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GigDetailsScreen(gig: widget.initialGig!),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
              child: Text(
                'My gigs',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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
            const TabBar(
              tabs: [
                Tab(text: 'Active'),
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _LiveGigList(filter: _GigFilter.active),
                  _LiveGigList(filter: _GigFilter.upcoming),
                  _LiveGigList(filter: _GigFilter.completed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _GigFilter { active, upcoming, completed }

class _LiveGigList extends StatefulWidget {
  const _LiveGigList({required this.filter});

  final _GigFilter filter;

  @override
  State<_LiveGigList> createState() => _LiveGigListState();
}

class _LiveGigListState extends State<_LiveGigList> {
  final _gigRepo = GigRepository();
  List<CustomerGig> _gigs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchGigs();
  }

  Future<void> _fetchGigs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final paginated = await _gigRepo.getCustomerGigs(pageSize: 50);
      final mapped = await Future.wait(paginated.data.map((dto) async {
        List<GigCandidate> candidates = [];
        final status = dto.status.toUpperCase();
        if (dto.selectedWorkerId == null &&
            status != 'COMPLETED' &&
            status != 'CANCELLED') {
          try {
            final cDtos = await _gigRepo
                .getCandidates(dto.id)
                .timeout(const Duration(seconds: 2));
            candidates = cDtos.map(GigCandidate.fromDto).toList();
          } catch (_) {}
        }
        return CustomerGig.fromDto(dto, candidates: candidates);
      }));

      if (!mounted) return;
      setState(() {
        _gigs = mapped;
        _isLoading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _fetchGigs,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _gigs.where((gig) {
      return switch (widget.filter) {
        _GigFilter.active =>
          gig.stage != GigStage.completed && gig.stage != GigStage.scheduled,
        _GigFilter.upcoming => gig.stage == GigStage.scheduled,
        _GigFilter.completed => gig.stage == GigStage.completed,
      };
    }).toList();

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchGigs,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Center(
              child: Text(
                'No gigs found in this category.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchGigs,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        itemCount: filtered.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _GigListTile(
          gig: filtered[index],
          onRefresh: _fetchGigs,
        ),
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
        .push(MaterialPageRoute<void>(builder: (_) => GigDetailsScreen(gig: gig)))
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
                    if (gig.price != null)
                      Text(
                        '₹${gig.price!.toInt()}',
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
