import 'package:flutter/material.dart';

import '../../../models/api/api_models.dart';
import '../../../models/api/api_response.dart';
import '../../../models/worker_job_workflow.dart';
import '../../../repositories/review_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class ReviewCustomerScreen extends StatefulWidget {
  const ReviewCustomerScreen({super.key, required this.job});

  final WorkerJob job;

  @override
  State<ReviewCustomerScreen> createState() => _ReviewCustomerScreenState();
}

class _ReviewCustomerScreenState extends State<ReviewCustomerScreen> {
  final _reviewRepo = ReviewRepository();

  List<ReviewQuestionDto> _questions = [];
  final Map<String, int> _answers = {};
  bool _isLoadingQuestions = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.job.gigId != null && widget.job.customerId != null) {
      _loadQuestions();
    }
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoadingQuestions = true);
    try {
      final qs = await _reviewRepo.getQuestions(targetRole: 'CUSTOMER');
      if (!mounted) return;
      setState(() {
        _questions = qs;
        for (var q in qs) {
          _answers[q.id] = 5;
        }
        _isLoadingQuestions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingQuestions = false);
    }
  }

  Future<void> _submitReview() async {
    if (widget.job.gigId != null && widget.job.customerId != null && _questions.isNotEmpty) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      try {
        final answerItems = _answers.entries
            .map((e) => ReviewAnswerItemDto(questionId: e.key, answerValue: e.value))
            .toList();

        await _reviewRepo.submitReview(
          gigId: widget.job.gigId!,
          revieweeId: widget.job.customerId!,
          answers: answerItems,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Review submitted for ${widget.job.customerName}. Thank you!',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } on ApiError catch (e) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.message;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Review submitted for ${widget.job.customerName}. Thank you!',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
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
          const SizedBox(height: 18),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (_isLoadingQuestions)
            const Center(child: CircularProgressIndicator())
          else if (_questions.isNotEmpty) ...[
            ..._questions.map((q) {
              final currentRating = _answers[q.id] ?? 5;
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.questionText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          icon: Icon(
                            starValue <= currentRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: starValue <= currentRating
                                ? Colors.amber
                                : AppColors.muted,
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() => _answers[q.id] = starValue);
                          },
                        );
                      }),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            const SectionTitle('1. Safety & Site Preparation'),
            const SizedBox(height: 8),
            _StaticStarRow(),
            const SizedBox(height: 18),
            const SectionTitle('2. Scope Accuracy & Clarity'),
            const SizedBox(height: 8),
            _StaticStarRow(),
            const SizedBox(height: 18),
            const SectionTitle('3. Timely Communication & Access'),
            const SizedBox(height: 8),
            _StaticStarRow(),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : PrimaryAction(
                    label: 'Submit Customer Rating',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: _submitReview,
                  ),
          ),
        ],
      ),
    );
  }
}

class _StaticStarRow extends StatefulWidget {
  @override
  State<_StaticStarRow> createState() => _StaticStarRowState();
}

class _StaticStarRowState extends State<_StaticStarRow> {
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final star = index + 1;
        return IconButton(
          icon: Icon(
            star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: star <= _rating ? Colors.amber : AppColors.muted,
            size: 32,
          ),
          onPressed: () => setState(() => _rating = star),
        );
      }),
    );
  }
}
