import 'package:flutter/material.dart';

import '../../../models/api/api_models.dart';
import '../../../models/api/api_response.dart';
import '../../../repositories/review_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';

class ReviewWorkerScreen extends StatefulWidget {
  const ReviewWorkerScreen({
    super.key,
    required this.workerName,
    required this.gigTitle,
    this.gigId,
    this.workerId,
  });

  final String workerName;
  final String gigTitle;
  final String? gigId;
  final String? workerId;

  @override
  State<ReviewWorkerScreen> createState() => _ReviewWorkerScreenState();
}

class _ReviewWorkerScreenState extends State<ReviewWorkerScreen> {
  final _reviewRepo = ReviewRepository();

  List<ReviewQuestionDto> _questions = [];
  final Map<String, int> _answers = {}; // questionId -> rating 1..5
  bool _isLoadingQuestions = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.gigId != null && widget.workerId != null) {
      _loadQuestions();
    }
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoadingQuestions = true);
    try {
      final qs = await _reviewRepo.getQuestions(targetRole: 'WORKER');
      if (!mounted) return;
      setState(() {
        _questions = qs;
        for (var q in qs) {
          _answers[q.id] = 5; // default 5 stars
        }
        _isLoadingQuestions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingQuestions = false);
    }
  }

  Future<void> _submitReview() async {
    if (widget.gigId != null && widget.workerId != null && _questions.isNotEmpty) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      try {
        final answerItems = _answers.entries
            .map((e) => ReviewAnswerItemDto(questionId: e.key, answerValue: e.value))
            .toList();

        await _reviewRepo.submitReview(
          gigId: widget.gigId!,
          revieweeId: widget.workerId!,
          answers: answerItems,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Review submitted for ${widget.workerName}. Thank you!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
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
          content: Text('Review submitted for ${widget.workerName}. Thank you!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Text(
                    widget.workerName.isNotEmpty
                        ? widget.workerName[0].toUpperCase()
                        : 'W',
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
            const SectionTitle('1. Work Quality & Completion'),
            const SizedBox(height: 8),
            _StaticStarRow(),
            const SizedBox(height: 18),
            const SectionTitle('2. Punctuality & Professionalism'),
            const SizedBox(height: 8),
            _StaticStarRow(),
            const SizedBox(height: 18),
            const SectionTitle('3. Communication & Transparency'),
            const SizedBox(height: 8),
            _StaticStarRow(),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : PrimaryAction(
                    label: 'Submit structured review',
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
