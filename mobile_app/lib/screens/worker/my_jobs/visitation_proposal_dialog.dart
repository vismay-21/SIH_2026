import 'package:flutter/material.dart';

import '../../../models/api/api_models.dart';
import '../../../repositories/catalogue_repository.dart';
import '../../../repositories/gig_repository.dart';
import '../../../theme/app_theme.dart';

class VisitationProposalDialog extends StatefulWidget {
  const VisitationProposalDialog({
    super.key,
    required this.gigId,
    required this.categoryId,
    required this.categoryName,
  });

  final String gigId;
  final String categoryId;
  final String categoryName;

  static Future<bool?> show(
    BuildContext context, {
    required String gigId,
    required String categoryId,
    required String categoryName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VisitationProposalDialog(
        gigId: gigId,
        categoryId: categoryId,
        categoryName: categoryName,
      ),
    );
  }

  @override
  State<VisitationProposalDialog> createState() =>
      _VisitationProposalDialogState();
}

class _VisitationProposalDialogState extends State<VisitationProposalDialog> {
  final CatalogueRepository _catalogueRepo = CatalogueRepository();
  final GigRepository _gigRepo = GigRepository();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<ServiceTaskDto> _availableTasks = [];
  final Set<String> _selectedTaskIds = {};
  PricePreviewDto? _pricePreview;

  @override
  void initState() {
    super.initState();
    _loadCategoryTasks();
  }

  Future<void> _loadCategoryTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String resolvedCatId = widget.categoryId;

      // If categoryId is missing or empty, look it up from categories list by name
      if (resolvedCatId.isEmpty) {
        final categories = await _catalogueRepo.getCategories();
        final matched = categories.firstWhere(
          (c) =>
              c.name.toLowerCase() == widget.categoryName.toLowerCase() ||
              widget.categoryName.toLowerCase().contains(c.name.toLowerCase()),
          orElse: () => categories.first,
        );
        resolvedCatId = matched.id;
      }

      final tasks = await _catalogueRepo.getTasks(resolvedCatId);
      if (mounted) {
        setState(() {
          _availableTasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load task catalogue: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleTask(String taskId) async {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });

    if (_selectedTaskIds.isEmpty) {
      setState(() => _pricePreview = null);
      return;
    }

    try {
      final preview = await _catalogueRepo.getPricePreview(
        categoryId: widget.categoryId.isNotEmpty
            ? widget.categoryId
            : (_availableTasks.isNotEmpty ? _availableTasks.first.categoryId : ''),
        taskIds: _selectedTaskIds.toList(),
      );
      if (mounted) {
        setState(() => _pricePreview = preview);
      }
    } catch (_) {}
  }

  Future<void> _submitProposal() async {
    if (_selectedTaskIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one diagnosed task.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _gigRepo.submitVisitationProposal(
        gigId: widget.gigId,
        taskIds: _selectedTaskIds.toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task proposal submitted! Waiting for customer approval.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit proposal: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
              color: AppColors.primary,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_add,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'On-Site Scope Proposal',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Select diagnosed repair tasks · ${widget.categoryName}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Explanatory Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.accent.withValues(alpha: 0.12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.primaryDark),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'If customer accepts, ₹100 diagnostic fee is waived into total quote. If declined, ₹100 visit charge is paid.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 40, color: AppColors.danger),
                                const SizedBox(height: 10),
                                Text(_errorMessage!, textAlign: TextAlign.center),
                                const SizedBox(height: 14),
                                ElevatedButton(
                                  onPressed: _loadCategoryTasks,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _availableTasks.isEmpty
                          ? const Center(
                              child: Text('No catalogue tasks available for this trade.'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _availableTasks.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final task = _availableTasks[idx];
                                final isChecked = _selectedTaskIds.contains(task.id);

                                return CheckboxListTile(
                                  value: isChecked,
                                  activeColor: AppColors.primary,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  title: Text(
                                    task.name,
                                    style: TextStyle(
                                      fontWeight: isChecked
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${task.standardDurationMinutes} min standard · ₹${task.basePrice.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  onChanged: (_) => _toggleTask(task.id),
                                );
                              },
                            ),
            ),

            // Quote Preview & Submit Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_selectedTaskIds.length} task(s) selected',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _pricePreview != null
                                ? '₹${_pricePreview!.basePrice.toInt()} Total Quote'
                                : 'Select repair scope',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      if (_pricePreview != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Payout: ₹${_pricePreview!.estimatedWageRange.minWage.toInt()} - ₹${_pricePreview!.estimatedWageRange.maxWage.toInt()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: (_isSubmitting || _selectedTaskIds.isEmpty)
                          ? null
                          : _submitProposal,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isSubmitting
                            ? 'Submitting Proposal...'
                            : 'Send Scope to Customer',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
