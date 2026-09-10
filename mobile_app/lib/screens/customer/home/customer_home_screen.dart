import 'package:flutter/material.dart';

import '../../../models/customer_gig_workflow.dart';
import '../../../repositories/gig_repository.dart';
import '../../../services/token_storage.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../customer_main_screen.dart';
import '../profile/customer_account_screens.dart';
import 'create_gig_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _gigRepo = GigRepository();
  List<CustomerGig> _gigs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final paginated = await _gigRepo.getCustomerGigs(pageSize: 50);
      final mapped = await Future.wait(paginated.data.map((dto) async {
        List<GigCandidate> candidates = [];
        final status = dto.status.toUpperCase();
        if (dto.selectedWorkerId == null &&
            status != 'COMPLETED' &&
            status != 'CANCELLED') {
          try {
            final cDtos = await _gigRepo.getCandidates(dto.id);
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = TokenStorage.instance.currentUser;
    final displayName = (user?.fullName != null && user!.fullName!.trim().isNotEmpty)
        ? user.fullName!.trim().split(' ').first
        : 'Customer';

    final activeGigs = _gigs.where((g) => g.stage != GigStage.completed).toList();
    final activeCount = activeGigs.length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            // Top Header with Dynamic Name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Good morning,',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const CustomerMainScreen(initialIndex: 2),
                    ),
                  ),
                  icon: const Icon(Icons.notifications_none_rounded, size: 27),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hero Banner with Merged Active Gigs & Create Gig
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fair matching for household work',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Workers see exact wages. You choose from accepted candidates.',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CreateGigScreen(),
                            ),
                          ).then((_) => _loadData()),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create a gig'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => Navigator.of(context, rootNavigator: true)
                            .pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const CustomerMainScreen(initialIndex: 1),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.assignment_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$activeCount Active',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Active and Upcoming Section Title
            SectionTitle(
              'Active and upcoming',
              action: activeGigs.isNotEmpty ? 'View all' : null,
              onAction: () =>
                  Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const CustomerMainScreen(initialIndex: 1),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Real Gigs List or Clean Empty State
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (activeGigs.isEmpty)
              SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 20,
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        size: 44,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No active gigs',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Post a household repair task to get matched with skilled cooperative artisans.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...activeGigs.map(
                (gig) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GigCard(
                    gig: gig,
                    onRefresh: _loadData,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GigCard extends StatelessWidget {
  const _GigCard({
    required this.gig,
    this.onRefresh,
  });

  final CustomerGig gig;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final statusText = gig.candidates.isNotEmpty && gig.selectedWorker == null
        ? '${gig.candidates.length} worker${gig.candidates.length == 1 ? '' : 's'} interested'
        : gig.stage.label;

    return SurfaceCard(
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
                      gig.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      gig.category,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              gig.isEmergency
                  ? _EmergencyBadge(statusText)
                  : StatusPill(statusText, warning: false),
            ],
          ),
          if (gig.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              gig.description,
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
          ],
          const SizedBox(height: 13),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetaChip(icon: Icons.calendar_today_outlined, text: gig.when),
              const SizedBox(height: 7),
              _MetaChip(icon: Icons.location_on_outlined, text: gig.location),
              const SizedBox(height: 7),
              _MetaChip(
                icon: Icons.schedule_outlined,
                text: 'Estimated · ${gig.duration}',
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context, rootNavigator: true)
                      .pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => CustomerMainScreen(
                        initialIndex: 1,
                        initialGig: gig,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.timeline_rounded, size: 16),
                  label: const Text('Track job'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: gig.chatEnabled
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CustomerChatThreadScreen(
                            workerName:
                                gig.selectedWorker?.name ?? 'Assigned Worker',
                            jobTitle: gig.title,
                            enabled: gig.chatEnabled,
                          ),
                        ),
                      )
                    : null,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: Text(
                  gig.chatEnabled ? 'Chat' : 'Chat after selection',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmergencyBadge extends StatelessWidget {
  const _EmergencyBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.12),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.45)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.danger,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    ),
  );
}
