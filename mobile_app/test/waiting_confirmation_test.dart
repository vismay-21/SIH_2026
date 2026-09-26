import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/models/worker_job_workflow.dart';
import 'package:mobile_app/providers/worker_jobs_provider.dart';
import 'package:mobile_app/screens/worker/my_jobs/waiting_confirmation_screen.dart';
import 'package:mobile_app/screens/worker/my_jobs/worker_navigation_3_screen.dart';

class FakeWorkerJobsNotifier extends WorkerJobsNotifier {
  @override
  WorkerJobsState build() {
    return const WorkerJobsState(
      activeJobs: [],
      upcomingJobs: [],
      completedJobs: [],
      awaitingSelectionJobs: [],
      isLoading: false,
    );
  }

  @override
  Future<void> loadJobs({bool silent = false}) async {}
}

void main() {
  const sampleJobEvidenceSubmitted = WorkerJob(
    id: 'job-1',
    gigId: 'job-1',
    customerId: 'cust-1',
    title: 'Plumbing Repair',
    category: 'Plumbing',
    description: 'Fix leak in kitchen',
    wage: '₹500',
    when: 'Today, 2:00 PM',
    location: 'PDEU Campus, Gandhinagar',
    duration: '1 hr',
    status: WorkerJobStatus.evidenceSubmitted,
    customerName: 'Demo Customer',
    customerPhone: '+91 98765 43210',
    materials: 'None',
    instructions: 'Ring doorbell',
  );

  const sampleJobPaymentPending = WorkerJob(
    id: 'job-2',
    gigId: 'job-2',
    customerId: 'cust-1',
    title: 'Plumbing Repair',
    category: 'Plumbing',
    description: 'Fix leak in kitchen',
    wage: '₹500',
    when: 'Today, 2:00 PM',
    location: 'PDEU Campus, Gandhinagar',
    duration: '1 hr',
    status: WorkerJobStatus.paymentPending,
    customerName: 'Demo Customer',
    customerPhone: '+91 98765 43210',
    materials: 'None',
    instructions: 'Ring doorbell',
  );

  testWidgets('WaitingConfirmationScreen disables button and displays faded awaiting state before customer approval', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WaitingConfirmationScreen(job: sampleJobEvidenceSubmitted),
      ),
    );
    await tester.pump();

    expect(find.text('Waiting for Customer'), findsOneWidget);
    expect(find.text('Evidence Submitted'), findsOneWidget);
    expect(find.text('Awaiting Customer Approval'), findsOneWidget);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull, reason: 'Button must be disabled before customer approves');
  });

  testWidgets('WaitingConfirmationScreen enables Confirm Payment Received button after customer approval', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WaitingConfirmationScreen(job: sampleJobPaymentPending),
      ),
    );
    await tester.pump();

    expect(find.text('Customer Approved'), findsOneWidget);
    expect(find.text('Customer Approved Work!'), findsOneWidget);
    expect(find.text('Confirm Payment Received'), findsOneWidget);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull, reason: 'Button must be clickable after customer approves');
  });

  testWidgets('WorkerNavigation3Screen does not contain Cooperative Artisan Growth & Rookie Track banner', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workerJobsProvider.overrideWith(() => FakeWorkerJobsNotifier()),
        ],
        child: const MaterialApp(
          home: WorkerNavigation3Screen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Cooperative Artisan Growth & Rookie Track'), findsNothing);
  });
}
