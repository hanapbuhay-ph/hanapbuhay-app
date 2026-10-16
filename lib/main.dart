import 'dart:async';

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
import 'providers/saved_posts_provider.dart';
import 'providers/theme_provider.dart';
import 'services/service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/api/api_client.dart';
import 'services/fcm_service.dart';
import 'services/presence_service.dart';

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
        ChangeNotifierProvider(
          create: (context) => BookingProvider(
            bookingRepository,
            isAuthenticated: () => context.read<AuthProvider>().isAuthenticated,
          ),
        ),
        ChangeNotifierProvider(create: (_) => ReportProvider(reportRepository)),
        ChangeNotifierProvider(
          create: (context) => ChatProvider(
            chatRepository,
            isAuthenticated: () => context.read<AuthProvider>().isAuthenticated,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(
            notificationRepository,
            isAuthenticated: () => context.read<AuthProvider>().isAuthenticated,
          ),
        ),
        ChangeNotifierProvider(create: (_) => SavedPostsProvider()),
      ],
      child: const HanapBuhayApp(),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FcmService.flushPendingNotification();
  });
}

class HanapBuhayApp extends StatefulWidget {
  const HanapBuhayApp({super.key});

  @override
  State<HanapBuhayApp> createState() => _HanapBuhayAppState();
}

class _HanapBuhayAppState extends State<HanapBuhayApp>
    with WidgetsBindingObserver {
  final _presence = PresenceService();
  AuthProvider? _observedAuthProvider;
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _presence.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = context.read<AuthProvider>();
    if (identical(_observedAuthProvider, authProvider)) return;

    _observedAuthProvider?.removeListener(_handleAuthChanged);
    _observedAuthProvider = authProvider..addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  void _handleAuthChanged() {
    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    if (!isAuthenticated) {
      _wasAuthenticated = false;
      return;
    }
    if (_wasAuthenticated) return;
    _wasAuthenticated = true;
    _refreshBadgeCounts();
  }

  void _refreshBadgeCounts() {
    if (!mounted || context.read<AuthProvider>().isAuthenticated == false) {
      return;
    }
    unawaited(context.read<BookingProvider>().refreshPendingCount());
    unawaited(context.read<ChatProvider>().refreshUnreadCount());
    unawaited(context.read<NotificationProvider>().refreshUnreadCount());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshBadgeCounts();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _observedAuthProvider?.removeListener(_handleAuthChanged);
    _presence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'HanapBuhay',
      debugShowCheckedModeBanner: false,
      navigatorKey: ApiClient.navigatorKey,
      navigatorObservers: [ApiClient.routeObserver],
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.splash,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
    );
  }
}
