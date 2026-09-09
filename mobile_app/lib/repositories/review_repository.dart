import '../models/api/api_models.dart';
import '../models/api/api_response.dart';
import '../services/api_client.dart';

class ReviewRepository {
  final ApiClient _client;

  ReviewRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  /// Fetches active review questions for either CUSTOMER or WORKER.
  Future<List<ReviewQuestionDto>> getQuestions({String? targetRole}) async {
    final response = await _client.get(
      '/review-questions',
      queryParameters: targetRole != null
          ? {'target_role': targetRole.toUpperCase()}
          : null,
    );

    final apiResponse = ApiResponse<List<ReviewQuestionDto>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => (data as List<dynamic>)
          .map((item) =>
              ReviewQuestionDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    return apiResponse.data;
  }

  /// Submits a structured review for a completed gig.
  Future<ReviewDto> submitReview({
    required String gigId,
    required String revieweeId,
    required List<ReviewAnswerItemDto> answers,
    double? overallRating,
  }) async {
    final response = await _client.post(
      '/gigs/$gigId/reviews',
      data: ReviewCreateRequestDto(
        revieweeId: revieweeId,
        answers: answers,
        overallRating: overallRating,
      ).toJson(),
    );

    final apiResponse = ApiResponse<ReviewDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => ReviewDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Retrieves reviews submitted for this gig.
  Future<List<ReviewDto>> getGigReviews(String gigId) async {
    final response = await _client.get('/gigs/$gigId/reviews');

    final apiResponse = ApiResponse<List<ReviewDto>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => (data as List<dynamic>)
          .map((item) => ReviewDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    return apiResponse.data;
  }

  /// Retrieves worker metrics.
  Future<WorkerPublicMetricsDto> getWorkerMetrics(String workerId) async {
    final response = await _client.get('/workers/$workerId/metrics');

    final apiResponse = ApiResponse<WorkerPublicMetricsDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => WorkerPublicMetricsDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }
}
