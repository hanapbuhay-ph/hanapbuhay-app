import 'dart:async';
import 'dart:convert';

import '../core/api/api_client.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/routing/app_router.dart';

/// FCM Token Registration Service
/// Handles device token registration with backend for push notifications
class FcmService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final StreamController<void> _notificationReceivedController =
      StreamController<void>.broadcast();
  static String? _pendingNotificationPayload;
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'hanapbuhay_notifications',
    'HanapBuhay notifications',
    description: 'Booking, tracking, and account notifications.',
    importance: Importance.high,
  );

  static Stream<void> get onNotificationReceived =>
      _notificationReceivedController.stream;

  static Future<void> initializeNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _openNotificationTarget(response.payload);
      },
    );

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();

    FirebaseMessaging.onMessage.listen((message) {
      _notificationReceivedController.add(null);
      unawaited(_showForegroundNotification(message));
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _notificationReceivedController.add(null);
      _openNotificationTarget(jsonEncode(message.data));
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _openNotificationTarget(jsonEncode(initialMessage.data));
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if (title == null || body == null) return;

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_notification',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> _openNotificationTarget(String? payload) async {
    if (payload == null || payload.isEmpty) return;

    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
    } catch (_) {
      return;
    }

    final bookingId = data['booking_id']?.toString();
    final conversationId = data['conversation_id']?.toString();
    if (bookingId == null && conversationId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    final navigator = ApiClient.navigatorKey.currentState;
    if (navigator == null) {
      _pendingNotificationPayload = payload;
      return;
    }

    if (conversationId != null && conversationId.isNotEmpty) {
      navigator.pushNamed('${AppRouter.chatThread}/$conversationId');
      return;
    }

    if (bookingId == null || bookingId.isEmpty) return;
    final route = role == 'worker' ? AppRouter.jobDetail : AppRouter.bookingDetail;
    navigator.pushNamed('$route/$bookingId');
  }

  static Future<void> flushPendingNotification() async {
    final payload = _pendingNotificationPayload;
    _pendingNotificationPayload = null;
    if (payload != null) {
      await _openNotificationTarget(payload);
    }
  }

  /// Register FCM device token with backend
  /// Endpoint: POST /api/user/fcm-token (also aliased as POST /api/notifications/register-device)
  /// Backend requires: fcm_token (string) and device_type (android|ios|web)
  static Future<bool> registerToken(String fcmToken) async {
    try {
      if (fcmToken.isEmpty) {
        print('[FcmService] registerToken: Empty token provided');
        return false;
      }

      // Device type: capstone mobile app targets Android (see Session 6 Android setup).
      // The backend validates device_type must be one of: android|ios|web
      final res = await ApiClient.post(
        '/user/fcm-token',
        body: {
          'fcm_token': fcmToken,
          'device_type': 'android',  // Required by backend (RegisterDeviceRequest.php)
        },
        requiresAuth: true,
      );

      if (res['success'] == true) {
        print('[FcmService] FCM token registered successfully');
        return true;
      } else {
        print('[FcmService] FCM token registration failed: ${res['message']}');
        return false;
      }
    } catch (e) {
      print('[FcmService] registerToken error: $e');
      return false;
    }
  }

  /// Note: Backend does not have a DELETE endpoint for FCM tokens
  /// The logout endpoint (POST /api/auth/logout) only revokes the Sanctum auth token
  /// FCM tokens remain in the database and will be overwritten on next login
  /// This is acceptable behavior for the capstone project scope
  static Future<bool> deleteToken() async {
    print('[FcmService] deleteToken: No DELETE endpoint in backend');
    print('[FcmService] FCM tokens are managed automatically by the backend');
    return true;
  }

  /// Initialize FCM and register token
  /// This should be called after successful login
  static Future<void> initializeAndRegister() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await messaging.getToken();
        if (token != null) {
          await registerToken(token);
        }

        messaging.onTokenRefresh.listen((newToken) {
          registerToken(newToken);
        });
      }
    } catch (e) {
      print('[FcmService] initializeAndRegister error: $e');
    }
  }
}
