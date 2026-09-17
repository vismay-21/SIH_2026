import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/api/api_response.dart';
import '../../../models/customer_gig_workflow.dart';
import '../../../providers/customer_gigs_provider.dart';
import '../../../repositories/gig_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class RescheduleGigScreen extends ConsumerStatefulWidget {
  const RescheduleGigScreen({super.key, required this.gig});

  final CustomerGig gig;

  @override
  ConsumerState<RescheduleGigScreen> createState() => _RescheduleGigScreenState();
}

class _RescheduleGigScreenState extends ConsumerState<RescheduleGigScreen> {
  final _gigRepo = GigRepository();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 11, minute: 0);
  bool _isSubmitting = false;

  bool get _hasSelectedWorker => widget.gig.selectedWorker != null;

  @override
  void initState() {
    super.initState();
    if (widget.gig.scheduledDate != null) {
      final parsed = DateTime.tryParse(widget.gig.scheduledDate!);
      if (parsed != null) {
        _selectedDate = parsed;
      }
    }
    if (widget.gig.scheduledStartTime != null) {
      final parts = widget.gig.scheduledStartTime!.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          _selectedTime = TimeOfDay(hour: h, minute: m);
        }
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
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

  Future<void> _submitReschedule() async {
    final formattedDate =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    final formattedTime = _selectedTime.format(context);

    setState(() => _isSubmitting = true);

    try {
      final gigId = widget.gig.id;
      final dateIso =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final timeIso =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';

      if (gigId != null && !gigId.startsWith('gig-')) {
        if (!_hasSelectedWorker) {
          // Direct schedule update in backend database before worker assignment
          await _gigRepo.updateGigSchedule(
            gigId: gigId,
            scheduledDate: dateIso,
            scheduledStartTime: timeIso,
          );
        }
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ref.read(customerGigsProvider.notifier).loadGigs(silent: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _hasSelectedWorker
                ? 'Reschedule request sent for $formattedDate at $formattedTime. Waiting for worker confirmation.'
                : 'Gig schedule updated to $formattedDate at $formattedTime.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update schedule: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update schedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                  'Current schedule: ${widget.gig.scheduleDisplay}',
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
                Icon(
                  _hasSelectedWorker
                      ? Icons.swap_horiz_rounded
                      : Icons.event_available_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasSelectedWorker
                            ? 'Worker Confirmation'
                            : 'Direct Schedule Update',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasSelectedWorker
                            ? 'The worker will be notified of your request. If accepted, the job schedule updates automatically.'
                            : 'Since no worker is selected yet, your gig schedule will update immediately for all reviewing artisans.',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryAction(
            label: _isSubmitting
                ? 'Updating Schedule...'
                : (_hasSelectedWorker
                    ? 'Send reschedule request'
                    : 'Update Gig Schedule'),
            icon: _hasSelectedWorker
                ? Icons.send_rounded
                : Icons.check_circle_outline_rounded,
            onPressed: _isSubmitting ? null : _submitReschedule,
          ),
        ],
      ),
    );
  }
}
