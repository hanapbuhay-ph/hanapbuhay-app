import '../models/auth_result_model.dart';

abstract class AuthRepository {
  /// Section A complete — app is now API-connected for auth.
  static const bool useMock = false;

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String mobileNumber,
    required String barangay,
  });

  Future<AuthResult> verifyOtp(String email, String otp);

  Future<AuthResult> login(String email, String password);

  Future<AuthResult> forgotPassword(String identifier);

  Future<AuthResult> verifyForgotPasswordOtp(String identifier, String otp);

  Future<AuthResult> resetPassword(String identifier, String newPassword);

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<AuthResult> updateProfile({
    required String name,
    required String mobileNumber,
    String? barangay,
    String? avatarPath,
  });
}
