class RepositoryException implements Exception {
  final String message;
  final String? code;
  final Object? cause;

  const RepositoryException({
    required this.message,
    this.code,
    this.cause,
  });

  @override
  String toString() =>
      'RepositoryException(code: $code, message: $message, cause: $cause)';
}
