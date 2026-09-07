import 'package:flutter/material.dart';

import '../../../models/worker_job_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class MultiWorkerInviteScreen extends StatefulWidget {
  const MultiWorkerInviteScreen({super.key, required this.job});

  final WorkerJob job;

  @override
  State<MultiWorkerInviteScreen> createState() =>
      _MultiWorkerInviteScreenState();
}

class _MultiWorkerInviteScreenState extends State<MultiWorkerInviteScreen> {
  JoinRoleType _selectedRole = JoinRoleType.equalSharing;
  String? _selectedWorkerId;
  final TextEditingController _noteController = TextEditingController();

  final List<Map<String, dynamic>> _eligibleWorkers = [
    {
      'id': 'w-1',
      'name': 'Suresh Kumar',
      'roleBadge': 'Rookie Apprentice',
      'rating': '4.7',
      'experience': '6 mentored gigs completed',
      'distance': '1.4 km away',
      'isRookie': true,
    },
    {
      'id': 'w-2',
      'name': 'Manoj Verma',
      'roleBadge': 'Certified Senior Worker',
      'rating': '4.9',
      'experience': '5 years experience · 180+ gigs',
      'distance': '2.6 km away',
      'isRookie': false,
    },
    {
      'id': 'w-3',
      'name': 'Priya Sundaram',
      'roleBadge': 'Certified Worker',
      'rating': '4.8',
      'experience': '3 years experience · 94 gigs',
      'distance': '3.1 km away',
      'isRookie': false,
    },
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _sendInvite() {
    if (_selectedWorkerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cooperative worker to invite.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final worker = _eligibleWorkers.firstWhere(
      (w) => w['id'] == _selectedWorkerId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Invitation sent to ${worker['name']} as ${_selectedRole.label}!',
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Invite Co-Worker',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // Job Summary Banner
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.job.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.job.when} · Fixed Wage: ${widget.job.wage}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Role Classification (SRS 16.2)
          const SectionTitle('Select Collaboration Type (SRS 16.2)'),
          const SizedBox(height: 8),

          InkWell(
            onTap: () =>
                setState(() => _selectedRole = JoinRoleType.equalSharing),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedRole == JoinRoleType.equalSharing
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surface,
                border: Border.all(
                  color: _selectedRole == JoinRoleType.equalSharing
                      ? AppColors.primary
                      : AppColors.border,
                  width: _selectedRole == JoinRoleType.equalSharing ? 1.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _selectedRole == JoinRoleType.equalSharing
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: _selectedRole == JoinRoleType.equalSharing
                        ? AppColors.primary
                        : AppColors.muted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Equal Sharing (50/50 Split)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'For experienced co-workers. Total wage is distributed equally between both verified workers.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _selectedRole = JoinRoleType.rookie),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedRole == JoinRoleType.rookie
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surface,
                border: Border.all(
                  color: _selectedRole == JoinRoleType.rookie
                      ? AppColors.primary
                      : AppColors.border,
                  width: _selectedRole == JoinRoleType.rookie ? 1.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _selectedRole == JoinRoleType.rookie
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: _selectedRole == JoinRoleType.rookie
                        ? AppColors.primary
                        : AppColors.muted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rookie Mentorship (Learning Track)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Rookie receives 0.5 cooperative job credits and assists you. Full wage is retained by lead technician.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Worker Selection List
          const SectionTitle('Available Cooperative Workers Nearby'),
          const SizedBox(height: 8),

          ..._eligibleWorkers.map((worker) {
            final isSelected = _selectedWorkerId == worker['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedWorkerId = worker['id'] as String;
                    if (worker['isRookie'] == true) {
                      _selectedRole = JoinRoleType.rookie;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.1),
                        foregroundColor: isSelected
                            ? Colors.white
                            : AppColors.primary,
                        child: Text(
                          (worker['name'] as String).substring(0, 1),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  worker['name'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              worker['roleBadge'] as String,
                              style: TextStyle(
                                color: worker['isRookie'] == true
                                    ? AppColors.primaryDark
                                    : AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${worker['experience']} · ${worker['distance']}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected ? AppColors.primary : AppColors.muted,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Notes / Instructions
          const Text(
            'Special Note / Instructions (Optional)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'e.g. Bring extra 14-inch pipe wrench and extension ladder...',
              hintStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _sendInvite,
            icon: const Icon(Icons.send_rounded),
            label: const Text(
              'Send Collaboration Invitation',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
