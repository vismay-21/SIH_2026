import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../models/api/api_models.dart';

/// Centralized token and session state storage.
/// In production or web/desktop/mobile, manages active token, authenticated user,
/// and configurable base URL.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  String? _token;
  UserDto? _currentUser;
  String? _currentRole; // 'customer' or 'worker'
  String? _customBaseUrl;

  final ValueNotifier<String?> tokenNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<UserDto?> userNotifier = ValueNotifier<UserDto?>(null);

  /// Determine default API base URL based on platform:
  /// - Android emulator uses 10.0.2.2 to reach host machine's localhost:8000
  /// - iOS simulator, desktop (Windows/macOS/Linux), and Web use localhost:8000
  String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api/v1';
      }
    } catch (_) {
      // Platform may throw on unsupported web targets
    }
    return 'http://localhost:8000/api/v1';
  }

  String get baseUrl => _customBaseUrl ?? defaultBaseUrl;

  void setBaseUrl(String url) {
    _customBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  UserDto? get currentUser => _currentUser;
  String? get currentRole => _currentRole ?? _currentUser?.role;

  void setSession({
    required String token,
    required UserDto user,
    String? role,
  }) {
    _token = token;
    _currentUser = user;
    _currentRole = role ?? user.role;
    tokenNotifier.value = token;
    userNotifier.value = user;
  }

  void updateCurrentUser(UserDto user) {
    _currentUser = user;
    userNotifier.value = user;
  }

  void clear() {
    _token = null;
    _currentUser = null;
    _currentRole = null;
    tokenNotifier.value = null;
    userNotifier.value = null;
  }
}
