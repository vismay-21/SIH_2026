import 'dart:async';
import 'package:flutter/material.dart';

import '../../../models/worker_job_workflow.dart';
import '../../../repositories/gig_repository.dart';
import '../../../repositories/payment_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../../common/chat_screen.dart';
import 'worker_payment_confirmation_screen.dart';

class WaitingConfirmationScreen extends StatefulWidget {
  const WaitingConfirmationScreen({super.key, required this.job});

  final WorkerJob job;

  @override
  State<WaitingConfirmationScreen> createState() =>
      _WaitingConfirmationScreenState();
}

class _WaitingConfirmationScreenState extends State<WaitingConfirmationScreen> {
  late WorkerJob _job;
  bool _isApproved = false;
  bool _isChecking = false;
  String? _paymentMethod;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _isApproved = _job.status == WorkerJobStatus.paymentPending ||
        _job.status == WorkerJobStatus.completed;

    if (!_isApproved) {
      _checkStatus();
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    final gigId = _job.gigId;
    if (gigId == null || gigId.startsWith('job-')) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isApproved && mounted) {
        _checkStatus();
      }
    });
  }

  Future<void> _checkStatus({bool showFeedback = false}) async {
    if (_isChecking) return;
    final gigId = _job.gigId;

    if (gigId == null || gigId.startsWith('job-')) {
      // Mock / local demo job toggle for development testing
      if (showFeedback && mounted) {
        setState(() {
          _isApproved = !_isApproved;
          if (_isApproved) {
            _job = _job.copyWith(status: WorkerJobStatus.paymentPending);
            _pollTimer?.cancel();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isApproved
                  ? 'Demo: Customer approved work.'
                  : 'Demo: Awaiting customer approval.',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    setState(() => _isChecking = true);
    try {
      // Check gig status first
      final gig = await GigRepository().getGig(gigId);
      final statusUpper = gig.status.toUpperCase();

      // Check payment status if available
      String? paymentMethod;
      bool paymentApproved = false;
      try {
        final payment = await PaymentRepository().getGigPayment(gigId);
        paymentMethod = payment.paymentMethod;
        if (payment.status == 'CUSTOMER_PAID' ||
            payment.status == 'COMPLETED' ||
            payment.status == 'WORKER_CONFIRMED' ||
            payment.canConfirm) {
          paymentApproved = true;
        }
      } catch (_) {
        // Payment record may not exist yet until customer confirms/initiates
      }

      final approved = paymentApproved ||
          statusUpper == 'CUSTOMER_CONFIRMED' ||
          statusUpper == 'PAYMENT_PENDING' ||
          statusUpper == 'PAYMENT_CUSTOMER_PAID' ||
          statusUpper == 'PAYMENT_WORKER_CONFIRMED' ||
          statusUpper == 'COMPLETED';

      if (mounted) {
        setState(() {
          _isApproved = approved;
          if (paymentMethod != null) {
            _paymentMethod = paymentMethod;
          }
          if (approved) {
            _job = _job.copyWith(status: WorkerJobStatus.paymentPending);
            _pollTimer?.cancel();
            _pollTimer = null;
          }
        });

        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                approved
                    ? 'Customer has approved! You can now confirm payment.'
                    : 'Still waiting for customer approval.',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not refresh status: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isApproved ? 'Customer Approved' : 'Waiting for Customer',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: _isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Check approval & payment',
            onPressed: () => _checkStatus(showFeedback: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _checkStatus(showFeedback: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          children: [
            // Status Illustration Card
            SurfaceCard(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _isApproved
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isApproved
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_top_rounded,
                      color: _isApproved
                          ? AppColors.success
                          : AppColors.primaryDark,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _isApproved
                        ? 'Customer Approved Work!'
                        : 'Evidence Submitted',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isApproved
                        ? '${_job.customerName} has verified completion and approved payment.'
                        : 'Waiting for ${_job.customerName} to verify completion.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _isApproved
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: _isApproved
                          ? Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isApproved) ...[
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Awaiting Approval & Payment release',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.payments_outlined,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _paymentMethod != null
                                ? 'Approved · Paying via $_paymentMethod'
                                : 'Approved · Collect Cash or UPI & Confirm',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Job & Payout Breakdown
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _job.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Location: ${_job.location}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Agreed Wage',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _job.wage,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contact Customer Card
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Contact',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Calling ${_job.customerName}...'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.call_outlined),
                          label: const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ChatScreen(
                                  title: _job.customerName,
                                  subtitle: 'Customer · ${_job.title}',
                                  gigId: _job.gigId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('Message'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
          child: _isApproved
              ? FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => WorkerPaymentConfirmationScreen(job: _job),
                      ),
                    );
                  },
                  icon: const Icon(Icons.payments_rounded),
                  label: const Text(
                    'Confirm Payment Received',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                )
              : Opacity(
                  opacity: 0.45,
                  child: FilledButton.icon(
                    onPressed: null,
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: Colors.grey.shade400,
                      disabledForegroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.hourglass_top_rounded),
                    label: const Text(
                      'Awaiting Customer Approval',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
