import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/data/repositories/mock/mock_notification_repository.dart';
import 'package:hanapbuhayapp/providers/notification_provider.dart';
import 'package:hanapbuhayapp/widgets/navigation/notification_nav_icon.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows unread count for existing unread notifications', (
    tester,
  ) async {
    final provider = NotificationProvider(MockNotificationRepository());

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: NotificationNavIcon(active: false)),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('notification-unread-count')),
      findsOneWidget,
    );
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);

    await provider.markAsRead('n1');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('notification-unread-count')),
      findsOneWidget,
    );
    expect(find.text('1'), findsOneWidget);

    await provider.markAsRead('n2');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('notification-unread-count')),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('keeps unread indicator on the selected alerts icon', (
    tester,
  ) async {
    final provider = NotificationProvider(MockNotificationRepository());

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: NotificationNavIcon(active: true)),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.notifications), findsOneWidget);
    expect(
      find.byKey(const ValueKey('notification-unread-count')),
      findsOneWidget,
    );
    expect(find.text('2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
  });
}
