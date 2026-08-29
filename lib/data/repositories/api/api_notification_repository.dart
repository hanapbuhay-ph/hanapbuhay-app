import '../../models/notification_model.dart';
import '../notification_repository.dart';

class ApiNotificationRepository implements NotificationRepository {
  @override
  Future<List<AppNotification>> getNotifications() async {
    // TODO: GET /api/notifications
    throw UnimplementedError();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    // TODO: POST /api/notifications/{id}/read
    throw UnimplementedError();
  }

  @override
  Stream<int> getUnreadCount() {
    // TODO: Connect to WebSocket or periodic poll
    return Stream.value(0);
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    // TODO: GET /api/notifications/preferences
    throw UnimplementedError();
  }

  @override
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    // TODO: POST /api/notifications/preferences
    throw UnimplementedError();
  }
}
