import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/data/repositories/mock/mock_booking_repository.dart';
import 'package:hanapbuhayapp/data/repositories/mock/mock_chat_repository.dart';
import 'package:hanapbuhayapp/providers/booking_provider.dart';
import 'package:hanapbuhayapp/providers/chat_provider.dart';

void main() {
  test(
    'refreshes pending booking badge when a push notification arrives',
    () async {
      final notifications = StreamController<void>.broadcast();
      final provider = BookingProvider(
        MockBookingRepository(),
        isAuthenticated: () => true,
        notificationEvents: notifications.stream,
      );
      addTearDown(provider.dispose);
      addTearDown(notifications.close);

      final badgeCount = provider.getPendingCount().firstWhere(
        (count) => count > 0,
      );
      notifications.add(null);

      expect(await badgeCount.timeout(const Duration(seconds: 2)), 2);
      expect(provider.pendingCount, 2);
    },
  );

  test('refreshes message badge when a push notification arrives', () async {
    final notifications = StreamController<void>.broadcast();
    final provider = ChatProvider(
      MockChatRepository(),
      isAuthenticated: () => true,
      notificationEvents: notifications.stream,
    );
    addTearDown(provider.dispose);
    addTearDown(notifications.close);

    final badgeCount = provider.getUnreadCount().firstWhere(
      (count) => count > 0,
    );
    notifications.add(null);

    expect(await badgeCount.timeout(const Duration(seconds: 2)), 1);
    expect(provider.unreadCount, 1);
  });

  test(
    'refreshes message badge after opening an unread conversation',
    () async {
      final provider = ChatProvider(
        MockChatRepository(),
        isAuthenticated: () => true,
      );
      addTearDown(provider.dispose);

      await provider.refreshUnreadCount();
      expect(provider.unreadCount, 1);

      await provider.markAsRead('c1');

      expect(provider.unreadCount, 0);
    },
  );
}
