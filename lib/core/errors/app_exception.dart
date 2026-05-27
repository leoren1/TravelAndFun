sealed class AppException implements Exception {
  final String message;
  final String? code;
  const AppException({required this.message, this.code});

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

final class NetworkException extends AppException {
  const NetworkException({required super.message, super.code});
}

final class StorageException extends AppException {
  const StorageException({required super.message, super.code});
}

final class PermissionException extends AppException {
  const PermissionException({required super.message, super.code});
}

final class ValidationException extends AppException {
  const ValidationException({required super.message, super.code});
}

final class NotFoundException extends AppException {
  const NotFoundException({required super.message, super.code});
}
