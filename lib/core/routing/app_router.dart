import 'package:flutter/material.dart';
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
import '../../screens/section_0_onboarding_auth/login_activity_screen.dart';
import '../../screens/section_0_onboarding_auth/legal_document_screen.dart';
import '../../screens/section_1_client/worker_search_screen.dart';
import '../../screens/section_1_client/worker_profile_view_screen.dart';
import '../../screens/section_1_client/send_booking_request_screen.dart';
import '../../screens/section_1_client/booking_detail_screen.dart';
import '../../screens/section_1_client/live_tracking_screen.dart';
import '../../screens/section_1_client/rate_review_screen.dart';
import '../../screens/section_1_client/file_report_screen.dart';
import '../../screens/section_1_client/report_status_screen.dart';
import '../../screens/section_2_worker/incoming_requests_screen.dart';
import '../../screens/section_2_worker/manage_posts_screen.dart';
import '../../screens/section_2_worker/worker_map_screen.dart';
import '../../screens/section_1_client/browse_category_screen.dart';
import '../../screens/section_1_client/category_results_screen.dart';
import '../../screens/section_2_worker/verification_document_screen.dart';
import '../../screens/section_2_worker/verification_status_screen.dart';
import '../../screens/section_2_worker/portfolio_skills_screen.dart';
import '../../screens/section_2_worker/job_detail_screen.dart';
import '../../screens/section_2_worker/rate_client_screen.dart';
import '../../screens/section_2_worker/create_job_post_screen.dart';
import '../../screens/section_2_worker/edit_job_post_screen.dart';
import '../../screens/section_3_shared/chat_thread_screen.dart';
import '../../screens/section_3_shared/help_faq_screen.dart';
import '../../screens/section_3_shared/edit_profile_screen.dart';
import '../../screens/section_3_shared/notification_preferences_screen.dart';
import '../../screens/shell/tab_shell.dart';

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
  static const String loginActivity = '/login-activity';
  static const String termsOfService = '/terms-of-service';
  static const String privacyPolicy = '/privacy-policy';
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
  static const String clientHome = '/client-home';
  static const String workerHome = '/worker-home';
  static const String createJobPost = '/create-job-post';
  static const String editJobPost = '/edit-job-post';
  static const String manageJobPosts = '/manage-job-posts';
  static const String workerMap = '/worker-map';
  static const String incomingRequests = '/incoming-requests';
  static const String browseCategory = '/browse-category';
  static const String categoryResults = '/category-results';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Uri uri = Uri.parse(settings.name ?? '');
    final String path = uri.path;

    switch (path) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingSlidesScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case registerRole:
        return MaterialPageRoute(builder: (_) => const RegistrationRoleScreen());
      case registerAccount:
        final role = uri.queryParameters['role'] ?? 'client';
        return MaterialPageRoute(builder: (_) => RegistrationAccountScreen(role: role));
      case verifyEmail:
        final email = uri.queryParameters['email'] ?? '';
        return MaterialPageRoute(builder: (_) => EmailVerificationScreen(email: email));
      case completeProfile:
        final role = uri.queryParameters['role'] ?? 'client';
        return MaterialPageRoute(builder: (_) => CompleteProfileScreen(role: role));
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case securitySettings:
        return MaterialPageRoute(builder: (_) => const SecuritySettingsScreen());
      case changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
      case loginActivity:
        return MaterialPageRoute(builder: (_) => const LoginActivityScreen());
      case termsOfService:
        return MaterialPageRoute(builder: (_) => const LegalDocumentScreen(type: LegalDocumentType.terms));
      case privacyPolicy:
        return MaterialPageRoute(builder: (_) => const LegalDocumentScreen(type: LegalDocumentType.privacy));
      case bookingHistory:
        return MaterialPageRoute(builder: (_) => const TabShell(initialIndex: 1));
      case reportStatus:
        return MaterialPageRoute(builder: (_) => const ReportStatusScreen());
      case portfolioSkills:
        return MaterialPageRoute(builder: (_) => const PortfolioSkillsScreen());
      case bookingSchedule:
        return MaterialPageRoute(builder: (_) => const TabShell(initialIndex: 1));
      case chatInbox:
        return MaterialPageRoute(builder: (_) => const TabShell(initialIndex: 2));
      case notificationCenter:
        return MaterialPageRoute(builder: (_) => const TabShell(initialIndex: 3));
      case help:
        return MaterialPageRoute(builder: (_) => const HelpFaqScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const TabShell(initialIndex: 4));
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case notificationPreferences:
        return MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen());
      case clientHome:
        return MaterialPageRoute(builder: (_) => const TabShell(initialIndex: 0));
      case workerHome:
        return MaterialPageRoute(builder: (_) => const TabShell(initialIndex: 0));
      case createJobPost:
        return MaterialPageRoute(builder: (_) => const CreateJobPostScreen());
      case workerSearch:
        final query = uri.queryParameters['query'];
        final category = uri.queryParameters['category'];
        final showFilter = uri.queryParameters['filter'] == 'true';
        return MaterialPageRoute(
          builder: (_) => WorkerSearchScreen(
            initialQuery: query,
            initialCategory: category,
            showFilterOnInit: showFilter,
          ),
        );
      case verificationDocuments:
        return MaterialPageRoute(builder: (_) => const VerificationDocumentScreen());
      case manageJobPosts:
        return MaterialPageRoute(builder: (_) => const ManagePostsScreen());
      case incomingRequests:
        return MaterialPageRoute(builder: (_) => const IncomingRequestsScreen());
      case browseCategory:
        return MaterialPageRoute(builder: (_) => const BrowseCategoryScreen());
      case verificationStatus:
        return MaterialPageRoute(builder: (_) => const VerificationStatusScreen());
      
      // Dynamic Routes
      default:
        // Handle routes with path parameters
        if (path.startsWith(categoryResults)) {
          final id = path.split('/').last;
          final name = uri.queryParameters['name'] ?? id;
          return MaterialPageRoute(builder: (_) => CategoryResultsScreen(categoryId: id, categoryName: name));
        }
        if (path.startsWith(workerMap)) {
          final id = path.split('/').last;
          return MaterialPageRoute(builder: (_) => WorkerMapScreen(bookingId: id));
        }
        if (path.startsWith(editJobPost)) {
          final id = path.split('/').last;
          return MaterialPageRoute(builder: (_) => EditJobPostScreen(postId: id));
        }
        if (path.startsWith(workerProfile)) {
          final id = path.split('/').last;
          return MaterialPageRoute(builder: (_) => WorkerProfileViewScreen(workerId: id));
        }
        if (path.startsWith(sendBookingRequest)) {
          final id = path.split('/').last;
          return MaterialPageRoute(builder: (_) => SendBookingRequestScreen(workerId: id));
        }
        if (path.startsWith(bookingDetail)) {
          final parts = path.split('/');
          final id = parts[2];
          if (parts.length > 3 && parts[3] == 'tracking') {
            return MaterialPageRoute(builder: (_) => LiveTrackingScreen(bookingId: id));
          }
          final autoTrack = uri.queryParameters['track'] == 'true';
          return MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: id, autoTrack: autoTrack));
        }
        if (path.startsWith(jobDetail)) {
          final id = path.split('/').last;
          return MaterialPageRoute(builder: (_) => JobDetailScreen(bookingId: id));
        }
        if (path.startsWith(rateReview)) {
          final id = path.split('/').last;
          return MaterialPageRoute(builder: (_) => RateReviewScreen(bookingId: id));
        }
        if (path.startsWith(rateClient)) {
          final id = path.split('/').last;
          return MaterialPageRoute(builder: (_) => RateClientScreen(bookingId: id));
        }
        if (path.startsWith(fileReport)) {
          final id = path.split('/').last;
          return MaterialPageRoute(builder: (_) => FileReportScreen(bookingId: id));
        }
        if (path.startsWith(chatThread)) {
          final id = path.split('/').last;
          return MaterialPageRoute(builder: (_) => ChatThreadScreen(conversationId: id));
        }

        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
