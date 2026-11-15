/// Standard backend envelope: `{ success, message, statusCode, data }`.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    required this.statusCode,
    this.data,
  });

  final bool success;
  final String message;
  final int statusCode;
  final T? data;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Map<String, dynamic>)? dataParser,
  }) {
    final dataJson = json['data'];
    T? data;
    if (dataParser != null && dataJson is Map<String, dynamic>) {
      data = dataParser(dataJson);
    }
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      statusCode: json['statusCode'] as int? ?? 0,
      data: data,
    );
  }
}
