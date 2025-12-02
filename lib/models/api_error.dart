/// API Error Model
/// Represents errors returned from the server API
class ApiError implements Exception {
  final String message;
  final String code;
  final int statusCode;
  final dynamic details;

  ApiError({
    required this.message,
    required this.code,
    required this.statusCode,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final error = json['error'] ?? json;
    return ApiError(
      message: error['message'] ?? 'Unknown error',
      code: error['code'] ?? 'UNKNOWN_ERROR',
      statusCode: error['statusCode'] ?? 500,
      details: error['details'],
    );
  }

  factory ApiError.fromResponse(int statusCode, String body) {
    try {
      final json = body.isNotEmpty 
          ? Map<String, dynamic>.from(
              const {} is Map<String, dynamic> 
                ? {} 
                : {}
            )
          : <String, dynamic>{};
      return ApiError.fromJson(json);
    } catch (e) {
      return ApiError(
        message: 'Failed to parse error response',
        code: 'PARSE_ERROR',
        statusCode: statusCode,
      );
    }
  }

  /// Network-related errors
  factory ApiError.network([String? message]) {
    return ApiError(
      message: message ?? 'Network error. Please check your connection.',
      code: 'NETWORK_ERROR',
      statusCode: 0,
    );
  }

  /// Timeout errors
  factory ApiError.timeout() {
    return ApiError(
      message: 'Request timed out. Please try again.',
      code: 'TIMEOUT_ERROR',
      statusCode: 408,
    );
  }

  /// Authentication errors
  factory ApiError.unauthorized([String? message]) {
    return ApiError(
      message: message ?? 'Unauthorized. Please login again.',
      code: 'UNAUTHORIZED',
      statusCode: 401,
    );
  }

  /// Forbidden errors
  factory ApiError.forbidden([String? message]) {
    return ApiError(
      message: message ?? 'You do not have permission to perform this action.',
      code: 'FORBIDDEN',
      statusCode: 403,
    );
  }

  /// Not found errors
  factory ApiError.notFound([String? message]) {
    return ApiError(
      message: message ?? 'Resource not found.',
      code: 'NOT_FOUND',
      statusCode: 404,
    );
  }

  /// Server errors
  factory ApiError.server([String? message]) {
    return ApiError(
      message: message ?? 'Server error. Please try again later.',
      code: 'SERVER_ERROR',
      statusCode: 500,
    );
  }

  /// Validation errors
  factory ApiError.validation(String message, [dynamic details]) {
    return ApiError(
      message: message,
      code: 'VALIDATION_ERROR',
      statusCode: 400,
      details: details,
    );
  }

  bool get isNetworkError => code == 'NETWORK_ERROR';
  bool get isTimeoutError => code == 'TIMEOUT_ERROR';
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
  bool get isValidationError => code == 'VALIDATION_ERROR';

  /// Get user-friendly message
  String get userMessage {
    switch (code) {
      case 'NETWORK_ERROR':
        return 'Không thể kết nối mạng. Vui lòng kiểm tra kết nối.';
      case 'TIMEOUT_ERROR':
        return 'Yêu cầu quá thời gian. Vui lòng thử lại.';
      case 'UNAUTHORIZED':
      case 'TOKEN_EXPIRED':
      case 'INVALID_TOKEN':
        return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      case 'FORBIDDEN':
        return 'Bạn không có quyền thực hiện thao tác này.';
      case 'NOT_FOUND':
      case 'ROUTE_NOT_FOUND':
        return 'Không tìm thấy dữ liệu.';
      case 'VALIDATION_ERROR':
        return message;
      case 'EMAIL_EXISTS':
        return 'Email đã được đăng ký.';
      case 'INVALID_CREDENTIALS':
        return 'Email hoặc mật khẩu không đúng.';
      case 'USER_NOT_FOUND':
        return 'Không tìm thấy người dùng.';
      case 'WORKSPACE_NOT_FOUND':
        return 'Không tìm thấy workspace.';
      case 'BOARD_NOT_FOUND':
        return 'Không tìm thấy bảng.';
      case 'TASK_NOT_FOUND':
        return 'Không tìm thấy task.';
      case 'DUPLICATE_ENTRY':
        return 'Dữ liệu đã tồn tại.';
      case 'CONSTRAINT_VIOLATION':
        return 'Vi phạm ràng buộc dữ liệu.';
      case 'REQUIRED_FIELD':
        return 'Thiếu trường bắt buộc.';
      case 'SERVER_ERROR':
      default:
        if (isServerError) {
          return 'Lỗi máy chủ. Vui lòng thử lại sau.';
        }
        return message;
    }
  }

  /// Get validation field errors (if any)
  Map<String, String>? get fieldErrors {
    if (!isValidationError || details == null) return null;
    
    try {
      if (details is List) {
        final errors = <String, String>{};
        for (var error in details) {
          if (error is Map) {
            final field = error['param'] ?? error['field'];
            final msg = error['msg'] ?? error['message'];
            if (field != null && msg != null) {
              errors[field.toString()] = msg.toString();
            }
          }
        }
        return errors.isNotEmpty ? errors : null;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  @override
  String toString() {
    return 'ApiError{message: $message, code: $code, statusCode: $statusCode}';
  }

  /// Convert to JSON (for logging)
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'code': code,
      'statusCode': statusCode,
      if (details != null) 'details': details,
    };
  }
}
