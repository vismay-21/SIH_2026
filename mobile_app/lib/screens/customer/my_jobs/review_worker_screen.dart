import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class ReviewWorkerScreen extends StatefulWidget {
  const ReviewWorkerScreen({
    super.key,
    required this.workerName,
    required this.gigTitle,
  });

  final String workerName;
  final String gigTitle;

  @override
  State<ReviewWorkerScreen> createState() => _ReviewWorkerScreenState();
}

class _ReviewWorkerScreenState extends State<ReviewWorkerScreen> {
  int _qualityScore = 0;
  int _punctualityScore = 0;
  int _communicationScore = 0;
  int _recommendScore = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Review submitted for ${widget.workerName}. Thank you!'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Worker')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          SurfaceCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Text(
                    'AS',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.workerName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.gigTitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('1. Work Quality & Completion'),
          const SizedBox(height: 8),
          _McqGroup(
            options: const [
              'Excellent & Thorough',
              'Good Quality',
              'Satisfactory',
              'Needs Improvement',
            ],
            selectedIndex: _qualityScore,
            onSelected: (idx) => setState(() => _qualityScore = idx),
          ),
          const SizedBox(height: 18),
          const SectionTitle('2. Punctuality & Professionalism'),
          const SizedBox(height: 8),
          _McqGroup(
            options: const [
              'On Time & Courteous',
              'Slight Delay (<15 min)',
              'Significant Delay',
              'Unprofessional',
            ],
            selectedIndex: _punctualityScore,
            onSelected: (idx) => setState(() => _punctualityScore = idx),
          ),
          const SizedBox(height: 18),
          const SectionTitle('3. Communication & Transparency'),
          const SizedBox(height: 8),
          _McqGroup(
            options: const [
              'Clear & Helpful',
              'Adequate',
              'Minimal Communication',
              'Confusing',
            ],
            selectedIndex: _communicationScore,
            onSelected: (idx) => setState(() => _communicationScore = idx),
          ),
          const SizedBox(height: 18),
          const SectionTitle('4. Overall Recommendation'),
          const SizedBox(height: 8),
          _McqGroup(
            options: const [
              'Highly Recommend',
              'Would Hire Again',
              'Neutral',
              'Would Not Hire',
            ],
            selectedIndex: _recommendScore,
            onSelected: (idx) => setState(() => _recommendScore = idx),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Additional Feedback (Optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share any specific details about the service...',
            ),
          ),
          const SizedBox(height: 24),
          PrimaryAction(
            label: 'Submit structured review',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _submitReview,
          ),
        ],
      ),
    );
  }
}

class _McqGroup extends StatelessWidget {
  const _McqGroup({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(options.length, (index) {
        final isSelected = selectedIndex == index;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surface,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected ? AppColors.primary : AppColors.muted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    options[index],
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
