import '../models/api/api_models.dart';
import '../models/api/api_response.dart';
import '../services/api_client.dart';

class GigRepository {
  final ApiClient _client;

  GigRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;

  /// Creates a customer gig in DRAFT status.
  Future<GigDto> createGig(GigCreateRequestDto request) async {
    final response = await _client.post(
      '/gigs',
      data: request.toJson(),
    );

    final apiResponse = ApiResponse<GigDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => GigDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Posts a DRAFT gig to SEEKING_WORKERS status, notifying eligible workers.
  Future<GigDto> postGig(String gigId) async {
    final response = await _client.post('/gigs/$gigId/post');

    final apiResponse = ApiResponse<GigDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => GigDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Retrieves gig details by ID.
  Future<GigDto> getGig(String gigId) async {
    final response = await _client.get('/gigs/$gigId');

    final apiResponse = ApiResponse<GigDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => GigDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Retrieves paginated list of customer gigs.
  Future<PaginatedResponse<GigDto>> getCustomerGigs({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (status != null) {
      query['status'] = status;
    }

    final response = await _client.get(
      '/customer/gigs',
      queryParameters: query,
    );

    return PaginatedResponse<GigDto>.fromJson(
      response.data as Map<String, dynamic>,
      (item) => GigDto.fromJson(item as Map<String, dynamic>),
    );
  }

  /// Lists accepted worker candidates for customer selection.
  Future<List<GigCandidateDto>> getCandidates(String gigId) async {
    final response = await _client.get('/gigs/$gigId/candidates');

    final apiResponse = ApiResponse<List<GigCandidateDto>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => (data as List<dynamic>)
          .map((item) => GigCandidateDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    return apiResponse.data;
  }

  /// Customer selects one worker candidate for the gig.
  Future<SelectWorkerResponseDto> selectWorker({
    required String gigId,
    required String workerId,
  }) async {
    final response = await _client.post(
      '/gigs/$gigId/select-worker',
      data: SelectWorkerRequestDto(workerId: workerId).toJson(),
    );

    final apiResponse = ApiResponse<SelectWorkerResponseDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => SelectWorkerResponseDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Retrieves completion evidence and confirmation status.
  Future<GigCompletionDetailDto> getCompletion(String gigId) async {
    final response = await _client.get('/gigs/$gigId/completion');

    final apiResponse = ApiResponse<GigCompletionDetailDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => GigCompletionDetailDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Customer confirms completion or requests rework.
  Future<CompletionConfirmationResponseDto> confirmCompletion({
    required String gigId,
    required bool confirmed,
    String? responseNote,
  }) async {
    final response = await _client.post(
      '/gigs/$gigId/completion/confirm',
      data: CompletionConfirmationRequestDto(
        confirmed: confirmed,
        responseNote: responseNote,
      ).toJson(),
    );

    final apiResponse = ApiResponse<CompletionConfirmationResponseDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => CompletionConfirmationResponseDto.fromJson(
        data as Map<String, dynamic>,
      ),
    );

    return apiResponse.data;
  }
}
