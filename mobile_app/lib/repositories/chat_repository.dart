import '../models/api/api_models.dart';
import '../models/api/api_response.dart';
import '../services/api_client.dart';

class ChatRepository {
  final ApiClient _client;

  ChatRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;

  /// Retrieves or initializes the job-scoped conversation thread.
  Future<ConversationDto> getConversation(String gigId) async {
    final response = await _client.get('/gigs/$gigId/conversation');

    final apiResponse = ApiResponse<ConversationDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => ConversationDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Retrieves messages in a gig conversation with pagination.
  Future<ConversationMessagesDto> getMessages(
    String gigId, {
    int limit = 50,
    String? before,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (before != null) {
      query['before'] = before;
    }

    final response = await _client.get(
      '/gigs/$gigId/conversation/messages',
      queryParameters: query,
    );

    final apiResponse = ApiResponse<ConversationMessagesDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => ConversationMessagesDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }

  /// Sends a text message to the gig conversation.
  Future<MessageDto> sendMessage(String gigId, String messageText) async {
    final response = await _client.post(
      '/gigs/$gigId/conversation/messages',
      data: MessageCreateRequestDto(messageText: messageText).toJson(),
    );

    final apiResponse = ApiResponse<MessageDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => MessageDto.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse.data;
  }
}
