import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/api/api_models.dart';
import 'package:mobile_app/models/customer_gig_workflow.dart';
import 'package:mobile_app/models/gig_draft.dart';
import 'package:mobile_app/models/worker_job_workflow.dart';
import 'package:mobile_app/widgets/common/sample_photos.dart';

void main() {
  group('Operational Photos End-to-End Test Suite', () {
    test('GigDraft stores photos and computes photoCount correctly', () {
      final draft = GigDraft(
        category: 'Plumbing',
        description: 'Leaking pipe',
        location: 'Downtown',
        date: DateTime.now(),
        time: '10:00 AM',
        duration: '2 hours',
        isEmergency: false,
        photos: [
          SampleIssuePhotos.plumbingLeak,
          SampleIssuePhotos.electricalDefect,
        ],
        instructions: 'Call on arrival',
        customerBuysMaterials: true,
      );

      expect(draft.photos.length, 2);
      expect(draft.photoCount, 2);
      expect(draft.photos.first, contains('data:image/jpeg;base64,'));
    });

    test('GigCreateRequestDto serializes photos in JSON payload', () {
      final dto = GigCreateRequestDto(
        categoryId: 'cat-123',
        taskIds: ['task-1'],
        photos: [
          'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD...',
          'https://example.com/issue.jpg',
        ],
      );

      final json = dto.toJson();
      expect(json['photos'], isA<List<String>>());
      final photos = json['photos'] as List<String>;
      expect(photos.length, 2);
      expect(photos[0], startsWith('data:image/jpeg;base64,'));
      expect(photos[1], equals('https://example.com/issue.jpg'));
    });

    test('GigDto parses photos from backend JSON response and maps to CustomerGig', () {
      final json = {
        'id': 'gig-999',
        'customer_id': 'cust-1',
        'cooperative_id': 'coop-1',
        'category_id': 'cat-plumbing',
        'category_name': 'Plumbing Services',
        'gig_type': 'STANDARD',
        'status': 'POSTED',
        'is_emergency': false,
        'material_procurement_mode': 'CUSTOMER_PURCHASES',
        'base_price': 450.0,
        'tasks': [],
        'photos': [
          SampleIssuePhotos.plumbingLeak,
          SampleIssuePhotos.wallCrack,
        ],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final gigDto = GigDto.fromJson(json);
      expect(gigDto.photos.length, 2);

      final customerGig = CustomerGig.fromDto(gigDto);
      expect(customerGig.photos.length, 2);
      expect(customerGig.photos[0], equals(SampleIssuePhotos.plumbingLeak));
      expect(customerGig.photos[1], equals(SampleIssuePhotos.wallCrack));
    });

    test('OpportunityGigDto parses photos and maps to WorkerOpportunity', () {
      final json = {
        'id': 'opp-888',
        'gig_id': 'gig-999',
        'worker_id': 'worker-1',
        'status': 'OFFERED',
        'base_price': 500.0,
        'base_price_snapshot': 500.0,
        'final_score_snapshot': 0.85,
        'premium_percentage': 0.0,
        'exact_wage': 500.0,
        'offered_at': DateTime.now().toIso8601String(),
        'gig': {
          'id': 'gig-999',
          'category_id': 'cat-plumbing',
          'category_name': 'Plumbing Services',
          'gig_type': 'STANDARD',
          'material_procurement_mode': 'CUSTOMER_PURCHASES',
          'tasks': [],
          'photos': [
            SampleIssuePhotos.electricalDefect,
          ],
        },
      };

      final oppDto = OpportunityDto.fromJson(json);
      expect(oppDto.gig.photos.length, 1);

      final workerOpp = WorkerOpportunity.fromDto(oppDto);
      expect(workerOpp.photos.length, 1);
      expect(workerOpp.photos.first, equals(SampleIssuePhotos.electricalDefect));

      final workerJob = WorkerJob.fromOpportunity(workerOpp);
      expect(workerJob.photos.length, 1);
      expect(workerJob.photos.first, equals(SampleIssuePhotos.electricalDefect));
    });

    test('Completion evidence photos serialize and deserialize correctly', () {
      final requestDto = CompletionSubmissionRequestDto(
        description: 'Repaired bathroom joint and cleaned area',
        evidenceItems: [
          CompletionEvidenceCreateDto(
            fileUrl: SampleCompletionPhotos.repairedPlumbingJoint,
            fileType: 'image/jpeg',
          ),
          CompletionEvidenceCreateDto(
            fileUrl: SampleCompletionPhotos.rewiredCircuitSocket,
            fileType: 'image/jpeg',
          ),
        ],
      );

      final reqJson = requestDto.toJson();
      expect(reqJson['description'], equals('Repaired bathroom joint and cleaned area'));
      expect(reqJson['evidence_items'], isA<List>());
      final items = reqJson['evidence_items'] as List;
      expect(items.length, 2);
      expect(items[0]['file_url'], contains('data:image/jpeg;base64,'));

      // Test response deserialization
      final responseJson = {
        'id': 'sub-101',
        'gig_id': 'gig-101',
        'worker_id': 'worker-101',
        'description': 'Repaired bathroom joint and cleaned area',
        'submitted_at': DateTime.now().toIso8601String(),
        'evidence_files': [
          {
            'id': 'ev-1',
            'submission_id': 'sub-101',
            'file_url': SampleCompletionPhotos.repairedPlumbingJoint,
            'file_type': 'image/jpeg',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'ev-2',
            'submission_id': 'sub-101',
            'file_url': SampleCompletionPhotos.rewiredCircuitSocket,
            'file_type': 'image/jpeg',
            'created_at': DateTime.now().toIso8601String(),
          },
        ],
      };

      final subDto = CompletionSubmissionResponseDto.fromJson(responseJson);
      expect(subDto.evidenceFiles.length, 2);
      expect(subDto.evidenceFiles[0].fileUrl, contains('data:image/jpeg;base64,'));
      expect(subDto.evidenceFiles[1].fileType, equals('image/jpeg'));

      // Test GigCompletionDetailDto
      final detailDto = GigCompletionDetailDto.fromJson({
        'gig_id': 'gig-101',
        'status': 'COMPLETION_SUBMITTED',
        'submission': responseJson,
        'confirmation': null,
      });

      expect(detailDto.status, equals('COMPLETION_SUBMITTED'));
      expect(detailDto.submission?.evidenceFiles.length, 2);
    });

    test('SampleCompletionPhotos presets are defined and non-empty', () {
      expect(SampleCompletionPhotos.presets.isNotEmpty, isTrue);
      expect(SampleCompletionPhotos.repairedPlumbingJoint, contains('data:image/jpeg;base64,'));
      expect(SampleCompletionPhotos.rewiredCircuitSocket, contains('data:image/jpeg;base64,'));
      expect(SampleCompletionPhotos.plasteredCleanArea, contains('data:image/jpeg;base64,'));
    });
  });
}

