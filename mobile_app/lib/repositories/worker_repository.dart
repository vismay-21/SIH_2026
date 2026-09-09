import '../models/api/api_models.dart';
import '../models/api/api_response.dart';
import '../services/api_client.dart';

class WorkerRepository {
  final ApiClient _client;

  WorkerRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  /// Retrieves worker opportunities with personalized exact wage snapshots.
  Future<PaginatedResponse<OpportunityDto>> getOpportunities({
    String? categoryId,
    String? status,
    bool? isEmergency,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (categoryId != null) {
      query['category_id'] = categoryId;
    }
    if (status != null) {
      query['status'] = status;
    }
    if (isEmergency != null) {
      query['is_emergency'] = isEmergency;
    }

    final response = await _client.get(
      '/worker/opportunities',
      queryParameters: query,
    );

    return PaginatedResponse<OpportunityDto>.fromJson(
      response.data as Map<String, dynamic>,
      (item) => OpportunityDto.fromJson(item as Map<String, dynamic>),
    );
  }

  /// Retrieves specific opportunity details.
  Future<OpportunityDto> getOpportunity(String opportunityId) async {
    final response = await _client.get('/worker/opportunities/$opportunityId');

    final apiResponse = ApiResponse<OpportunityDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => OpportunityDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Accept an opportunity.
  Future<OpportunityDto> acceptOpportunity(String opportunityId) async {
    final response = await _client.post(
      '/worker/opportunities/$opportunityId/accept',
    );

    final apiResponse = ApiResponse<OpportunityDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => OpportunityDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Reject an opportunity.
  Future<OpportunityDto> rejectOpportunity(String opportunityId) async {
    final response = await _client.post(
      '/worker/opportunities/$opportunityId/reject',
    );

    final apiResponse = ApiResponse<OpportunityDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => OpportunityDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Retrieves assigned gigs for the worker filtered by tab (active, upcoming, completed).
  Future<PaginatedResponse<WorkerGigListItemDto>> getWorkerGigs({
    String? tab,
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (tab != null) {
      query['tab'] = tab;
    }
    if (status != null) {
      query['status'] = status;
    }

    final response = await _client.get(
      '/worker/gigs',
      queryParameters: query,
    );

    return PaginatedResponse<WorkerGigListItemDto>.fromJson(
      response.data as Map<String, dynamic>,
      (item) => WorkerGigListItemDto.fromJson(item as Map<String, dynamic>),
    );
  }

  /// Worker marks work as started ("Arrived & Start Work").
  Future<StartWorkResponseDto> startWork(String gigId) async {
    final response = await _client.post('/gigs/$gigId/start');

    final apiResponse = ApiResponse<StartWorkResponseDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => StartWorkResponseDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Worker submits completion notes and evidence photo items.
  Future<CompletionSubmissionResponseDto> submitCompletion({
    required String gigId,
    String? description,
    required List<CompletionEvidenceCreateDto> evidenceItems,
  }) async {
    final response = await _client.post(
      '/gigs/$gigId/completion',
      data: CompletionSubmissionRequestDto(
        description: description,
        evidenceItems: evidenceItems,
      ).toJson(),
    );

    final apiResponse = ApiResponse<CompletionSubmissionResponseDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) =>
          CompletionSubmissionResponseDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Retrieves public performance metrics for a worker.
  Future<WorkerPublicMetricsDto> getMetrics(String workerId) async {
    final response = await _client.get('/workers/$workerId/metrics');

    final apiResponse = ApiResponse<WorkerPublicMetricsDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => WorkerPublicMetricsDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }
}
