import '../../models/auth_result_model.dart';
import '../auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  // In-memory store to persist user data across registration steps for the session
  static final Map<String, Map<String, dynamic>> _mockUsers = {
    'worker@test.com': {
      'id': 'w1',
      'role': 'worker',
      'name': 'Ricardo Dalisay',
      'mobile': '09171234567',
      'avatar': 'https://i.pravatar.cc/150?u=w1',
      'signInMethod': 'email',
    },
    'client@test.com': {
      'id': 'c1',
      'role': 'client',
      'name': 'Maria Santos',
      'mobile': '09171112222',
      'avatar': 'https://i.pravatar.cc/150?u=client',
      'signInMethod': 'email',
    },
  };

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
    
    // Persist the data for this email
    _mockUsers[email.toLowerCase()] = {
      'id': role == 'worker' ? 'w1' : 'c1',
      'role': role,
      'name': name,
      'mobile': mobileNumber,
      'avatar': role == 'worker' ? 'https://i.pravatar.cc/150?u=w1' : 'https://i.pravatar.cc/150?u=client',
      'signInMethod': 'email',
    };
    
    return AuthResult.success(
      message: 'OTP sent to $email',
      data: {'email': email},
    );
  }

  @override
  Future<AuthResult> verifyOtp(String email, String otp) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (otp == '123456' || otp == '111111') { // Allowing a few common test OTPs
      final userData = _mockUsers[email.toLowerCase()] ?? {
        'id': 'c1',
        'role': 'client',
        'name': 'Mock User',
        'mobile': '09123456789',
        'avatar': 'https://i.pravatar.cc/150?u=mock',
        'signInMethod': 'email',
      };
      
      return AuthResult.success(
        message: 'Verification successful',
        data: {
          'user': {
            'id': userData['id'],
            'name': userData['name'],
            'email': email,
            'role': userData['role'],
            'mobile_number': userData['mobile'],
            'avatar_url': userData['avatar'],
            'sign_in_method': userData['signInMethod'],
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
    
    final userData = _mockUsers[email.toLowerCase()] ?? {
      'id': 'c1',
      'role': 'client',
      'name': 'Maria Santos',
      'mobile': '09171234567',
      'avatar': 'https://i.pravatar.cc/150?u=client',
      'signInMethod': 'email',
    };

    return AuthResult.success(
      message: 'Login successful',
      data: {
        'user': {
          'id': userData['id'],
          'name': userData['name'],
          'email': email,
          'role': userData['role'],
          'mobile_number': userData['mobile'],
          'avatar_url': userData['avatar'],
          'sign_in_method': userData['signInMethod'],
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

  @override
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (currentPassword == 'password123') {
      return AuthResult.success(message: 'Password changed successfully');
    }
    return AuthResult.failure(message: 'Incorrect current password');
  }

  @override
  Future<AuthResult> updateProfile({
    required String name,
    required String mobileNumber,
    String? avatarPath,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return AuthResult.success(message: 'Profile updated successfully!');
  }
}
