import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/section_0_onboarding_auth/splash_screen.dart';
import '../../screens/section_0_onboarding_auth/onboarding_slides_screen.dart';
import '../../screens/section_0_onboarding_auth/login_screen.dart';
import '../../screens/section_0_onboarding_auth/registration_role_screen.dart';
import '../../screens/section_0_onboarding_auth/registration_account_screen.dart';
import '../../screens/section_0_onboarding_auth/email_verification_screen.dart';
import '../../screens/section_0_onboarding_auth/complete_profile_screen.dart';
import '../../screens/section_0_onboarding_auth/forgot_password_screen.dart';
import '../../screens/section_0_onboarding_auth/security_settings_screen.dart';
import '../../screens/section_0_onboarding_auth/change_password_screen.dart';
import '../../screens/section_1_client/client_home_screen.dart';
import '../../screens/section_1_client/worker_search_screen.dart';
import '../../screens/section_1_client/worker_profile_view_screen.dart';
import '../../screens/section_1_client/send_booking_request_screen.dart';
import '../../screens/section_1_client/booking_history_screen.dart';
import '../../screens/section_1_client/booking_detail_screen.dart';
import '../../screens/section_1_client/live_tracking_screen.dart';
import '../../screens/section_1_client/rate_review_screen.dart';
import '../../screens/section_1_client/file_report_screen.dart';
import '../../screens/section_1_client/report_status_screen.dart';
import '../../screens/section_2_worker/worker_home_screen.dart';
import '../../screens/section_2_worker/verification_document_screen.dart';
import '../../screens/section_2_worker/verification_under_review_screen.dart';
import '../../screens/section_2_worker/verification_status_screen.dart';
import '../../screens/section_2_worker/portfolio_skills_screen.dart';
import '../../screens/section_2_worker/booking_schedule_screen.dart';
import '../../screens/section_2_worker/job_detail_screen.dart';
import '../../screens/section_2_worker/rate_client_screen.dart';
import '../../screens/section_3_shared/chat_inbox_screen.dart';
import '../../screens/section_3_shared/chat_thread_screen.dart';
import '../../screens/section_3_shared/notification_center_screen.dart';
import '../../screens/section_3_shared/help_faq_screen.dart';
import '../../screens/section_3_shared/profile_tab_screen.dart';
import '../../screens/section_3_shared/edit_profile_screen.dart';
import '../../screens/section_3_shared/notification_preferences_screen.dart';

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
  static const String securitySettings = '/security-settings';
  static const String changePassword = '/change-password';
  static const String workerSearch = '/worker-search';
  static const String workerProfile = '/worker-profile';
  static const String sendBookingRequest = '/send-booking-request';
  static const String bookingHistory = '/booking-history';
  static const String bookingDetail = '/booking-detail';
  static const String liveTracking = '/live-tracking';
  static const String rateReview = '/rate-review';
  static const String fileReport = '/file-report';
  static const String reportStatus = '/report-status';
  static const String verificationDocuments = '/verification-documents';
  static const String verificationUnderReview = '/verification-under-review';
  static const String verificationStatus = '/verification-status';
  static const String portfolioSkills = '/portfolio-skills';
  static const String bookingSchedule = '/booking-schedule';
  static const String jobDetail = '/job-detail';
  static const String rateClient = '/rate-client';
  static const String chatInbox = '/messages';
  static const String chatThread = '/chat';
  static const String notificationCenter = '/notifications';
  static const String help = '/help';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String notificationPreferences = '/notification-preferences';
  
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
        path: securitySettings,
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: bookingHistory,
        builder: (context, state) => const BookingHistoryScreen(),
      ),
      GoRoute(
        path: '$bookingDetail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final autoTrack = state.uri.queryParameters['track'] == 'true';
          return BookingDetailScreen(bookingId: id, autoTrack: autoTrack);
        },
      ),
      GoRoute(
        path: '$bookingDetail/:id/tracking',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return LiveTrackingScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '$rateReview/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return RateReviewScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '$fileReport/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return FileReportScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: reportStatus,
        builder: (context, state) => const ReportStatusScreen(),
      ),
      GoRoute(
        path: portfolioSkills,
        builder: (context, state) => const PortfolioSkillsScreen(),
      ),
      GoRoute(
        path: bookingSchedule,
        builder: (context, state) => const BookingScheduleScreen(),
      ),
      GoRoute(
        path: '$jobDetail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return JobDetailScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '$rateClient/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return RateClientScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: chatInbox,
        builder: (context, state) => const ChatInboxScreen(),
      ),
      GoRoute(
        path: notificationCenter,
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: help,
        builder: (context, state) => const HelpFaqScreen(),
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const ProfileTabScreen(),
      ),
      GoRoute(
        path: editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: notificationPreferences,
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: '$chatThread/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ChatThreadScreen(conversationId: id);
        },
      ),
      GoRoute(
        path: clientHome,
        builder: (context, state) => const ClientHomeScreen(),
      ),
      GoRoute(
        path: workerHome,
        builder: (context, state) => const WorkerHomeScreen(),
      ),
      GoRoute(
        path: workerSearch,
        builder: (context, state) {
          final query = state.uri.queryParameters['query'];
          final category = state.uri.queryParameters['category'];
          return WorkerSearchScreen(initialQuery: query, initialCategory: category);
        },
      ),
      GoRoute(
        path: '$workerProfile/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return WorkerProfileViewScreen(workerId: id);
        },
      ),
      GoRoute(
        path: '$sendBookingRequest/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return SendBookingRequestScreen(workerId: id);
        },
      ),
      GoRoute(
        path: verificationDocuments,
        builder: (context, state) => const VerificationDocumentScreen(),
      ),
      GoRoute(
        path: verificationUnderReview,
        builder: (context, state) => const VerificationUnderReviewScreen(),
      ),
      GoRoute(
        path: verificationStatus,
        builder: (context, state) => const VerificationStatusScreen(),
      ),
    ],
  );
}
