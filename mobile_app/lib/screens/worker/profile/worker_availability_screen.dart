import 'package:flutter/material.dart';

import '../../../models/worker_job_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class WorkerAvailabilityScreen extends StatefulWidget {
  const WorkerAvailabilityScreen({super.key});

  @override
  State<WorkerAvailabilityScreen> createState() =>
      _WorkerAvailabilityScreenState();
}

class _WorkerAvailabilityScreenState extends State<WorkerAvailabilityScreen> {
  late List<DayAvailability> _schedule;
  String _activePreset = '';

  @override
  void initState() {
    super.initState();
    _schedule = List.from(demoWeekAvailability);
  }

  void _applyPreset(String preset) {
    setState(() {
      _activePreset = preset;
      if (preset == 'standard') {
        _schedule = _schedule.map((d) {
          final isWeekend = d.day == 'Saturday' || d.day == 'Sunday';
          return d.copyWith(
            isAvailable: !isWeekend,
            startTime: '09:00 AM',
            endTime: '06:00 PM',
          );
        }).toList();
      } else if (preset == 'all') {
        _schedule = _schedule.map((d) {
          return d.copyWith(
            isAvailable: true,
            startTime: '09:00 AM',
            endTime: '07:00 PM',
          );
        }).toList();
      } else if (preset == 'weekend') {
        _schedule = _schedule.map((d) {
          final isWeekend = d.day == 'Saturday' || d.day == 'Sunday';
          return d.copyWith(
            isAvailable: isWeekend,
            startTime: '10:00 AM',
            endTime: '06:00 PM',
          );
        }).toList();
      }
    });
  }

  void _saveSchedule() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Weekly availability updated successfully!')),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  String _getDayAbbr(String fullDay) {
    if (fullDay.length >= 3) {
      return fullDay.substring(0, 3).toUpperCase();
    }
    return fullDay.toUpperCase();
  }

  Future<void> _pickTime(int idx, bool isStart) async {
    final day = _schedule[idx];
    final currentStr = isStart ? day.startTime : day.endTime;
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);

    try {
      final parts = currentStr.split(' ');
      if (parts.isNotEmpty) {
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour < 12) {
          hour += 12;
        } else if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && hour == 12) {
          hour = 0;
        }
        initial = TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null && mounted) {
      setState(() {
        final formatted = picked.format(context);
        _schedule[idx] = isStart
            ? day.copyWith(startTime: formatted)
            : day.copyWith(endTime: formatted);
        _activePreset = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDaysCount = _schedule.where((d) => d.isAvailable).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weekly Availability',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          // 1. Overview Banner Card
          SurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Hours',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          StatusPill(
                            '$activeDaysCount / 7 days active',
                            warning: activeDaysCount == 0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Set your regular working hours. You will only receive customer job dispatches during these configured slots.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Quick Presets Section
          const SectionTitle('Quick Presets'),
          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PresetButton(
                  icon: Icons.work_outline_rounded,
                  label: 'Mon–Fri (9–6)',
                  isSelected: _activePreset == 'standard',
                  onTap: () => _applyPreset('standard'),
                ),
                const SizedBox(width: 8),
                _PresetButton(
                  icon: Icons.all_inclusive_rounded,
                  label: 'All 7 Days',
                  isSelected: _activePreset == 'all',
                  onTap: () => _applyPreset('all'),
                ),
                const SizedBox(width: 8),
                _PresetButton(
                  icon: Icons.weekend_outlined,
                  label: 'Weekends Only',
                  isSelected: _activePreset == 'weekend',
                  onTap: () => _applyPreset('weekend'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // 3. Daily Schedule List
          const SectionTitle('Recurring Weekly Schedule'),
          const SizedBox(height: 10),

          ..._schedule.asMap().entries.map((entry) {
            final idx = entry.key;
            final day = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfaceCard(
                child: Column(
                  children: [
                    // Header row: Day badge, title, subtitle & Switch
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: day.isAvailable
                                ? AppColors.primary
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getDayAbbr(day.day),
                            style: TextStyle(
                              color: day.isAvailable ? Colors.white : AppColors.muted,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                day.day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                day.isAvailable
                                    ? '${day.startTime} – ${day.endTime}'
                                    : 'Off-duty · No job alerts',
                                style: TextStyle(
                                  color: day.isAvailable
                                      ? AppColors.primary
                                      : AppColors.muted,
                                  fontWeight: day.isAvailable
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: day.isAvailable,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _schedule[idx] = day.copyWith(isAvailable: val);
                              _activePreset = '';
                            });
                          },
                        ),
                      ],
                    ),

                    // Time pickers row when day is active
                    if (day.isAvailable) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(idx, true),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.schedule_rounded,
                                        size: 15,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        day.startTime,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: AppColors.muted,
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(idx, false),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.schedule_rounded,
                                        size: 15,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        day.endTime,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: PrimaryAction(
              label: 'Save Weekly Availability',
              icon: Icons.check_circle_rounded,
              onPressed: _saveSchedule,
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
