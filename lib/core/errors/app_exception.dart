/// A user-facing application error with metadata for programmatic handling.
class AppException implements Exception {
  const AppException(
    this.message, {
    this.statusCode,
    this.isUnauthorized = false,
    this.isNetwork = false,
  });

  final String message;
  final int? statusCode;
  final bool isUnauthorized;
  final bool isNetwork;

  @override
  String toString() => message;
}
