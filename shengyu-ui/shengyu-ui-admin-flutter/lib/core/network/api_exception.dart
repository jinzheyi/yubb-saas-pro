class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.details});

  final int code;
  final String message;
  final Object? details;

  @override
  String toString() {
    return 'ApiException(code: $code, message: $message)';
  }
}
