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
        final count = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(active ? Icons.notifications : Icons.notifications_none),
            if (count > 0)
              Positioned(
                right: -5,
                top: -4,
                child: Container(
                  key: const ValueKey('notification-unread-count'),
                  constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 1.5),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
