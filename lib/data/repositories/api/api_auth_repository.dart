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
    // TODO: This endpoint is not yet live on the backend.
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password/forgot'),
        body: {'identifier': identifier},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return AuthResult.success(message: data['message'] ?? 'Code sent');
      } else {
        return AuthResult.failure(message: data['message'] ?? 'Failed to send code');
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  @override
  Future<AuthResult> verifyForgotPasswordOtp(String identifier, String otp) async {
    // TODO: This endpoint is not yet live on the backend.
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password/verify-otp'),
        body: {
          'identifier': identifier,
          'otp': otp,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return AuthResult.success(message: data['message'] ?? 'Code verified');
      } else {
        return AuthResult.failure(message: data['message'] ?? 'Invalid code');
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  @override
  Future<AuthResult> resetPassword(String identifier, String newPassword) async {
    // TODO: This endpoint is not yet live on the backend.
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password/reset'),
        body: {
          'identifier': identifier,
          'password': newPassword,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return AuthResult.success(message: data['message'] ?? 'Password reset successful');
      } else {
        return AuthResult.failure(message: data['message'] ?? 'Reset failed');
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  @override
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // TODO: This endpoint is not yet live on the backend.
    // It will also require the auth token in headers.
    throw UnimplementedError('Change password endpoint is pending backend implementation.');
  }
}
