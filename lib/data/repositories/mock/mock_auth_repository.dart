import '../../models/auth_result_model.dart';
import '../auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String mobileNumber,
    required String barangay,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return AuthResult.success(
      message: 'OTP sent to $email',
      data: {'email': email},
    );
  }

  @override
  Future<AuthResult> verifyOtp(String email, String otp) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (otp == '123456') {
      return AuthResult.success(
        message: 'Verification successful',
        data: {
          'user': {
            'id': 1,
            'name': 'Test User',
            'email': email,
          },
          'token': 'mock_token_123',
        },
      );
    } else {
      return AuthResult.failure(message: 'Invalid OTP');
    }
  }

  @override
  Future<AuthResult> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return AuthResult.success(
      message: 'Login successful',
      data: {
        'user': {
          'id': 1,
          'name': 'Test User',
          'email': email,
        },
        'token': 'mock_token_123',
      },
    );
  }

  @override
  Future<AuthResult> forgotPassword(String identifier) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return AuthResult.success(message: 'Code sent to $identifier');
  }

  @override
  Future<AuthResult> verifyForgotPasswordOtp(String identifier, String otp) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (otp == '123456') {
      return AuthResult.success(message: 'Code verified');
    }
    return AuthResult.failure(message: 'Invalid code');
  }

  @override
  Future<AuthResult> resetPassword(String identifier, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return AuthResult.success(message: 'Password reset successful');
  }
}
