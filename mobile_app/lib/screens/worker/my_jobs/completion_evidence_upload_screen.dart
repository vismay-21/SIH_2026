import 'package:flutter/material.dart';

import '../../../models/api/api_models.dart';
import '../../../models/worker_job_workflow.dart';
import '../../../repositories/worker_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_photo_view.dart';
import '../../../widgets/common/sample_photos.dart';
import '../../../widgets/common/shared_widgets.dart';
import 'waiting_confirmation_screen.dart';

class CompletionEvidenceUploadScreen extends StatefulWidget {
  const CompletionEvidenceUploadScreen({super.key, required this.job});

  final WorkerJob job;

  @override
  State<CompletionEvidenceUploadScreen> createState() =>
      _CompletionEvidenceUploadScreenState();
}

class _CompletionEvidenceUploadScreenState
    extends State<CompletionEvidenceUploadScreen> {
  final List<String> _photos = [];
  bool _isSubmitting = false;
  final TextEditingController _notesController = TextEditingController(
    text:
        'Replaced valve seal, reconnected pipeline, tested water pressure for 10 minutes with zero leakage. Cleaned work area.',
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    await showPhotoSourcePicker(
      context,
      title: 'Attach Work Evidence Photo',
      subtitle:
          'Take a live photo, pick from gallery, or select a demo proof preset.',
      presetsTitle: 'Work Completion Presets (Demo)',
      presetsSubtitle: 'Choose sample verified repair photo',
      dialogTitle: 'Select Work Evidence Sample',
      customPresets: SampleCompletionPhotos.presets,
      onPhotoSelected: (photoData) {
        setState(() {
          _photos.add(photoData);
        });
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload at least one evidence photo of completed work.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final gigId = widget.job.gigId;
    if (gigId != null && !gigId.startsWith('job-')) {
      try {
        final evidenceItems = _photos.map((photo) {
          return CompletionEvidenceCreateDto(
            fileUrl: photo,
            fileType: 'image/jpeg',
          );
        }).toList();

        await WorkerRepository().submitCompletion(
          gigId: gigId,
          description: _notesController.text.trim(),
          evidenceItems: evidenceItems,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting completion evidence: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    final updatedJob = WorkerJob(
      id: widget.job.id,
      gigId: widget.job.gigId,
      customerId: widget.job.customerId,
      title: widget.job.title,
      category: widget.job.category,
      description: widget.job.description,
      wage: widget.job.wage,
      when: widget.job.when,
      location: widget.job.location,
      duration: widget.job.duration,
      status: WorkerJobStatus.evidenceSubmitted,
      customerName: widget.job.customerName,
      materials: widget.job.materials,
      instructions: widget.job.instructions,
      isEmergency: widget.job.isEmergency,
      isRookieParticipation: widget.job.isRookieParticipation,
      additionalWorkerName: widget.job.additionalWorkerName,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => WaitingConfirmationScreen(job: updatedJob),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Submit Work Evidence',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // Job Summary
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.job.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer: ${widget.job.customerName} · Wage: ${widget.job.wage}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Explanation Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Photo evidence protects both cooperative workers and customers, creating an immutable audit trail before payment release.',
                    style: TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionTitle('Proof Photos of Completed Work'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _photos.isNotEmpty
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_photos.length} photo${_photos.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: _photos.isNotEmpty ? AppColors.primary : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Photo Upload Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: _photos.length + 1,
            itemBuilder: (context, index) {
              if (index < _photos.length) {
                final photo = _photos[index];
                return _buildPhotoCard(
                  photo: photo,
                  index: index,
                  onDelete: () => setState(() => _photos.removeAt(index)),
                  onTap: () => PhotoViewerDialog.show(
                    context,
                    photos: _photos,
                    initialIndex: index,
                  ),
                );
              } else {
                // Add Photo Button Card
                return _buildAddPhotoButton();
              }
            },
          ),

          const SizedBox(height: 20),
          const SectionTitle('Completion Summary Notes'),
          const SizedBox(height: 8),

          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Summarize work steps, leak checks, or testing performed...',
              hintStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 16),

          SurfaceCard(
            child: Row(
              children: const [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Upon submission, the customer will see your evidence photos and will be prompted to confirm completion and release payment.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
              ],
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
            onPressed: _isSubmitting ? null : _handleSubmit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              _isSubmitting
                  ? 'Submitting Evidence...'
                  : 'Submit Evidence to Customer (${_photos.length})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard({
    required String photo,
    required int index,
    required VoidCallback onDelete,
    required VoidCallback onTap,
  }) {
    final label = index == 0
        ? 'Finished Work'
        : index == 1
            ? 'Area Cleaned'
            : 'Evidence #${index + 1}';

    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImageWidget(
                    photo: photo,
                    fit: BoxFit.cover,
                  ),
                  // Dark bottom gradient for legible label
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.zoom_in_rounded,
                              color: Colors.white70, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Delete button
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.black.withValues(alpha: 0.65),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onDelete,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _addPhoto,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add Photo',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 2),
            const Text(
              'Camera, Gallery, Sample',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
