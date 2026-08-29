class AuthResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? errors;

  AuthResult({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory AuthResult.success({String message = 'Success', Map<String, dynamic>? data}) {
    return AuthResult(
      success: true,
      message: message,
      data: data,
    );
  }

  factory AuthResult.failure({required String message, Map<String, dynamic>? errors}) {
    return AuthResult(
      success: false,
      message: message,
      errors: errors,
    );
  }
}
