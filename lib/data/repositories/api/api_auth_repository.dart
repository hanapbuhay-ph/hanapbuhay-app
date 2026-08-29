import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../models/auth_result_model.dart';
import '../auth_repository.dart';

/// Real implementation of AuthRepository.
/// Note: register() and verifyOtp() are implemented.
/// login() is pending backend and currently throws UnimplementedError.
class ApiAuthRepository implements AuthRepository {
  final String baseUrl = AppConstants.apiBaseUrl;

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String mobileNumber,
    required String barangay,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        body: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'mobile_number': mobileNumber,
          'barangay': barangay,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.success(
          message: data['message'] ?? 'OTP sent',
          data: data['data'],
        );
      } else {
        return AuthResult.failure(
          message: data['message'] ?? 'Registration failed',
          errors: data['errors'],
        );
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  @override
  Future<AuthResult> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        body: {
          'email': email,
          'otp': otp,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return AuthResult.success(
          message: data['message'] ?? 'Verified',
          data: data['data'],
        );
      } else {
        return AuthResult.failure(
          message: data['message'] ?? 'Verification failed',
          errors: data['errors'],
        );
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  @override
  Future<AuthResult> login(String email, String password) {
    // PENDING BACKEND: The login endpoint is not yet live on the Laravel API.
    throw UnimplementedError('Login endpoint is pending backend implementation.');
  }

  @override
  Future<AuthResult> forgotPassword(String identifier) async {
    // MOCKED: Forgot password endpoint is pending backend implementation.
    await Future.delayed(const Duration(milliseconds: 800));
    return AuthResult.success(message: 'Code sent to $identifier');
  }

  @override
  Future<AuthResult> verifyForgotPasswordOtp(String identifier, String otp) async {
    // MOCKED: Verify forgot password OTP endpoint is pending backend implementation.
    await Future.delayed(const Duration(milliseconds: 800));
    if (otp == '123456') {
      return AuthResult.success(message: 'Code verified');
    }
    return AuthResult.failure(message: 'Invalid code');
  }

  @override
  Future<AuthResult> resetPassword(String identifier, String newPassword) async {
    // MOCKED: Reset password endpoint is pending backend implementation.
    await Future.delayed(const Duration(milliseconds: 800));
    return AuthResult.success(message: 'Password reset successful');
  }
}
