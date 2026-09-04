import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/tab_top_bar.dart';
import '../../widgets/navigation/app_bottom_nav.dart';
import '../section_1_client/client_home_screen.dart';
import '../section_1_client/booking_history_screen.dart';
import '../section_2_worker/worker_home_screen.dart';
import '../section_2_worker/booking_schedule_screen.dart';
import '../section_3_shared/chat_inbox_screen.dart';
import '../section_3_shared/notification_center_screen.dart';
import '../section_3_shared/profile_tab_screen.dart';

class TabShell extends StatefulWidget {
  final int initialIndex;
  const TabShell({super.key, this.initialIndex = 0});

  @override
  State<TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<TabShell> {
  late int _currentIndex;
  late int _previousIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _previousIndex = widget.initialIndex;
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWorker = context.watch<AuthProvider>().userRole == 'worker';

    final List<Widget> tabs = isWorker
        ? [
            const WorkerHomeScreen(),
            const BookingScheduleScreen(),
            const ChatInboxScreen(),
            const NotificationCenterScreen(),
            const ProfileTabScreen(),
          ]
        : [
            const ClientHomeScreen(),
            const BookingHistoryScreen(),
            const ChatInboxScreen(),
            const NotificationCenterScreen(),
            const ProfileTabScreen(),
          ];

    final bool slidingRight = _currentIndex > _previousIndex;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          if (_currentIndex != 4) const TabTopBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) {
                final isIncoming = child.key == ValueKey(_currentIndex);
                final begin = isIncoming
                    ? Offset(slidingRight ? 1.0 : -1.0, 0)
                    : Offset(slidingRight ? -1.0 : 1.0, 0);
                return SlideTransition(
                  position: Tween<Offset>(begin: begin, end: Offset.zero)
                      .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: tabs[_currentIndex],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: (isWorker && _currentIndex == 0)
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, AppRouter.createJobPost),
              label: const Text('New Post', style: TextStyle(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            )
          : null,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTabTap: _onTabTap,
      ),
    );
  }
}
