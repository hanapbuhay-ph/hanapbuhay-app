import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int)? onTabTap;

  const AppBottomNav({super.key, required this.currentIndex, this.onTabTap});

  void _onTap(BuildContext context, int index, bool isWorker) {
    if (index == currentIndex) return;
    if (onTabTap != null) {
      onTabTap!(index);
      return;
    }
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, isWorker ? AppRouter.workerHome : AppRouter.clientHome);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, isWorker ? AppRouter.bookingSchedule : AppRouter.bookingHistory);
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
    final colorScheme = Theme.of(context).colorScheme;
    final isWorker = context.watch<AuthProvider>().userRole == 'worker';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3), width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex < 0 ? 0 : currentIndex,
        onTap: (index) => _onTap(context, index, isWorker),
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
          BottomNavigationBarItem(
            icon: Icon(isWorker ? Icons.work_outline : Icons.calendar_today_outlined),
            activeIcon: Icon(isWorker ? Icons.work : Icons.calendar_today),
            label: isWorker ? 'Jobs' : 'Bookings',
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
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.surface, width: 1),
                          ),
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
