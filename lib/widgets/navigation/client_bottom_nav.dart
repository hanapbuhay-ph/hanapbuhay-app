import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/chat_provider.dart';
import '../../providers/booking_provider.dart';
import 'notification_nav_icon.dart';

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
          BottomNavigationBarItem(
            icon: _bookingIcon(context, colorScheme, false),
            activeIcon: _bookingIcon(context, colorScheme, true),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: _messageIcon(context, colorScheme, false),
            activeIcon: _messageIcon(context, colorScheme, true),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: NotificationNavIcon(active: false),
            activeIcon: NotificationNavIcon(active: true),
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

  Widget _messageIcon(BuildContext context, ColorScheme colorScheme, bool active) {
    return StreamBuilder<int>(
      stream: context.read<ChatProvider>().getUnreadCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(active ? Icons.chat_bubble : Icons.chat_bubble_outline),
            if (count > 0) Positioned(right: -5, top: -4, child: _countBadge(colorScheme, count)),
          ],
        );
      },
    );
  }

  Widget _bookingIcon(BuildContext context, ColorScheme colorScheme, bool active) {
    return StreamBuilder<int>(
      stream: context.read<BookingProvider>().getPendingCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(active ? Icons.work : Icons.work_outline),
            if (count > 0) Positioned(right: -5, top: -4, child: _countBadge(colorScheme, count)),
          ],
        );
      },
    );
  }

  Widget _countBadge(ColorScheme colorScheme, int count) => Container(
        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colorScheme.error, shape: BoxShape.circle, border: Border.all(color: colorScheme.surface, width: 1.5)),
        child: Text(count > 9 ? '9+' : '$count', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
      );
}
