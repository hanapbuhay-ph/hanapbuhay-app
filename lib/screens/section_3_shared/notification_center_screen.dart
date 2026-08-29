import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_locator.dart';
import '../../data/models/notification_model.dart';
import '../../widgets/navigation/client_bottom_nav.dart';
import '../../widgets/navigation/worker_bottom_nav.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    _notificationsFuture = notificationRepository.getNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isWorker = authProvider.userRole == 'worker';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<List<AppNotification>>(
              future: _notificationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final allNotifications = snapshot.data ?? [];
                if (allNotifications.isEmpty) {
                  return _buildEmptyState();
                }

                // Group by Today/Earlier
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final todayNotifications = allNotifications.where((n) => n.createdAt.isAfter(today)).toList();
                final earlierNotifications = allNotifications.where((n) => n.createdAt.isBefore(today)).toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _loadNotifications());
                  },
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    children: [
                      if (todayNotifications.isNotEmpty) ...[
                        _buildSectionHeader('Today'),
                        const SizedBox(height: 12),
                        ...todayNotifications.map((n) => _buildNotificationCard(n)),
                        const SizedBox(height: 24),
                      ],
                      if (earlierNotifications.isNotEmpty) ...[
                        _buildSectionHeader('Earlier'),
                        const SizedBox(height: 12),
                        ...earlierNotifications.map((n) => _buildNotificationCard(n)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWorker 
          ? const WorkerBottomNav(currentIndex: 3) 
          : const ClientBottomNav(currentIndex: 3),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.menu, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 16),
            Text('Notifications', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=current_user')),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final isUnread = !notification.isRead;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isUnread ? [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ] : null,
        border: Border.all(color: AppColors.surfaceVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconCircle(notification),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormattedText(notification.body, isUnread),
                    const SizedBox(height: 8),
                    Text(
                      _formatRelativeTime(notification.createdAt),
                      style: AppTypography.bodySmall.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconCircle(AppNotification notification) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (notification.type) {
      case NotificationType.bookingAccepted:
      case NotificationType.bookingUpdated:
        icon = Icons.work;
        color = AppColors.primary;
        bgColor = AppColors.secondaryContainer.withValues(alpha: 0.3);
        break;
      case NotificationType.newChatMessage:
        icon = Icons.chat;
        color = const Color(0xFF835400); // Tertiary
        bgColor = const Color(0xFFFFDDB5).withValues(alpha: 0.3);
        break;
      case NotificationType.verificationApproved:
        icon = Icons.verified_user;
        color = AppColors.primary;
        bgColor = AppColors.primaryContainer.withValues(alpha: 0.1);
        break;
      case NotificationType.bookingCompleted:
        icon = Icons.history;
        color = AppColors.onSurfaceVariant;
        bgColor = AppColors.surfaceVariant.withValues(alpha: 0.5);
        break;
      case NotificationType.newRatingReceived:
        icon = Icons.star;
        color = AppColors.onSurfaceVariant;
        bgColor = AppColors.surfaceVariant.withValues(alpha: 0.5);
        break;
      default:
        icon = Icons.notifications;
        color = AppColors.primary;
        bgColor = AppColors.surfaceContainer;
    }

    if (!notification.isRead) {
       // Already handled by colors above based on type
    } else {
       // Greyscale for read
       color = AppColors.onSurfaceVariant;
       bgColor = AppColors.surfaceVariant.withValues(alpha: 0.5);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildFormattedText(String body, bool isUnread) {
    // Basic markdown-like bold support
    final parts = body.split('**');
    return RichText(
      text: TextSpan(
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.onSurface,
          fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
          height: 1.4,
        ),
        children: List.generate(parts.length, (index) {
          final isBold = index % 2 != 0;
          return TextSpan(
            text: parts[index],
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : null),
          );
        }),
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) async {
    await notificationRepository.markAsRead(notification.id);
    if (!mounted) return;

    setState(() => _loadNotifications());

    switch (notification.type) {
      case NotificationType.bookingAccepted:
      case NotificationType.bookingUpdated:
      case NotificationType.bookingCompleted:
        final role = context.read<AuthProvider>().userRole;
        if (role == 'worker') {
          context.push('${AppRouter.jobDetail}/${notification.relatedId}');
        } else {
          context.push('${AppRouter.bookingDetail}/${notification.relatedId}');
        }
        break;
      case NotificationType.newChatMessage:
        context.push('${AppRouter.chatThread}/${notification.relatedId}');
        break;
      case NotificationType.verificationApproved:
        context.push(AppRouter.verificationStatus);
        break;
      case NotificationType.newRatingReceived:
        final role = context.read<AuthProvider>().userRole;
        if (role == 'worker') {
           // For worker, rate client screen or jobs list? Instruction says "own Profile/reviews tab"
           // For now, go to schedule to see completed jobs
           context.push(AppRouter.bookingSchedule);
        } else {
           context.push(AppRouter.bookingHistory);
        }
        break;
      default:
        break;
    }
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${_monthName(time.month)} ${time.day}';
  }

  String _monthName(int month) {
    return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off_outlined, size: 80, color: AppColors.outlineVariant),
            const SizedBox(height: 24),
            Text('No Notifications', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text(
              'You haven\'t received any notifications yet. Updates about your bookings and messages will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
