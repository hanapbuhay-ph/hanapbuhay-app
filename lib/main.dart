import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/worker_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/report_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'services/service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/api/api_client.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FcmService.initializeNotifications();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FcmService.flushPendingNotification();
  });
}

class HanapBuhayApp extends StatelessWidget {
  const HanapBuhayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'HanapBuhay',
      debugShowCheckedModeBanner: false,
      navigatorKey: ApiClient.navigatorKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.splash,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
    );
  }
}
