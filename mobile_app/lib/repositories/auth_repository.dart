import '../models/api/api_models.dart';
import '../models/api/api_response.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';

class AuthRepository {
  final ApiClient _client;

  AuthRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;

  /// Logs in using the development authentication endpoint.
  /// Automatically stores the session token and current user.
  Future<DevLoginResponse> login({
    required String email,
    required String password,
    String? role,
  }) async {
    final response = await _client.post(
      '/auth/login',
      data: DevLoginRequest(
        email: email,
        password: password,
        role: role,
      ).toJson(),
    );

    final apiResponse = ApiResponse<DevLoginResponse>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => DevLoginResponse.fromJson(data as Map<String, dynamic>),
    );

    TokenStorage.instance.setSession(
      token: apiResponse.data.token,
      user: apiResponse.data.user,
      role: role ?? apiResponse.data.user.role,
    );

    return apiResponse.data;
  }

  /// Retrieves list of pre-seeded development demo accounts.
  Future<List<DemoUserItem>> getDemoUsers() async {
    final response = await _client.get('/auth/demo-users');

    final apiResponse = ApiResponse<List<DemoUserItem>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => (data as List<dynamic>)
          .map((item) => DemoUserItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    return apiResponse.data;
  }

  /// Retrieves current active user profile and refreshes session cache.
  Future<UserDto> getMe() async {
    final response = await _client.get('/me');

    final apiResponse = ApiResponse<UserDto>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => UserDto.fromJson(data as Map<String, dynamic>),
    );

    TokenStorage.instance.updateCurrentUser(apiResponse.data);
    return apiResponse.data;
  }

  /// Clears stored JWT token and user session.
  void logout() {
    TokenStorage.instance.clear();
  }
}
