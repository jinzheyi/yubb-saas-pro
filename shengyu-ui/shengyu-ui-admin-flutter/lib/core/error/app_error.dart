class AppError {
  const AppError({required this.message, this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;
}
