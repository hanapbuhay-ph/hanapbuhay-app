import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/data/repositories/mock/mock_auth_repository.dart';
import 'package:hanapbuhayapp/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists and clears an interrupted login OTP challenge', () async {
    final provider = AuthProvider(MockAuthRepository());
    addTearDown(provider.dispose);

    await provider.savePendingLoginOtp('client@example.com', 300);

    final prefs = await SharedPreferences.getInstance();
    expect(provider.pendingLoginOtpEmail, 'client@example.com');
    expect(provider.pendingLoginOtpSecondsRemaining, greaterThan(0));
    expect(prefs.getString('pending_login_otp_email'), 'client@example.com');
    expect(prefs.getInt('pending_login_otp_expires_at'), isNotNull);

    await provider.clearPendingLoginOtp();

    expect(provider.pendingLoginOtpEmail, isNull);
    expect(prefs.getString('pending_login_otp_email'), isNull);
    expect(prefs.getInt('pending_login_otp_expires_at'), isNull);
  });

  test(
    'persists and clears an interrupted password reset OTP challenge',
    () async {
      final provider = AuthProvider(MockAuthRepository());
      addTearDown(provider.dispose);

      await provider.savePendingPasswordResetOtp('client@example.com', 300);

      final prefs = await SharedPreferences.getInstance();
      expect(provider.pendingPasswordResetOtpEmail, 'client@example.com');
      expect(provider.pendingPasswordResetOtpSecondsRemaining, greaterThan(0));
      expect(
        prefs.getString('pending_password_reset_otp_email'),
        'client@example.com',
      );
      expect(prefs.getInt('pending_password_reset_otp_expires_at'), isNotNull);

      await provider.clearPendingPasswordResetOtp();

      expect(provider.pendingPasswordResetOtpEmail, isNull);
      expect(prefs.getString('pending_password_reset_otp_email'), isNull);
      expect(prefs.getInt('pending_password_reset_otp_expires_at'), isNull);
    },
  );
}
