import 'dart:async';
import '../../models/notification_model.dart';
import '../notification_repository.dart';
import '../../../core/api/api_client.dart';

/// API-connected NotificationRepository — Section J of 07_API_ENDPOINTS.md
class ApiNotificationRepository implements NotificationRepository {
  final _unreadCountController = StreamController<int>.broadcast();

  @override
  Future<List<AppNotification>> getNotifications() async {
    try {
      final res = await ApiClient.get('/notifications', requiresAuth: true);
      
      if (res['success'] != true) {
        print('[ApiNotificationRepository] getNotifications failed: ${res['message']}');
        return [];
      }

      final data = res['data'];
      if (data == null) return [];

      final notificationsData = data['notifications'] ?? data;
      if (notificationsData is! List) return [];

      final notifications = notificationsData.map((item) {
        return _parseNotification(item);
      }).whereType<AppNotification>().toList();

      // Update unread count
      final unreadCount = notifications.where((n) => !n.isRead).length;
      _unreadCountController.add(unreadCount);

      return notifications;
    } catch (e) {
      print('[ApiNotificationRepository] getNotifications error: $e');
      return [];
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      final res = await ApiClient.post(
        '/notifications/$notificationId/read',
        requiresAuth: true,
      );

      if (res['success'] != true) {
        print('[ApiNotificationRepository] markAsRead failed: ${res['message']}');
      }
    } catch (e) {
      print('[ApiNotificationRepository] markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final res = await ApiClient.post(
        '/notifications/read-all',
        requiresAuth: true,
      );

      if (res['success'] == true) {
        _unreadCountController.add(0);
      }
    } catch (e) {
      print('[ApiNotificationRepository] markAllAsRead error: $e');
    }
  }

  @override
  Stream<int> getUnreadCount() {
    return _unreadCountController.stream;
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    try {
      final res = await ApiClient.get('/user/notification-preferences', requiresAuth: true);

      if (res['success'] != true || res['data'] == null) {
        return NotificationPreferences();
      }

      final data = res['data'] as Map<String, dynamic>;

      return NotificationPreferences(
        bookingUpdates: data['booking_updates'] ?? true,
        messages: data['messages'] ?? true,
        promotions: data['promotions'] ?? false,
        pushEnabled: data['push'] ?? true,
        emailEnabled: data['email'] ?? true,
      );
    } catch (e) {
      return NotificationPreferences();
    }
  }

  @override
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      await ApiClient.post(
        '/user/notification-preferences',
        requiresAuth: true,
        body: {
          'booking_updates': preferences.bookingUpdates,
          'messages': preferences.messages,
          'promotions': preferences.promotions,
          'push': preferences.pushEnabled,
          'email': preferences.emailEnabled,
        },
      );
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  /// Parse notification from API response
  AppNotification? _parseNotification(dynamic item) {
    try {
      if (item is! Map) return null;

      final id = item['id']?.toString();
      final typeStr = item['type']?.toString();
      final title = item['title']?.toString();
      final body = item['body']?.toString();
      
      // Extract related_id from 'data' object if present
      String? relatedId;
      final dataObj = item['data'];
      if (dataObj is Map) {
        relatedId = dataObj['booking_id']?.toString() ?? 
                    dataObj['conversation_id']?.toString() ??
                    dataObj['worker_id']?.toString();
      }
      // Fallback to direct related_id field
      relatedId ??= item['related_id']?.toString();
      
      final isRead = item['is_read'] == true || item['read_at'] != null;
      final createdAtStr = item['created_at']?.toString();

      if (id == null || typeStr == null || title == null || body == null) {
        return null;
      }

      final type = _parseNotificationType(typeStr);
      final createdAt = createdAtStr != null
          ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
          : DateTime.now();

      return AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        relatedId: relatedId,
        isRead: isRead,
        createdAt: createdAt,
      );
    } catch (e) {
      print('[ApiNotificationRepository] _parseNotification error: $e');
      return null;
    }
  }

  /// Map API notification type string to enum
  NotificationType _parseNotificationType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'booking_accepted':
      case 'bookingaccepted':
        return NotificationType.bookingAccepted;
      case 'booking_updated':
      case 'bookingupdated':
        return NotificationType.bookingUpdated;
      case 'booking_completed':
      case 'bookingcompleted':
        return NotificationType.bookingCompleted;
      case 'new_chat_message':
      case 'newchatmessage':
      case 'message':
        return NotificationType.newChatMessage;
      case 'verification_approved':
      case 'verificationapproved':
        return NotificationType.verificationApproved;
      case 'new_rating_received':
      case 'newratingreceived':
      case 'rating':
        return NotificationType.newRatingReceived;
      default:
        return NotificationType.system;
    }
  }
}
