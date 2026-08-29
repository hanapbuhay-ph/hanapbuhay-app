import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications();
  Future<void> markAsRead(String notificationId);
  Stream<int> getUnreadCount();
  Future<NotificationPreferences> getPreferences();
  Future<void> updatePreferences(NotificationPreferences preferences);
}
