import '../core/api/api_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// FCM Token Registration Service
/// Handles device token registration with backend for push notifications
class FcmService {
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
