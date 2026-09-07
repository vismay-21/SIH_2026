import 'package:flutter/material.dart';

import '../../../models/worker_job_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class WorkerCancelRescheduleScreen extends StatefulWidget {
  const WorkerCancelRescheduleScreen({super.key, required this.job});

  final WorkerJob job;

  @override
  State<WorkerCancelRescheduleScreen> createState() =>
      _WorkerCancelRescheduleScreenState();
}

class _WorkerCancelRescheduleScreenState
    extends State<WorkerCancelRescheduleScreen> {
  bool _isReschedule = true;
  String _selectedReason = 'Unexpected vehicle breakdown';
  final TextEditingController _notesController = TextEditingController();
  DateTime _newDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _newTime = const TimeOfDay(hour: 10, minute: 0);

  final List<String> _reasons = [
    'Unexpected vehicle breakdown',
    'Medical emergency / Sudden illness',
    'Essential equipment or tool defect',
    'Dangerous conditions reported at location',
    'Other legitimate cooperative reason',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_isReschedule) {
      final formattedTime = _newTime.format(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reschedule proposal sent to ${widget.job.customerName} for ${_newDate.day}/${_newDate.month} at $formattedTime.',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gig "${widget.job.title}" cancelled. The cooperative dispatcher has been alerted.',
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isReschedule ? 'Reschedule Gig' : 'Cancel Gig',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // Mode Toggle
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Reschedule Request')),
                  selected: _isReschedule,
                  onSelected: (selected) {
                    if (selected) setState(() => _isReschedule = true);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Cancel Gig')),
                  selected: !_isReschedule,
                  onSelected: (selected) {
                    if (selected) setState(() => _isReschedule = false);
                  },
                  selectedColor: AppColors.danger.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Job Summary
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.job.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer: ${widget.job.customerName} · Current Slot: ${widget.job.when}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // If reschedule: Date/time pickers
          if (_isReschedule) ...[
            const SectionTitle('Proposed New Schedule'),
            const SizedBox(height: 8),
            SurfaceCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Proposed Date',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${_newDate.day}/${_newDate.month}/${_newDate.year}',
                    ),
                    trailing: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _newDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 14),
                          ),
                        );
                        if (picked != null) setState(() => _newDate = picked);
                      },
                      child: const Text('Select'),
                    ),
                  ),
                  const Divider(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Proposed Time',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(_newTime.format(context)),
                    trailing: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _newTime,
                        );
                        if (picked != null) setState(() => _newTime = picked);
                      },
                      child: const Text('Select'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Reason Selector
          SectionTitle(
            _isReschedule ? 'Reason for Reschedule' : 'Reason for Cancellation',
          ),
          const SizedBox(height: 8),

          SurfaceCard(
            child: Column(
              children: _reasons.map((r) {
                final isSelected = _selectedReason == r;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedReason = r),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected
                                ? (_isReschedule
                                      ? AppColors.primary
                                      : AppColors.danger)
                                : AppColors.muted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              r,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.text
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Policy Note (SRS 21)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isReschedule
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isReschedule
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: _isReschedule ? AppColors.primary : AppColors.danger,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isReschedule
                        ? 'Rescheduling requires customer acceptance. If declined, the job can be safely reassigned through cooperative dispatch.'
                        : 'Per SRS 21: Excessive short-notice cancellations without verified emergency may reduce algorithm dispatch priority.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isReschedule ? AppColors.text : AppColors.danger,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
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
            onPressed: _handleSubmit,
            icon: Icon(
              _isReschedule
                  ? Icons.schedule_send_rounded
                  : Icons.cancel_outlined,
            ),
            label: Text(
              _isReschedule
                  ? 'Submit Reschedule Request'
                  : 'Confirm Cancellation',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _isReschedule
                  ? AppColors.primary
                  : AppColors.danger,
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
