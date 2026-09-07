import 'package:flutter/material.dart';

import '../../../models/worker_job_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import 'opportunity_details_screen.dart';

class WorkerNavigation2Screen extends StatefulWidget {
  const WorkerNavigation2Screen({super.key});

  @override
  State<WorkerNavigation2Screen> createState() =>
      _WorkerNavigation2ScreenState();
}

class _WorkerNavigation2ScreenState extends State<WorkerNavigation2Screen> {
  String _activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final filteredOpportunities = demoOpportunities.where((opp) {
      if (_activeFilter == 'Emergency') return opp.isEmergency;
      if (_activeFilter == 'Conflicts') return opp.hasScheduleConflict;
      return true;
    }).toList();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Opportunities',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
          ),
          automaticallyImplyLeading: false,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            const Text(
              'Guaranteed wages established by the cooperative. Zero bidding, zero commission.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Emergency', 'Conflicts'].map((filter) {
                  final isSelected = _activeFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.muted,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _activeFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            ...filteredOpportunities.map((opp) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
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
                              child: Text(
                                opp.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (opp.isEmergency)
                              const StatusPill('Emergency', warning: true)
                            else if (opp.hasScheduleConflict)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Conflict',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              )
                            else
                              const StatusPill('Eligible'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opp.category,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              opp.wage,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
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
                              'View Details →',
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
          ],
        ),
      ),
    );
  }
}
