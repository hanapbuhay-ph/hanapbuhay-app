import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
}

class HanapBuhayApp extends StatelessWidget {
  const HanapBuhayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'HanapBuhay',
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.splash,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
    );
  }
}
