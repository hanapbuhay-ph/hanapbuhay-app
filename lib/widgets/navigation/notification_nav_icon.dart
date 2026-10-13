import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';

class NotificationNavIcon extends StatelessWidget {
  final bool active;

  const NotificationNavIcon({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<int>(
      stream: context.read<NotificationProvider>().getUnreadCount(),
      initialData: 0,
      builder: (context, snapshot) {
        final hasUnreadNotifications = (snapshot.data ?? 0) > 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(active ? Icons.notifications : Icons.notifications_none),
            if (hasUnreadNotifications)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  key: const ValueKey('notification-unread-indicator'),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
