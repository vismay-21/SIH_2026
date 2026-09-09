import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/api/api_response.dart';
import 'token_storage.dart';

/// Centralized HTTP client wrapper using Dio for FastAPI backend communication.
class ApiClient {
  /// Optional mock handler hook for hermetic unit and widget testing.
  static Future<Response<dynamic>?> Function(RequestOptions options)? mockHandler;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: TokenStorage.instance.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor for dynamic base URL, Bearer tokens, and error transformation
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (mockHandler != null) {
            try {
              final mockResp = await mockHandler!(options);
              if (mockResp != null) {
                return handler.resolve(mockResp);
              }
            } catch (e) {
              if (e is DioException) {
                return handler.reject(e);
              }
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: e,
                  type: DioExceptionType.unknown,
                ),
              );
            }
          }

          // Keep base URL in sync with TokenStorage configuration
          options.baseUrl = TokenStorage.instance.baseUrl;

          final token = TokenStorage.instance.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          final statusCode = e.response?.statusCode;

          // 401 Unauthorized handling: reset session
          if (statusCode == 401) {
            TokenStorage.instance.clear();
          }

          if (e.response?.data is Map<String, dynamic>) {
            final apiError = ApiError.fromJson(
              e.response!.data as Map<String, dynamic>,
              statusCode: statusCode,
            );
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                type: e.type,
                error: apiError,
                message: apiError.message,
              ),
            );
          } else if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout) {
            final netError = ApiError.network(
              'Cannot connect to backend server at ${TokenStorage.instance.baseUrl}. Ensure server is running.',
            );
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                type: e.type,
                error: netError,
                message: netError.message,
              ),
            );
          }
          return handler.next(e);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          logPrint: (obj) => debugPrint('[API] $obj'),
        ),
      );
    }
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  Dio get dio => _dio;

  /// Helper to extract structured ApiError from any caught exception
  static ApiError extractError(dynamic error) {
    if (error is ApiError) return error;
    if (error is DioException) {
      if (error.error is ApiError) {
        return error.error as ApiError;
      }
      return ApiError(
        code: error.response?.statusCode != null
            ? 'HTTP_${error.response?.statusCode}'
            : 'NETWORK_ERROR',
        message: error.message ?? 'Network connection error occurred',
        statusCode: error.response?.statusCode,
      );
    }
    return ApiError(
      code: 'UNKNOWN',
      message: error.toString(),
    );
  }

  // HTTP helper methods

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw extractError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw extractError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw extractError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw extractError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw extractError(e);
    }
  }
}
