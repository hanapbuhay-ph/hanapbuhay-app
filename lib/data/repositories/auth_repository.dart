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

  Future<AuthResult> verifyLoginOtp(String email, String otp, {String? deviceName});

  Future<AuthResult> resendLoginOtp(String email);

  Future<AuthResult> login(String email, String password, {String? deviceName});

  Future<AuthResult> forgotPassword(String identifier);

  Future<AuthResult> verifyForgotPasswordOtp(String identifier, String otp);

  Future<AuthResult> resetPassword(String identifier, String newPassword);

  Future<AuthResult> resendOtp(String email);

  Future<AuthResult> changePassword({
    String? currentPassword,
    required String newPassword,
  });

  Future<AuthResult> updateProfile({
    required String name,
    required String mobileNumber,
    int? barangayId,
    String? avatarPath,
  });

  Future<List<Map<String, dynamic>>> getSessions();

  Future<AuthResult> revokeSession(String sessionId);

  Future<AuthResult> revokeAllSessions();

  Future<AuthResult> getDeletionRequestStatus();

  Future<AuthResult> requestAccountDeletion();

  Future<AuthResult> cancelAccountDeletion();

  Future<bool> getTwoFactorEnabled();

  Future<AuthResult> updateTwoFactorEnabled(bool enabled);
}
