import '../models/api/api_models.dart';
import '../models/api/api_response.dart';
import '../services/api_client.dart';

class CatalogueRepository {
  final ApiClient _client;

  CatalogueRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  /// Fetch all active service categories.
  Future<List<ServiceCategoryDto>> getCategories() async {
    final response = await _client.get('/service-categories');

    final apiResponse = ApiResponse<List<ServiceCategoryDto>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => (data as List<dynamic>)
          .map((item) =>
              ServiceCategoryDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    return apiResponse.data;
  }

  /// Fetch tasks for a given category.
  Future<List<ServiceTaskDto>> getTasks(String categoryId) async {
    final response = await _client.get('/service-categories/$categoryId/tasks');

    final apiResponse = ApiResponse<List<ServiceTaskDto>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => (data as List<dynamic>)
          .map((item) => ServiceTaskDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    return apiResponse.data;
  }

  /// Calculates authoritative labour price preview and worker wage range for selected tasks.
  Future<PricePreviewDto> getPricePreview({
    required String categoryId,
    required List<String> taskIds,
  }) async {
    final response = await _client.post(
      '/gigs/price-preview',
      data: {
        'category_id': categoryId,
        'task_ids': taskIds,
      },
    );

    final apiResponse = ApiResponse<PricePreviewDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => PricePreviewDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }
}
