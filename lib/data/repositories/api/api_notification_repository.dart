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
    // Note: This endpoint is not in 07_API_ENDPOINTS.md
    // Return default preferences for now
    // TODO: Add backend endpoint GET /api/user/notification-preferences
    return NotificationPreferences();
  }

  @override
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    // Note: This endpoint is not in 07_API_ENDPOINTS.md
    // TODO: Add backend endpoint POST /api/user/notification-preferences
    print('[ApiNotificationRepository] updatePreferences: Backend endpoint not yet available');
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
