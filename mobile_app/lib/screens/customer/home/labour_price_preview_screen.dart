import 'package:flutter/material.dart';

import '../../../models/api/api_models.dart';
import '../../../models/api/api_response.dart';
import '../../../models/gig_draft.dart';
import '../../../repositories/catalogue_repository.dart';
import '../../../repositories/gig_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../customer_main_screen.dart';

class LabourPricePreviewScreen extends StatefulWidget {
  const LabourPricePreviewScreen({super.key, required this.draft});

  final GigDraft draft;

  @override
  State<LabourPricePreviewScreen> createState() =>
      _LabourPricePreviewScreenState();
}

class _LabourPricePreviewScreenState extends State<LabourPricePreviewScreen> {
  final _catalogueRepo = CatalogueRepository();
  final _gigRepo = GigRepository();

  PricePreviewDto? _pricePreview;
  bool _isLoadingPreview = true;
  String? _previewError;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _fetchPreview();
  }

  Future<void> _fetchPreview() async {
    final catId = widget.draft.categoryId;
    final taskIds = widget.draft.taskIds;

    // For visitation gigs, tasks may be empty (worker proposes after visit)
    if (catId == null || (taskIds.isEmpty && !widget.draft.requiresVisitation)) {
      setState(() {
        _isLoadingPreview = false;
      });
      return;
    }

    if (taskIds.isEmpty && widget.draft.requiresVisitation) {
      // No price preview needed for visitation-only gigs
      setState(() => _isLoadingPreview = false);
      return;
    }

    try {
      final preview = await _catalogueRepo.getPricePreview(
        categoryId: catId,
        taskIds: taskIds,
      );
      if (!mounted) return;
      setState(() {
        _pricePreview = preview;
        _isLoadingPreview = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _previewError = e.message;
        _isLoadingPreview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewError = e.toString();
        _isLoadingPreview = false;
      });
    }
  }

  Future<void> _handlePostGig() async {
    setState(() => _isPosting = true);

    try {
      final catId = widget.draft.categoryId;
      final taskIds = widget.draft.taskIds;

      if (catId == null || taskIds.isEmpty) {
        throw const ApiError(
          code: 'INVALID_DRAFT',
          message: 'Category or tasks missing from draft.',
        );
      }

      // 1. Create gig in DRAFT status
      final gig = await _gigRepo.createGig(
        GigCreateRequestDto(
          categoryId: catId,
          taskIds: taskIds,
          gigType: widget.draft.requiresVisitation
              ? 'VISITATION'
              : (widget.draft.isEmergency ? 'EMERGENCY' : 'NORMAL'),
          description: widget.draft.description,
          instructions: widget.draft.instructions.isNotEmpty
              ? widget.draft.instructions
              : null,
          address: widget.draft.location,
          isEmergency: widget.draft.isEmergency,
          materialProcurementMode: widget.draft.customerBuysMaterials
              ? 'CUSTOMER_PURCHASES'
              : 'WORKER_PURCHASES',
        ),
      );

      // 2. Post gig to SEEKING_WORKERS status
      await _gigRepo.postGig(gig.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gig posted successfully! Workers can now view and accept.'),
          backgroundColor: AppColors.primary,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const CustomerMainScreen(),
        ),
        (route) => false,
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error posting gig: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post gig: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _pricePreview;

    return Scaffold(
      appBar: AppBar(title: const Text('Review before posting')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepHeader(step: '3 of 3', title: 'Your labour price range'),
            const SizedBox(height: 10),
            const Text(
              'This is the cooperative estimate for the service work based on standard duration and skill rates. Materials are priced separately.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoadingPreview)
              const SurfaceCard(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_previewError != null)
              SurfaceCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      _previewError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              )
            else
              SurfaceCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Indicative labour range',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      preview != null
                          ? '₹${preview.estimatedWageRange.minWage.toInt()} – ₹${preview.estimatedWageRange.maxWage.toInt()}'
                          : '₹550 – ₹800',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (preview != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Base cooperative labour price: ₹${preview.basePrice.toInt()} (${preview.billableDurationMinutes} min)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      widget.draft.isEmergency
                          ? 'Emergency jobs are prioritized for faster broadcast and matching.'
                          : 'Workers will see their exact guaranteed wage before accepting.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.draft.requiresVisitation) ...[
              const SizedBox(height: 12),
              SurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.home_repair_service_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Site visit charge',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Worker inspects scope before full job',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '₹100',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            const SectionTitle('Gig summary'),
            const SizedBox(height: 8),
            SurfaceCard(
              child: Column(
                children: [
                  _SummaryRow(label: 'Category', value: widget.draft.category),
                  _SummaryRow(label: 'Location', value: widget.draft.location),
                  _SummaryRow(label: 'Duration', value: widget.draft.duration),
                  _SummaryRow(
                    label: 'Materials',
                    value: widget.draft.customerBuysMaterials
                        ? 'Customer purchases'
                        : 'Worker purchases',
                  ),
                  _SummaryRow(
                    label: 'Priority',
                    value: widget.draft.isEmergency ? 'Emergency' : 'Standard',
                  ),
                  if (widget.draft.requiresVisitation)
                    const _SummaryRow(
                      label: 'Site visit',
                      value: 'Requested (₹100)',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: _isPosting
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : PrimaryAction(
                      label: 'Post gig',
                      icon: Icons.publish_rounded,
                      onPressed: _handlePostGig,
                    ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'You can review worker responses from My jobs.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.title});

  final String step;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        step,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
