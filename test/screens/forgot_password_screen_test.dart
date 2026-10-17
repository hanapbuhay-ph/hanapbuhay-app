import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/data/repositories/mock/mock_auth_repository.dart';
import 'package:hanapbuhayapp/providers/auth_provider.dart';
import 'package:hanapbuhayapp/screens/section_0_onboarding_auth/forgot_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'keeps the request screen until the user chooses to enter an OTP',
    (tester) async {
      final authProvider = AuthProvider(MockAuthRepository());
      addTearDown(authProvider.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const MaterialApp(home: ForgotPasswordScreen()),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'client@example.com');
      await tester.tap(find.text('Send Reset Code'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(
        find.text(
          'If an account is eligible for password reset, a code will be sent. Check your email. If you have a code, continue below.',
        ),
        findsOneWidget,
      );
      expect(find.text('Verify your email'), findsNothing);
      expect(authProvider.pendingPasswordResetOtpEmail, isNull);

      await tester.tap(find.text('I have a code'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Verify your email'), findsOneWidget);
      expect(authProvider.pendingPasswordResetOtpEmail, 'client@example.com');
    },
  );
}
