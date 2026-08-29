import 'package:go_router/go_router.dart';
import '../../screens/section_0_onboarding_auth/splash_screen.dart';
import '../../screens/section_0_onboarding_auth/onboarding_slides_screen.dart';
import '../../screens/section_0_onboarding_auth/login_screen.dart';
import '../../screens/section_0_onboarding_auth/registration_role_screen.dart';
import '../../screens/section_0_onboarding_auth/registration_account_screen.dart';
import '../../screens/section_0_onboarding_auth/email_verification_screen.dart';
import '../../screens/section_0_onboarding_auth/complete_profile_screen.dart';
import '../../screens/section_0_onboarding_auth/forgot_password_screen.dart';
import '../../screens/section_1_client/client_home_screen.dart';
import '../../screens/section_2_worker/worker_home_dashboard_screen.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String registerRole = '/register-role';
  static const String registerAccount = '/register-account';
  static const String verifyEmail = '/verify-email';
  static const String completeProfile = '/complete-profile';
  static const String forgotPassword = '/forgot-password';
  
  // Section 1 & 2 Home (Placeholder destinations)
  static const String clientHome = '/client-home';
  static const String workerHome = '/worker-home';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingSlidesScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: registerRole,
        builder: (context, state) => const RegistrationRoleScreen(),
      ),
      GoRoute(
        path: registerAccount,
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'client';
          return RegistrationAccountScreen(role: role);
        },
      ),
      GoRoute(
        path: verifyEmail,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: completeProfile,
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'client';
          return CompleteProfileScreen(role: role);
        },
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: clientHome,
        builder: (context, state) => const ClientHomeScreen(),
      ),
      GoRoute(
        path: workerHome,
        builder: (context, state) => const WorkerHomeDashboardScreen(),
      ),
    ],
  );
}
