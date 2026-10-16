import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/data/models/notification_model.dart';
import 'package:hanapbuhayapp/data/repositories/notification_repository.dart';
import 'package:hanapbuhayapp/providers/notification_provider.dart';

void main() {
  test('does not refresh alerts while the user is unauthenticated', () async {
    final repository = _CountingNotificationRepository();
    final provider = NotificationProvider(
      repository,
      isAuthenticated: () => false,
    );
    addTearDown(provider.dispose);

    await provider.refreshUnreadCount();

    expect(repository.notificationRequests, 0);
  });
}

class _CountingNotificationRepository implements NotificationRepository {
  int notificationRequests = 0;

  @override
  Future<List<AppNotification>> getNotifications() async {
    notificationRequests++;
    return [];
  }

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Stream<int> getUnreadCount() => const Stream<int>.empty();

  @override
  Future<NotificationPreferences> getPreferences() async =>
      NotificationPreferences();

  @override
  Future<void> updatePreferences(NotificationPreferences preferences) async {}
}
