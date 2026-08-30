import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_typography.dart';
import 'providers/auth_provider.dart';
import 'providers/worker_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/report_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'services/service_locator.dart';
import 'core/routing/app_router.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => WorkerProvider(workerRepository)),
        ChangeNotifierProvider(create: (_) => BookingProvider(bookingRepository)),
        ChangeNotifierProvider(create: (_) => ReportProvider(reportRepository)),
        ChangeNotifierProvider(create: (_) => ChatProvider(chatRepository)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(notificationRepository)),
      ],
      child: const HanapBuhayApp(),
    ),
  );
}

class HanapBuhayApp extends StatelessWidget {
  const HanapBuhayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HanapBuhay',
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.splash,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          error: AppColors.error,
          onError: AppColors.onError,
        ),
        fontFamily: AppTypography.fontFamily,
        useMaterial3: true,
      ),
    );
  }
}
