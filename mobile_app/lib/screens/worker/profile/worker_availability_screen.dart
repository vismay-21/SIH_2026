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

  @override
  void initState() {
    super.initState();
    _schedule = List.from(demoWeekAvailability);
  }

  void _applyPreset(String preset) {
    setState(() {
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
        content: Text('Weekly availability updated successfully!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weekly Availability',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // Introduction
          const Text(
            'Control your schedule (SRS 10.1). You only receive opportunity notifications during your active hours.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Quick Presets
          const SectionTitle('Quick Presets'),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  label: const Text('Mon–Fri (9 AM – 6 PM)'),
                  onPressed: () => _applyPreset('standard'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('All 7 Days'),
                  onPressed: () => _applyPreset('all'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Weekends Only'),
                  onPressed: () => _applyPreset('weekend'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const SectionTitle('Recurring Weekly Schedule'),
          const SizedBox(height: 8),

          ..._schedule.asMap().entries.map((entry) {
            final idx = entry.key;
            final day = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              day.isAvailable
                                  ? Icons.check_circle_rounded
                                  : Icons.do_not_disturb_on_outlined,
                              size: 18,
                              color: day.isAvailable
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              day.day,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: day.isAvailable
                                    ? AppColors.text
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: day.isAvailable,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _schedule[idx] = day.copyWith(isAvailable: val);
                            });
                          },
                        ),
                      ],
                    ),
                    if (day.isAvailable) ...[
                      const Divider(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(
                                    hour: 9,
                                    minute: 0,
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _schedule[idx] = day.copyWith(
                                      startTime: picked.format(context),
                                    );
                                  });
                                }
                              },
                              icon: const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                              ),
                              label: Text(
                                day.startTime,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'to',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(
                                    hour: 18,
                                    minute: 0,
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _schedule[idx] = day.copyWith(
                                      endTime: picked.format(context),
                                    );
                                  });
                                }
                              },
                              icon: const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                              ),
                              label: Text(
                                day.endTime,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
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
            onPressed: _saveSchedule,
            icon: const Icon(Icons.check_rounded),
            label: const Text(
              'Save Availability Schedule',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}
