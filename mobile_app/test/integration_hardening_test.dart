import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/models/api/api_models.dart';
import 'package:mobile_app/models/api/api_response.dart';
import 'package:mobile_app/models/customer_gig_workflow.dart';
import 'package:mobile_app/models/worker_job_workflow.dart';
import 'package:mobile_app/repositories/catalogue_repository.dart';
import 'package:mobile_app/services/api_client.dart';
import 'package:mobile_app/services/token_storage.dart';

void main() {
  group('Integration Hardening — Sprint 15 Tests', () {
    setUp(() {
      TokenStorage.instance.clear();
    });

    tearDown(() {
      TokenStorage.instance.clear();
    });

    // =========================================================================
    // 1. API ENVELOPE PARSING
    // =========================================================================
    test('ApiResponse parses standard success envelope correctly', () {
      final json = {
        'data': {
          'id': 'cat-1',
          'name': 'Plumbing',
          'description': 'Water pipes and leaks',
        },
        'message': 'Category retrieved successfully',
      };

      final response = ApiResponse<ServiceCategoryDto>.fromJson(
        json,
        (data) => ServiceCategoryDto.fromJson(data as Map<String, dynamic>),
      );

      expect(response.message, 'Category retrieved successfully');
      expect(response.data.id, 'cat-1');
      expect(response.data.name, 'Plumbing');
      expect(response.data.description, 'Water pipes and leaks');
    });

    test('PaginatedResponse parses metadata and items envelope', () {
      final json = {
        'data': [
          {
            'id': 'demo-user-1',
            'email': 'customer1@example.com',
            'full_name': 'Bhagya Rao',
            'role': 'customer',
            'is_active': true,
          },
          {
            'id': 'demo-user-2',
            'email': 'worker1@example.com',
            'full_name': 'Ravi Kumar',
            'role': 'worker',
            'is_active': true,
          },
        ],
        'pagination': {
          'total': 42,
          'page': 2,
          'page_size': 2,
          'total_pages': 21,
        },
      };

      final paginated = PaginatedResponse<DemoUserItem>.fromJson(
        json,
        (item) => DemoUserItem.fromJson(item as Map<String, dynamic>),
      );

      expect(paginated.data.length, 2);
      expect(paginated.pagination.total, 42);
      expect(paginated.pagination.page, 2);
      expect(paginated.pagination.pageSize, 2);
      expect(paginated.pagination.totalPages, 21);
      expect(paginated.data[0].fullName, 'Bhagya Rao');
      expect(paginated.data[1].role, 'worker');
    });

    // =========================================================================
    // 2. ERROR ENVELOPE PARSING
    // =========================================================================
    test('ApiError parses structured backend error envelope', () {
      final errorJson = {
        'error': {
          'code': 'GIG_NOT_COMPLETED',
          'message': 'Cannot submit review until gig is completed',
          'details': {
            'current_status': 'IN_PROGRESS',
            'required_status': 'COMPLETED',
          },
        },
      };

      final apiError = ApiError.fromJson(errorJson, statusCode: 409);

      expect(apiError.code, 'GIG_NOT_COMPLETED');
      expect(apiError.message, 'Cannot submit review until gig is completed');
      expect(apiError.statusCode, 409);
      expect(apiError.details?['current_status'], 'IN_PROGRESS');
      expect(apiError.statusCode == 409, isTrue);
      expect(apiError.statusCode == 401, isFalse);
    });

    test('ApiError handles 401 Unauthorized correctly', () {
      final errorJson = {
        'error': {
          'code': 'INVALID_TOKEN',
          'message': 'JWT signature verification failed',
        },
      };

      final apiError = ApiError.fromJson(errorJson, statusCode: 401);
      expect(apiError.statusCode == 401, isTrue);
      expect(apiError.statusCode == 404, isFalse);
    });

    test('ApiError handles FastAPI validation 422 error list', () {
      final validationJson = {
        'detail': [
          {
            'loc': ['body', 'payment_method'],
            'msg': 'Input should be CASH or UPI',
            'type': 'enum',
          },
        ],
      };

      final apiError = ApiError.fromJson(validationJson, statusCode: 422);
      expect(apiError.code, 'VALIDATION_ERROR');
      expect(apiError.message, contains('Input should be CASH or UPI'));
      expect(apiError.statusCode, 422);
    });

    // =========================================================================
    // 3. UUID / NUM / NULL / DECIMAL DTO PARSING
    // =========================================================================
    test('PricePreviewDto parses Decimal, num, and task breakdown faithfully', () {
      final json = {
        'category_id': 'cat-123',
        'category_name': 'Plumbing',
        'base_rate_per_minute': 5.5,
        'minimum_billable_minutes': 60,
        'total_standard_duration_minutes': 120,
        'billable_duration_minutes': 120,
        'base_price': 660.0,
        'tasks': [
          {
            'id': 't-1',
            'name': 'Tap Leak Repair',
            'standard_duration_minutes': 60,
            'base_price': 330.0,
            'complexity_score': 1.0,
          },
        ],
        'estimated_wage_range': {
          'min_wage': 550.0,
          'rookie_wage': 600.0,
          'max_wage': 750.0,
        },
      };

      final dto = PricePreviewDto.fromJson(json);

      expect(dto.categoryId, 'cat-123');
      expect(dto.basePrice, 660.0);
      expect(dto.baseRatePerMinute, 5.5);
      expect(dto.tasks.length, 1);
      expect(dto.tasks[0].name, 'Tap Leak Repair');
      expect(dto.estimatedWageRange.rookieWage, 600.0);
    });

    test('UserDto parses UUID, nulls, and role normalization', () {
      final json = {
        'id': 'b1c2d3e4-5678-90ab-cdef-1234567890ab',
        'email': 'customer@example.com',
        'phone_number': null,
        'full_name': 'Kavita Devi',
        'role': 'CUSTOMER',
        'is_active': true,
        'created_at': '2026-09-10T01:00:00Z',
      };

      final user = UserDto.fromJson(json);

      expect(user.id, 'b1c2d3e4-5678-90ab-cdef-1234567890ab');
      expect(user.email, 'customer@example.com');
      expect(user.phoneNumber, isNull);
      expect(user.role, 'customer');
      expect(user.isActive, isTrue);
      expect(user.createdAt, isNotNull);
    });

    // =========================================================================
    // 4. NESTED DTO PARSING
    // =========================================================================
    test('GigDto parses nested tasks and price breakdown', () {
      final json = {
        'id': 'gig-uuid-123',
        'customer_id': 'cust-uuid-456',
        'cooperative_id': 'coop-uuid-789',
        'category_id': 'cat-plumbing-789',
        'category_name': 'Plumbing',
        'gig_type': 'STANDARD',
        'description': 'Fix drain trap and tighten pipe threads',
        'instructions': 'Gate code 4321',
        'address': 'MG Road, Bangalore',
        'latitude': 12.9716,
        'longitude': 77.5946,
        'scheduled_date': '2026-09-12',
        'scheduled_start_time': '10:00',
        'scheduled_end_time': '12:00',
        'expected_duration_minutes': 120,
        'status': 'IN_PROGRESS',
        'base_price': 650.0,
        'is_emergency': false,
        'material_procurement_mode': 'CUSTOMER_PURCHASES',
        'selected_worker_id': 'worker-uuid-999',
        'created_at': '2026-09-10T00:00:00Z',
        'updated_at': '2026-09-10T01:00:00Z',
        'tasks': [
          {
            'id': 'task-item-1',
            'task_id': 'task-def-1',
            'task_name': 'Trap cleaning & seal replacement',
            'standard_duration_minutes_snapshot': 90,
            'base_price_snapshot': 650.0,
          },
        ],
      };

      final gig = GigDto.fromJson(json);

      expect(gig.id, 'gig-uuid-123');
      expect(gig.status, 'IN_PROGRESS');
      expect(gig.basePrice, 650.0);
      expect(gig.tasks.length, 1);
      expect(gig.tasks[0].taskName, 'Trap cleaning & seal replacement');
      expect(gig.tasks[0].basePriceSnapshot, 650.0);
      expect(gig.selectedWorkerId, 'worker-uuid-999');
    });

    test('OpportunityDto parses nested OpportunityGigDto and task items', () {
      final json = {
        'id': 'opp-uuid-101',
        'gig_id': 'gig-uuid-123',
        'worker_id': 'worker-uuid-999',
        'status': 'OFFERED',
        'base_price': 650.0,
        'base_price_snapshot': 650.0,
        'final_score_snapshot': 0.92,
        'premium_percentage': 0.05,
        'exact_wage': 682.50,
        'offered_at': '2026-09-10T02:00:00Z',
        'gig': {
          'id': 'gig-uuid-123',
          'category_id': 'cat-plumbing-789',
          'category_name': 'Plumbing',
          'gig_type': 'STANDARD',
          'description': 'Leak fix',
          'address': 'MG Road',
          'material_procurement_mode': 'CUSTOMER_PURCHASES',
          'tasks': [
            {
              'id': 'task-item-1',
              'task_id': 'task-def-1',
              'task_name': 'Trap cleaning',
              'quantity': 1,
              'base_rate_per_minute': 5.0,
              'estimated_duration_minutes': 60,
            },
          ],
        },
      };

      final opp = OpportunityDto.fromJson(json);

      expect(opp.id, 'opp-uuid-101');
      expect(opp.exactWage, 682.50);
      expect(opp.gig.categoryName, 'Plumbing');
      expect(opp.gig.tasks.length, 1);
    });

    test('GigCompletionDetailDto parses nested submission and evidence files', () {
      final json = {
        'gig_id': 'gig-uuid-123',
        'status': 'COMPLETION_SUBMITTED',
        'submission': {
          'id': 'sub-uuid-1',
          'gig_id': 'gig-uuid-123',
          'worker_id': 'worker-uuid-999',
          'description': 'Repaired pipe and checked water flow.',
          'submitted_at': '2026-09-10T04:00:00Z',
          'evidence_files': [
            {
              'id': 'ev-1',
              'submission_id': 'sub-uuid-1',
              'file_url': 'https://s3.example.com/evidence1.jpg',
              'file_type': 'image/jpeg',
            },
          ],
        },
        'confirmation': null,
      };

      final detail = GigCompletionDetailDto.fromJson(json);

      expect(detail.gigId, 'gig-uuid-123');
      expect(detail.status, 'COMPLETION_SUBMITTED');
      expect(detail.submission, isNotNull);
      expect(detail.submission!.evidenceFiles.length, 1);
      expect(detail.submission!.evidenceFiles[0].fileUrl, contains('evidence1.jpg'));
      expect(detail.confirmation, isNull);
    });

    // =========================================================================
    // 5. REPOSITORY REQUEST CONSTRUCTION & SERIALIZATION
    // =========================================================================
    test('DevLoginRequest serializes to compliant backend JSON', () {
      const req = DevLoginRequest(
        email: 'customer1@example.com',
        password: 'securepassword123',
        role: 'customer',
      );

      final json = req.toJson();

      expect(json['email'], 'customer1@example.com');
      expect(json['password'], 'securepassword123');
      expect(json['role'], 'CUSTOMER');
    });

    test('GigCreateRequestDto serializes all required backend parameters', () {
      final req = GigCreateRequestDto(
        categoryId: 'cat-electrical',
        description: 'Install 2 ceiling fans in bedrooms',
        instructions: 'Call upon arrival',
        address: 'Whitefield, Bangalore',
        scheduledDate: '2026-09-15',
        scheduledStartTime: '11:00',
        expectedDurationMinutes: 90,
        materialProcurementMode: 'WORKER_PURCHASES',
        taskIds: const ['task-fan-install'],
      );

      final json = req.toJson();

      expect(json['category_id'], 'cat-electrical');
      expect(json['description'], 'Install 2 ceiling fans in bedrooms');
      expect(json['material_procurement_mode'], 'WORKER_PURCHASES');
      expect(json['task_ids'], ['task-fan-install']);
    });

    test('PaymentCreateRequestDto serializes payment_method strictly', () {
      const upiReq = PaymentCreateRequestDto(paymentMethod: 'UPI');
      expect(upiReq.toJson(), {'payment_method': 'UPI'});

      const cashReq = PaymentCreateRequestDto(paymentMethod: 'CASH');
      expect(cashReq.toJson(), {'payment_method': 'CASH'});
    });

    test('ReviewCreateRequestDto serializes answers list correctly', () {
      const req = ReviewCreateRequestDto(
        revieweeId: 'worker-123',
        overallRating: 5.0,
        answers: [
          ReviewAnswerItemDto(questionId: 'q-punctuality', answerValue: 5),
          ReviewAnswerItemDto(questionId: 'q-quality', answerValue: 5),
        ],
      );

      final json = req.toJson();

      expect(json['reviewee_id'], 'worker-123');
      expect(json['overall_rating'], 5.0);
      expect(json['answers'], isA<List<dynamic>>());
      expect((json['answers'] as List<dynamic>).length, 2);
      expect((json['answers'] as List<dynamic>)[0]['question_id'], 'q-punctuality');
      expect((json['answers'] as List<dynamic>)[0]['answer_value'], 5);
    });

    // =========================================================================
    // 6. AUTHENTICATION & TOKEN HANDLING
    // =========================================================================
    test('TokenStorage manages session token, user, and role correctly', () {
      expect(TokenStorage.instance.isAuthenticated, isFalse);

      const user = UserDto(
        id: 'usr-123',
        email: 'bhagya@example.com',
        fullName: 'Bhagya Rao',
        role: 'customer',
      );

      TokenStorage.instance.setSession(
        token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
        user: user,
        role: 'customer',
      );

      expect(TokenStorage.instance.isAuthenticated, isTrue);
      expect(TokenStorage.instance.token, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test');
      expect(TokenStorage.instance.currentRole, 'customer');
      expect(TokenStorage.instance.currentUser?.fullName, 'Bhagya Rao');

      TokenStorage.instance.clear();

      expect(TokenStorage.instance.isAuthenticated, isFalse);
      expect(TokenStorage.instance.token, isNull);
      expect(TokenStorage.instance.currentUser, isNull);
    });

    // =========================================================================
    // 7. CHAT & NOTIFICATIONS
    // =========================================================================
    test('MessageDto parses conversation messages accurately', () {
      final json = {
        'id': 'msg-uuid-1',
        'conversation_id': 'conv-uuid-1',
        'sender_id': 'usr-customer-1',
        'sender_role': 'customer',
        'sender_name': 'Bhagya Rao',
        'message_text': 'Hello, I have left the spare key with security.',
        'is_read': false,
        'created_at': '2026-09-10T02:30:00Z',
      };

      final msg = MessageDto.fromJson(json);

      expect(msg.id, 'msg-uuid-1');
      expect(msg.senderRole, 'customer');
      expect(msg.messageText, contains('spare key'));
      expect(msg.isRead, isFalse);
    });

    test('NotificationDto parses action URLs and read state', () {
      final json = {
        'id': 'notif-1',
        'recipient_id': 'usr-123',
        'type': 'WORKER_SELECTED',
        'title': 'You were selected!',
        'body': 'Customer selected you for Bathroom Sink Leak Repair.',
        'action_url': '/gigs/gig-uuid-123',
        'is_read': false,
        'created_at': '2026-09-10T01:30:00Z',
      };

      final notif = NotificationDto.fromJson(json);

      expect(notif.id, 'notif-1');
      expect(notif.type, 'WORKER_SELECTED');
      expect(notif.isRead, isFalse);
      expect(notif.actionUrl, '/gigs/gig-uuid-123');
    });

    // =========================================================================
    // 8. WORKER METRICS & REVIEWS
    // =========================================================================
    test('WorkerPublicMetricsDto parses rating average and completed gigs', () {
      final json = {
        'worker_id': 'worker-uuid-999',
        'rating_average': 4.85,
        'rating_count': 32,
        'completed_jobs_count': 35,
        'final_score': 0.94,
      };

      final metrics = WorkerPublicMetricsDto.fromJson(json);

      expect(metrics.workerId, 'worker-uuid-999');
      expect(metrics.ratingAverage, 4.85);
      expect(metrics.ratingCount, 32);
      expect(metrics.completedJobsCount, 35);
      expect(metrics.finalScore, 0.94);
    });

    test('ReviewQuestionDto parses target_role and scale', () {
      final json = {
        'id': 'q-punctuality',
        'question_text': 'Was the worker on time?',
        'target_role': 'WORKER',
        'display_order': 1,
        'is_active': true,
      };

      final question = ReviewQuestionDto.fromJson(json);

      expect(question.id, 'q-punctuality');
      expect(question.targetRole, 'WORKER');
      expect(question.questionText, 'Was the worker on time?');
      expect(question.displayOrder, 1);
    });

    // =========================================================================
    // 9. CLIENT WORKFLOW MODEL ADAPTERS
    // =========================================================================
    test('CustomerGig.fromDto maps GigDto into CustomerGig workflow model', () {
      final gigDto = GigDto(
        id: 'gig-123',
        customerId: 'cust-1',
        cooperativeId: 'coop-1',
        categoryId: 'cat-plumbing',
        categoryName: 'Plumbing',
        gigType: 'STANDARD',
        description: 'Water leaking from tap',
        address: 'Koramangala, Bangalore',
        scheduledDate: '2026-09-11',
        scheduledStartTime: '3:00 PM',
        expectedDurationMinutes: 60,
        status: 'IN_PROGRESS',
        basePrice: 450.0,
        isEmergency: false,
        materialProcurementMode: 'CUSTOMER_PURCHASES',
        tasks: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customerGig = CustomerGig.fromDto(gigDto);

      expect(customerGig.id, 'gig-123');
      expect(customerGig.title, 'Plumbing');
      expect(customerGig.category, 'Plumbing');
      expect(customerGig.stage, GigStage.active);
    });

    test('WorkerOpportunity.fromDto maps OpportunityDto into WorkerOpportunity model', () {
      final oppDto = OpportunityDto(
        id: 'opp-101',
        gigId: 'gig-202',
        workerId: 'worker-303',
        status: 'OFFERED',
        basePrice: 500.0,
        basePriceSnapshot: 500.0,
        finalScoreSnapshot: 0.95,
        premiumPercentage: 0.10,
        exactWage: 550.0,
        offeredAt: DateTime.now(),
        gig: const OpportunityGigDto(
          id: 'gig-202',
          categoryId: 'cat-cleaning',
          categoryName: 'Deep Cleaning',
          gigType: 'STANDARD',
          description: 'Full kitchen cleaning',
          address: 'HSR Layout, Bangalore',
          materialProcurementMode: 'CUSTOMER_PURCHASES',
          tasks: [],
        ),
      );

      final workerOpp = WorkerOpportunity.fromDto(oppDto);

      expect(workerOpp.id, 'opp-101');
      expect(workerOpp.gigId, 'gig-202');
      expect(workerOpp.title, 'Deep Cleaning');
      expect(workerOpp.wage, '₹550');
    });

    // =========================================================================
    // 5. PAYMENT DECIMAL PARSING & CATALOGUE ROUTE TESTS
    // =========================================================================
    test('PaymentDto correctly parses Decimal string, numeric, and missing amount', () {
      final jsonStringAmount = {
        'id': 'pay-1',
        'gig_id': 'gig-1',
        'customer_id': 'cust-1',
        'worker_id': 'work-1',
        'amount': '225.50',
        'payment_method': 'UPI',
        'payment_type': 'LABOUR',
        'status': 'PENDING',
      };
      final dtoFromString = PaymentDto.fromJson(jsonStringAmount);
      expect(dtoFromString.amount, 225.50);

      final jsonNumAmount = {
        'id': 'pay-2',
        'gig_id': 'gig-1',
        'customer_id': 'cust-1',
        'worker_id': 'work-1',
        'amount': 225.50,
        'status': 'PENDING',
      };
      final dtoFromNum = PaymentDto.fromJson(jsonNumAmount);
      expect(dtoFromNum.amount, 225.50);

      final jsonMissingAmount = {
        'id': 'pay-3',
        'gig_id': 'gig-1',
        'customer_id': 'cust-1',
        'worker_id': 'work-1',
        'amount': null,
        'status': 'PENDING',
      };
      final dtoFromMissing = PaymentDto.fromJson(jsonMissingAmount);
      expect(dtoFromMissing.amount, 0.0);
    });

    test('CatalogueRepository calls /service-categories and /service-categories/{id}/tasks', () async {
      final requestedPaths = <String>[];

      ApiClient.mockHandler = (options) async {
        requestedPaths.add(options.path);
        if (options.path == '/service-categories') {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': [
                {
                  'id': 'cat-1',
                  'name': 'Plumbing',
                  'base_rate_per_minute': 5.0,
                  'minimum_billable_minutes': 45,
                  'is_active': true,
                }
              ]
            },
          );
        } else if (options.path == '/service-categories/cat-1/tasks') {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'data': [
                {
                  'id': 'task-1',
                  'category_id': 'cat-1',
                  'name': 'Fix tap',
                  'standard_duration_minutes': 30,
                  'base_price': 150.0,
                  'complexity_score': 1.0,
                  'complexity_bucket': 'LOW',
                  'is_active': true,
                }
              ]
            },
          );
        }
        return null;
      };

      try {
        final repo = CatalogueRepository();
        final cats = await repo.getCategories();
        expect(cats.length, 1);
        expect(requestedPaths, contains('/service-categories'));

        final tasks = await repo.getTasks('cat-1');
        expect(tasks.length, 1);
        expect(requestedPaths, contains('/service-categories/cat-1/tasks'));
      } finally {
        ApiClient.mockHandler = null;
      }
    });
  });
}

