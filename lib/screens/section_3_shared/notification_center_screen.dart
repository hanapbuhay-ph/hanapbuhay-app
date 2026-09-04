import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../data/models/notification_model.dart';

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
    _notificationsFuture = context.read<NotificationProvider>().getNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
        children: [
          Expanded(
            child: FutureBuilder<List<AppNotification>>(
              future: _notificationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
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
                  color: theme.colorScheme.primary,
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
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnread = !notification.isRead;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isUnread ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isUnread ? [
          BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ] : null,
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.15)),
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
                      style: AppTypography.bodySmall.copyWith(fontSize: 10, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconCircle(AppNotification notification) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    IconData icon;
    Color color;
    Color bgColor;

    switch (notification.type) {
      case NotificationType.bookingAccepted:
      case NotificationType.bookingUpdated:
        icon = Icons.work;
        color = colorScheme.primary;
        bgColor = colorScheme.primary.withValues(alpha: 0.1);
        break;
      case NotificationType.newChatMessage:
        icon = Icons.chat;
        color = const Color(0xFF835400); 
        bgColor = const Color(0xFFFFDDB5).withValues(alpha: 0.2);
        break;
      case NotificationType.verificationApproved:
        icon = Icons.verified_user;
        color = colorScheme.primary;
        bgColor = colorScheme.primary.withValues(alpha: 0.1);
        break;
      case NotificationType.bookingCompleted:
        icon = Icons.history;
        color = colorScheme.onSurfaceVariant;
        bgColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
        break;
      case NotificationType.newRatingReceived:
        icon = Icons.star;
        color = Colors.amber;
        bgColor = Colors.amber.withValues(alpha: 0.1);
        break;
      default:
        icon = Icons.notifications;
        color = colorScheme.primary;
        bgColor = colorScheme.primary.withValues(alpha: 0.1);
    }

    if (notification.isRead) {
       color = colorScheme.onSurfaceVariant;
       bgColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildFormattedText(String body, bool isUnread) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final parts = body.split('**');
    return RichText(
      text: TextSpan(
        style: AppTypography.bodyMedium.copyWith(
          color: colorScheme.onSurface,
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
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
    final notificationProvider = context.read<NotificationProvider>();
    await notificationProvider.markAsRead(notification.id);
    if (!mounted) return;

    setState(() => _loadNotifications());

    switch (notification.type) {
      case NotificationType.bookingAccepted:
      case NotificationType.bookingUpdated:
      case NotificationType.bookingCompleted:
        final role = context.read<AuthProvider>().userRole;
        if (role == 'worker') {
          Navigator.pushNamed(context, '${AppRouter.jobDetail}/${notification.relatedId}');
        } else {
          Navigator.pushNamed(context, '${AppRouter.bookingDetail}/${notification.relatedId}');
        }
        break;
      case NotificationType.newChatMessage:
        Navigator.pushNamed(context, '${AppRouter.chatThread}/${notification.relatedId}');
        break;
      case NotificationType.verificationApproved:
        Navigator.pushNamed(context, AppRouter.verificationStatus);
        break;
      case NotificationType.newRatingReceived:
        final role = context.read<AuthProvider>().userRole;
        if (role == 'worker') {
           Navigator.pushNamed(context, AppRouter.bookingSchedule);
        } else {
           Navigator.pushNamed(context, AppRouter.bookingHistory);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: colorScheme.outlineVariant),
            const SizedBox(height: 24),
            Text('No Notifications', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            Text(
              'You haven\'t received any notifications yet. Updates about your bookings and messages will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
