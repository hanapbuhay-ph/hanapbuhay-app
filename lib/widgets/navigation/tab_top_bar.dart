import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

/// Shared top bar for all bottom-nav tab screens.
/// Shows the HanapBuhay brand title, notification bell with badge, and avatar.
class TabTopBar extends StatelessWidget {
  const TabTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final avatar = authProvider.userAvatar ?? 'https://i.pravatar.cc/150?u=user';

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.9),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Text(
              'HanapBuhay',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: -1,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRouter.notificationCenter),
              child: Stack(
                children: [
                  Icon(Icons.notifications_none, color: colorScheme.onSurfaceVariant),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: StreamBuilder<int>(
                      stream: context.read<NotificationProvider>().getUnreadCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.surface, width: 1.5),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(radius: 16, backgroundImage: NetworkImage(avatar)),
          ],
        ),
      ),
    );
  }
}
