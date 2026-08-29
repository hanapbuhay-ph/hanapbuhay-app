import 'dart:async';
import '../../models/notification_model.dart';
import '../notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  final List<AppNotification> _mockNotifications = [
    AppNotification(
      id: 'n1',
      type: NotificationType.bookingAccepted,
      title: 'Booking Accepted',
      body: 'Your booking for **Plumbing Repair** was accepted by **Roberto Cruz**',
      relatedId: 'b1',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    AppNotification(
      id: 'n2',
      type: NotificationType.newChatMessage,
      title: 'New Message',
      body: 'New message from **Maria Santos** regarding Home Cleaning',
      relatedId: 'c1',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: 'n3',
      type: NotificationType.verificationApproved,
      title: 'Verification Successful',
      body: 'Your account verification is successful! You can now start accepting jobs.',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AppNotification(
      id: 'n4',
      type: NotificationType.bookingCompleted,
      title: 'Booking Completed',
      body: 'Booking completed: **Electrical Fix** on Oct 28',
      relatedId: 'b4',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AppNotification(
      id: 'n5',
      type: NotificationType.newRatingReceived,
      title: 'New Rating',
      body: 'You received a 5-star rating from **Juan Dela Cruz**',
      relatedId: 'w1',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  final _unreadCountController = StreamController<int>.broadcast();

  MockNotificationRepository() {
    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    final count = _mockNotifications.where((n) => !n.isRead).length;
    _unreadCountController.add(count);
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(_mockNotifications);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final index = _mockNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _mockNotifications[index] = _mockNotifications[index].copyWith(isRead: true);
      _updateUnreadCount();
    }
  }

  @override
  Stream<int> getUnreadCount() {
    return _unreadCountController.stream;
  }

  NotificationPreferences _prefs = NotificationPreferences();

  @override
  Future<NotificationPreferences> getPreferences() async {
    return _prefs;
  }

  @override
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    _prefs = preferences;
  }
}
