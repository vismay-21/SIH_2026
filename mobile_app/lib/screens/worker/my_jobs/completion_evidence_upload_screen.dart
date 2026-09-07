import 'package:flutter/material.dart';

import '../../../models/worker_job_workflow.dart';
import '../../../theme/app_theme.dart';
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
  bool _photo1Uploaded = true;
  bool _photo2Uploaded = true;
  final TextEditingController _notesController = TextEditingController(
    text:
        'Replaced valve seal, reconnected pipeline, tested water pressure for 10 minutes with zero leakage. Cleaned work area.',
  );

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_photo1Uploaded && !_photo2Uploaded) {
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

    final updatedJob = WorkerJob(
      id: widget.job.id,
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

          // SRS 19 Explanation Banner
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
                    'Per SRS 19: Photo evidence protects both cooperative workers and customers, creating an immutable audit trail before payment release.',
                    style: TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const SectionTitle('Proof Photos of Completed Work'),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildPhotoUploadCard(
                  title: 'Photo 1: Finished Work',
                  uploaded: _photo1Uploaded,
                  onToggle: () =>
                      setState(() => _photo1Uploaded = !_photo1Uploaded),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPhotoUploadCard(
                  title: 'Photo 2: Area Cleaned',
                  uploaded: _photo2Uploaded,
                  onToggle: () =>
                      setState(() => _photo2Uploaded = !_photo2Uploaded),
                ),
              ),
            ],
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
                    'Upon submission, the customer will be notified to review evidence and release payment.',
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
            onPressed: _handleSubmit,
            icon: const Icon(Icons.send_rounded),
            label: const Text(
              'Submit Evidence to Customer',
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

  Widget _buildPhotoUploadCard({
    required String title,
    required bool uploaded,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: uploaded ? AppColors.primary : AppColors.border,
            width: uploaded ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              uploaded ? Icons.check_circle_rounded : Icons.camera_alt_outlined,
              color: uploaded ? AppColors.primary : AppColors.muted,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              uploaded ? 'Attached (Tap to change)' : 'Tap to capture',
              style: TextStyle(
                color: uploaded ? AppColors.success : AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
