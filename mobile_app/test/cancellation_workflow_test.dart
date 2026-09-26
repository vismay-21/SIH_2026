import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/models/api/api_models.dart';
import 'package:mobile_app/models/customer_gig_workflow.dart';
import 'package:mobile_app/models/worker_job_workflow.dart';
import 'package:mobile_app/providers/customer_gigs_provider.dart';
import 'package:mobile_app/providers/worker_jobs_provider.dart';
import 'package:mobile_app/repositories/gig_repository.dart';
import 'package:mobile_app/services/api_client.dart';
import 'package:mobile_app/services/token_storage.dart';

void main() {
  group('Gig Cancellation & State Consistency Tests', () {
    setUp(() {
      TokenStorage.instance.clear();
      ApiClient.mockHandler = null;
    });

    tearDown(() {
      TokenStorage.instance.clear();
      ApiClient.mockHandler = null;
    });

    test('GigCancelResponseDto parses backend JSON correctly', () {
      final json = {
        'gig_id': 'gig-1234',
        'status': 'CANCELLED',
        'cancelled_by': 'user-customer-1',
        'cancellation_reason': 'My plans changed',
        'fee_amount': 0.0,
        'cancelled_at': '2026-09-15T22:00:00Z',
        'payment_status': null,
        'payment_required': false,
        'cancellation_id': 'canc-999',
      };

      final dto = GigCancelResponseDto.fromJson(json);

      expect(dto.gigId, 'gig-1234');
      expect(dto.status, 'CANCELLED');
      expect(dto.cancelledBy, 'user-customer-1');
      expect(dto.cancellationReason, 'My plans changed');
      expect(dto.feeAmount, 0.0);
      expect(dto.paymentRequired, false);
      expect(dto.cancellationId, 'canc-999');
    });

    test('GigRepository.cancelGig sends POST request with correct payload', () async {
      String? requestedPath;
      dynamic requestedData;

      ApiClient.mockHandler = (options) async {
        requestedPath = options.path;
        requestedData = options.data;
        return Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'data': {
              'gig_id': 'gig-456',
              'status': 'CANCELLED',
              'cancelled_by': 'cust-1',
              'cancellation_reason': 'Issue resolved independently',
              'fee_amount': 0.0,
              'cancelled_at': '2026-09-15T22:00:00Z',
              'payment_status': null,
              'payment_required': false,
              'cancellation_id': 'canc-111',
            },
            'message': 'Gig cancelled successfully',
          },
        );
      };

      final repo = GigRepository();
      final result = await repo.cancelGig(
        gigId: 'gig-456',
        reason: 'Issue resolved independently',
      );

      expect(requestedPath, '/gigs/gig-456/cancel');
      expect(requestedData, {'reason': 'Issue resolved independently'});
      expect(result.status, 'CANCELLED');
      expect(result.feeAmount, 0.0);
    });

    test('CustomerGig.fromDto maps CANCELLED status to GigStage.cancelled', () {
      final gigDto = GigDto(
        id: 'gig-canc-1',
        customerId: 'cust-1',
        cooperativeId: 'coop-1',
        categoryId: 'cat-1',
        categoryName: 'Plumbing',
        gigType: 'STANDARD',
        status: 'CANCELLED',
        isEmergency: false,
        materialProcurementMode: 'CUSTOMER_PURCHASES',
        basePrice: 500.0,
        createdAt: DateTime.parse('2026-09-15T10:00:00Z'),
        updatedAt: DateTime.parse('2026-09-15T11:00:00Z'),
        tasks: [],
      );

      final gig = CustomerGig.fromDto(gigDto);
      expect(gig.stage, GigStage.cancelled);
      expect(gig.rawStatus, 'CANCELLED');
    });

    test('WorkerJob.fromDto maps CANCELLED status to WorkerJobStatus.cancelled', () {
      const workerGigDto = WorkerGigListItemDto(
        id: 'gig-w-1',
        customerId: 'cust-1',
        categoryId: 'cat-1',
        categoryName: 'Electrical',
        gigType: 'STANDARD',
        status: 'CANCELLED',
        exactWage: 450.0,
      );

      final job = WorkerJob.fromDto(workerGigDto);
      expect(job.status, WorkerJobStatus.cancelled);
    });

    test('WorkerJob.fromDto formats scheduledDate and scheduledStartTime into clear date and time display', () {
      const workerGigDto = WorkerGigListItemDto(
        id: 'gig-w-2',
        customerId: 'cust-1',
        categoryId: 'cat-1',
        categoryName: 'Plumbing',
        gigType: 'STANDARD',
        status: 'IN_PROGRESS',
        exactWage: 500.0,
        scheduledDate: '2026-09-30',
        scheduledStartTime: '16:00:00',
      );

      final job = WorkerJob.fromDto(workerGigDto);
      expect(job.when, equals('30 Sep 2026 at 4:00 PM'));
      expect(job.scheduledDate, equals('2026-09-30'));
      expect(job.scheduledStartTime, equals('16:00:00'));
    });

    test('WorkerJobsState filters out cancelled jobs from active and current', () {
      const activeJob = WorkerJob(
        id: 'job-1',
        title: 'Carpentry repair',
        category: 'Carpentry',
        description: 'Fix door',
        wage: '₹500',
        when: 'Today',
        location: 'Sector 5',
        duration: '1 hr',
        status: WorkerJobStatus.active,
        customerName: 'Customer',
        materials: 'Included',
        instructions: 'Call on arrival',
      );

      const cancelledJob = WorkerJob(
        id: 'job-2',
        title: 'Leak repair',
        category: 'Plumbing',
        description: 'Fix pipe',
        wage: '₹350',
        when: 'Today',
        location: 'Sector 6',
        duration: '1 hr',
        status: WorkerJobStatus.cancelled,
        customerName: 'Customer',
        materials: 'None',
        instructions: '',
      );

      const stateWithCancelled = WorkerJobsState(
        activeJobs: [cancelledJob],
        upcomingJobs: [],
        awaitingSelectionJobs: [cancelledJob],
      );

      expect(stateWithCancelled.currentJob, isNull);
      expect(stateWithCancelled.allActiveAndScheduled, isEmpty);

      const stateWithActive = WorkerJobsState(
        activeJobs: [activeJob, cancelledJob],
        upcomingJobs: [],
        awaitingSelectionJobs: [],
      );

      expect(stateWithActive.currentJob?.id, 'job-1');
      expect(stateWithActive.allActiveAndScheduled.length, 1);
      expect(stateWithActive.allActiveAndScheduled.first.id, 'job-1');
    });

    test('CustomerGigsState computes activeNow, upcoming, and allGigs correctly', () {
      const activeNowGig = CustomerGig(
        id: 'gig-1',
        title: 'Immediate Pipe Repair',
        category: 'Plumbing',
        description: 'Fix leak in kitchen',
        when: 'Today, 10:00 AM',
        location: 'Sector 5',
        duration: '1 hr',
        stage: GigStage.active,
        materials: 'Included',
        instructions: 'Call on arrival',
        candidates: [],
        isEmergency: false,
        rawStatus: 'IN_PROGRESS',
      );

      const scheduledGig = CustomerGig(
        id: 'gig-2',
        title: 'Electrical Inspection',
        category: 'Electrical',
        description: 'Check main MCB',
        when: 'Tomorrow, 2:00 PM',
        location: 'Sector 6',
        duration: '2 hrs',
        stage: GigStage.scheduled,
        materials: 'None',
        instructions: '',
        candidates: [],
        isEmergency: false,
        rawStatus: 'SCHEDULED',
      );

      const completedGig = CustomerGig(
        id: 'gig-3',
        title: 'Carpentry Table Repair',
        category: 'Carpentry',
        description: 'Fix leg',
        when: 'Yesterday',
        location: 'Sector 7',
        duration: '1 hr',
        stage: GigStage.completed,
        materials: 'Customer provided',
        instructions: '',
        candidates: [],
        isEmergency: false,
        rawStatus: 'COMPLETED',
      );

      final state = CustomerGigsState(
        activeGigs: [activeNowGig, scheduledGig],
        completedGigs: [completedGig],
      );

      expect(state.activeCount, 2);
      expect(state.allGigs.length, 3);
      expect(state.activeNow.length, 1);
      expect(state.activeNow.first.id, 'gig-1');
      expect(state.upcoming.length, 1);
      expect(state.upcoming.first.id, 'gig-2');
      expect(state.completedGigs.length, 1);
      expect(state.completedGigs.first.id, 'gig-3');
    });
  });
}
