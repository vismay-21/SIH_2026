import 'package:flutter/material.dart';

import '../../../models/customer_gig_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../gig_details_screen.dart';

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
                  _GigList(filter: _GigFilter.active),
                  _GigList(filter: _GigFilter.upcoming),
                  _GigList(filter: _GigFilter.completed),
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

class _GigList extends StatelessWidget {
  const _GigList({required this.filter});

  final _GigFilter filter;

  @override
  Widget build(BuildContext context) {
    final gigs = demoGigs.where((gig) {
      return switch (filter) {
        _GigFilter.active =>
          gig.stage.index >= GigStage.responding.index &&
              gig.stage.index < GigStage.completed.index,
        _GigFilter.upcoming => gig.stage == GigStage.scheduled,
        _GigFilter.completed => gig.stage == GigStage.completed,
      };
    }).toList();

    if (gigs.isEmpty) {
      return const Center(child: Text('No gigs in this list.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      itemCount: gigs.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _GigListTile(gig: gigs[index]),
    );
  }
}

class _GigListTile extends StatelessWidget {
  const _GigListTile({required this.gig});

  final CustomerGig gig;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => GigDetailsScreen(gig: gig))),
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
                Text(
                  gig.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  gig.category,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '${gig.stage.label} · ${gig.when}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    ),
  );
}
