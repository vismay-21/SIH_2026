import 'dart:convert';

/// Generic envelope response returned by all FastAPI endpoints
/// following `{ "data": ... }`.
class ApiResponse<T> {
  final T data;
  final String? message;

  const ApiResponse({required this.data, this.message});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic rawData) fromJsonT,
  ) {
    return ApiResponse<T>(
      data: fromJsonT(json['data']),
      message: json['message'] as String?,
    );
  }
}

/// Standard pagination metadata conforming to `PaginationMeta` in backend.
class PaginationMeta {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const PaginationMeta({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Standard paginated response conforming to `PaginatedResponse[T]` in backend.
class PaginatedResponse<T> {
  final List<T> data;
  final PaginationMeta pagination;

  const PaginatedResponse({
    required this.data,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic item) fromJsonItem,
  ) {
    final rawList = json['data'] as List<dynamic>? ?? [];
    final items = rawList.map((item) => fromJsonItem(item)).toList();
    final meta = PaginationMeta.fromJson(
      (json['pagination'] as Map<String, dynamic>?) ?? {},
    );
    return PaginatedResponse<T>(data: items, pagination: meta);
  }
}

/// Structured API error model matching FastAPI error envelopes:
/// `{ "error": { "code": "...", "message": "...", "details": {...} } }`
class ApiError implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final int? statusCode;

  const ApiError({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  factory ApiError.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    final err = json['error'];
    if (err is Map<String, dynamic>) {
      return ApiError(
        code: (err['code'] as String?) ?? 'API_ERROR',
        message: (err['message'] as String?) ?? 'An error occurred',
        details: err['details'] as Map<String, dynamic>?,
        statusCode: statusCode,
      );
    }
    // Fallback for non-standard or standard FastAPI HTTP validation errors
    if (json.containsKey('detail')) {
      final detail = json['detail'];
      final msg = detail is String ? detail : jsonEncode(detail);
      return ApiError(
        code: 'VALIDATION_ERROR',
        message: msg,
        statusCode: statusCode,
      );
    }
    return ApiError(
      code: 'UNKNOWN_ERROR',
      message: (json['message'] as String?) ?? 'Unknown error occurred',
      statusCode: statusCode,
    );
  }

  factory ApiError.network([String? customMessage]) {
    return ApiError(
      code: 'NETWORK_ERROR',
      message: customMessage ??
          'Unable to reach backend service. Please ensure the server is running.',
    );
  }

  @override
  String toString() => 'ApiError($code): $message';
}
