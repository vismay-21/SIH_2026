import '../models/api/api_models.dart';
import '../models/api/api_response.dart';
import '../services/api_client.dart';

class NotificationRepository {
  final ApiClient _client;

  NotificationRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  /// Retrieves user in-app notifications with unread metrics.
  Future<NotificationListDto> getNotifications({
    bool? isRead,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (isRead != null) {
      query['is_read'] = isRead;
    }
    if (type != null) {
      query['type'] = type;
    }

    final response = await _client.get(
      '/notifications',
      queryParameters: query,
    );

    final apiResponse = ApiResponse<NotificationListDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => NotificationListDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Marks a specific notification as read.
  Future<NotificationDto> markAsRead(String notificationId) async {
    final response = await _client.post('/notifications/$notificationId/read');

    final apiResponse = ApiResponse<NotificationDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => NotificationDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Marks all unread notifications for the user as read.
  Future<NotificationReadAllDto> markAllAsRead() async {
    final response = await _client.post('/notifications/read-all');

    final apiResponse = ApiResponse<NotificationReadAllDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => NotificationReadAllDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }
}
