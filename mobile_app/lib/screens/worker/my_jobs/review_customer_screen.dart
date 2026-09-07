import 'package:flutter/material.dart';

import '../../../models/worker_job_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class ReviewCustomerScreen extends StatefulWidget {
  const ReviewCustomerScreen({super.key, required this.job});

  final WorkerJob job;

  @override
  State<ReviewCustomerScreen> createState() => _ReviewCustomerScreenState();
}

class _ReviewCustomerScreenState extends State<ReviewCustomerScreen> {
  int _overallRating = 5;
  int _safetyIndex = 0;
  int _accuracyIndex = 0;
  int _communicationIndex = 0;
  final TextEditingController _feedbackController = TextEditingController();

  final List<String> _safetyOptions = [
    'Yes, clean & fully prepared',
    'Needed minor clearing',
    'Unsafe or hazardous conditions',
  ];

  final List<String> _accuracyOptions = [
    'Accurate as described',
    'Minor scope addition',
    'Significantly different from post',
  ];

  final List<String> _commOptions = [
    'Very prompt & polite',
    'Acceptable communication',
    'Unresponsive or difficult',
  ];

  void _submitReview() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Review submitted for ${widget.job.customerName}. Thank you!',
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Return to the root of the tab
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rate Customer',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // Customer Header
          SurfaceCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: AppColors.primary,
                  child: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.job.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Completed: ${widget.job.title}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Star Rating
          SurfaceCard(
            child: Column(
              children: [
                const Text(
                  'Overall Experience',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return IconButton(
                      onPressed: () =>
                          setState(() => _overallRating = starValue),
                      icon: Icon(
                        starValue <= _overallRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.accent,
                        size: 34,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Structured MCQ Criteria (SRS 20)
          const SectionTitle('Objective Cooperative Assessment (SRS 20)'),
          const SizedBox(height: 10),

          // Q1: Safety
          _buildMcqCard(
            question: '1. Work Area Preparation & Safety',
            options: _safetyOptions,
            selectedIndex: _safetyIndex,
            onSelect: (val) => setState(() => _safetyIndex = val),
          ),

          const SizedBox(height: 12),

          // Q2: Job Accuracy
          _buildMcqCard(
            question: '2. Gig Description Accuracy',
            options: _accuracyOptions,
            selectedIndex: _accuracyIndex,
            onSelect: (val) => setState(() => _accuracyIndex = val),
          ),

          const SizedBox(height: 12),

          // Q3: Communication
          _buildMcqCard(
            question: '3. Customer Communication',
            options: _commOptions,
            selectedIndex: _communicationIndex,
            onSelect: (val) => setState(() => _communicationIndex = val),
          ),

          const SizedBox(height: 20),
          const SectionTitle('Additional Notes (Optional)'),
          const SizedBox(height: 8),

          TextField(
            controller: _feedbackController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Any helpful remarks for other cooperative technicians...',
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
            onPressed: _submitReview,
            icon: const Icon(Icons.check_rounded),
            label: const Text(
              'Submit Cooperative Rating',
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

  Widget _buildMcqCard({
    required String question,
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ...options.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            final isSelected = selectedIndex == idx;
            return InkWell(
              onTap: () => onSelect(idx),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: isSelected ? AppColors.primary : AppColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isSelected ? AppColors.text : AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
