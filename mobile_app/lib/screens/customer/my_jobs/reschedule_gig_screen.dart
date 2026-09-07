import 'package:flutter/material.dart';

import '../../../models/customer_gig_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class RescheduleGigScreen extends StatefulWidget {
  const RescheduleGigScreen({super.key, required this.gig});

  final CustomerGig gig;

  @override
  State<RescheduleGigScreen> createState() => _RescheduleGigScreenState();
}

class _RescheduleGigScreenState extends State<RescheduleGigScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 11, minute: 0);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submitReschedule() {
    final formattedDate =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    final formattedTime = _selectedTime.format(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reschedule request sent for $formattedDate at $formattedTime. Waiting for worker confirmation.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    final formattedTime = _selectedTime.format(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reschedule Gig')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.gig.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current schedule: ${widget.gig.when}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Select New Date & Time'),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Column(
              children: [
                ListTile(
                  onTap: _pickDate,
                  leading: const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('New Date'),
                  subtitle: Text(formattedDate),
                  trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                ),
                const Divider(height: 1),
                ListTile(
                  onTap: _pickTime,
                  leading: const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('New Start Time'),
                  subtitle: Text(formattedTime),
                  trailing: const Icon(
                    Icons.access_time_filled_rounded,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            child: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Worker Confirmation',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'The worker will be notified of your request. If accepted, the job schedule updates automatically.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryAction(
            label: 'Send reschedule request',
            icon: Icons.send_rounded,
            onPressed: _submitReschedule,
          ),
        ],
      ),
    );
  }
}
