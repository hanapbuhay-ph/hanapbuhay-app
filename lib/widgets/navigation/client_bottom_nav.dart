import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/notification_provider.dart';

class ClientBottomNav extends StatelessWidget {
  final int currentIndex;

  const ClientBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRouter.clientHome);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRouter.bookingHistory);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRouter.chatInbox);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRouter.notificationCenter);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRouter.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3), width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex == -1 ? 0 : currentIndex,
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: AppTypography.labelSmall.copyWith(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTypography.labelSmall.copyWith(fontSize: 10),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Bookings',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: context.read<NotificationProvider>().getUnreadCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Stack(
                  children: [
                    const Icon(Icons.notifications_none),
                    if (count > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colorScheme.surface, width: 1),
                          ),
                          constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                        ),
                      ),
                  ],
                );
              },
            ),
            activeIcon: const Icon(Icons.notifications),
            label: 'Alerts',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
