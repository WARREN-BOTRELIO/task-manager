/// Mirror of the backend `ApiError` response body.
class ApiError {
  const ApiError({
    required this.status,
    required this.message,
    this.error,
    this.path,
  });

  final int status;
  final String message;
  final String? error;
  final String? path;

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        status: json['status'] as int? ?? 0,
        message: json['message'] as String? ?? 'Unexpected error',
        error: json['error'] as String?,
        path: json['path'] as String?,
      );
}

/// Error surfaced to the UI when an API call fails.
class ApiException implements Exception {
  const ApiException(this.message, {this.status});

  final String message;
  final int? status;

  @override
  String toString() => 'ApiException($status): $message';
}

/// Thrown when any request is rejected with HTTP 401.
class UnauthorizedException extends ApiException {
  const UnauthorizedException() : super('Authentication required', status: 401);
}

/// Maps any thrown error to a user-friendly, displayable message.
String errorMessage(Object error, {String fallback = 'Something went wrong'}) {
  if (error is ApiException) {
    return error.message;
  }
  return fallback;
}