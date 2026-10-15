import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../providers/booking_provider.dart';
import '../../providers/chat_provider.dart';
import '../../data/models/booking_model.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/filters/status_filter_chips.dart';
import '../../widgets/status/status_badge.dart';
import '../../widgets/user_avatar.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Booking>> _bookingsFuture;
  // 'today' is a virtual status — filtered client-side from accepted bookings
  static const String _todayTab = 'today';
  final List<dynamic> _tabs = [
    BookingStatus.pending,
    BookingStatus.accepted,
    _todayTab,
    BookingStatus.active,
    BookingStatus.completed,
    BookingStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadBookings();
  }

  void _loadBookings() {
    _bookingsFuture = context.read<BookingProvider>().getBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getTabLabel(dynamic tab) {
    if (tab == _todayTab) return 'Today';
    switch (tab as BookingStatus) {
      case BookingStatus.pending:
        return 'Requests';
      case BookingStatus.accepted:
        return 'Upcoming';
      case BookingStatus.active:
        return 'Ongoing';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      default:
        return '';
    }
  }

  String _getStatusLabel(BookingStatus status) => _getTabLabel(status);

  bool _matchesTab(dynamic tab, Booking booking) {
    if (tab == _todayTab) {
      final today = DateTime.now();
      return booking.status == BookingStatus.accepted &&
          booking.date.year == today.year &&
          booking.date.month == today.month &&
          booking.date.day == today.day;
    }
    if (tab == BookingStatus.accepted) {
      // Keep today's accepted bookings in the Today tab only.
      final today = DateTime.now();
      final isToday =
          booking.date.year == today.year &&
          booking.date.month == today.month &&
          booking.date.day == today.day;
      return booking.status == BookingStatus.accepted && !isToday;
    }
    return booking.status == (tab as BookingStatus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: theme.colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookings',
                        style: AppTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your upcoming and past bookings.',
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Booking>>(
                  future: _bookingsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      );
                    }

                    final allBookings = snapshot.data ?? [];

                    return Column(
                      children: [
                        _buildFilterChips(allBookings),
                        const SizedBox(height: 12),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: _tabs.map((tab) {
                              final filteredList = allBookings
                                  .where((b) => _matchesTab(tab, b))
                                  .toList();
                              if (filteredList.isEmpty) {
                                return _buildEmptyState(tab);
                              }
                              return RefreshIndicator(
                                onRefresh: () async {
                                  setState(() => _loadBookings());
                                },
                                color: theme.colorScheme.primary,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) =>
                                      _buildBookingCard(
                                        filteredList[index],
                                        isToday: tab == _todayTab,
                                      ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(dynamic tab, ColorScheme colorScheme) {
    if (tab == _todayTab) return Colors.green.shade600;
    switch (tab as BookingStatus) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.accepted:
        return Colors.amber.shade700;
      case BookingStatus.active:
        return colorScheme.primary;
      case BookingStatus.completed:
        return Colors.grey.shade600;
      case BookingStatus.cancelled:
        return colorScheme.error;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFilterChips(List<Booking> allBookings) {
    return StatusFilterChips<dynamic>(
      items: _tabs,
      selectedIndex: _tabController.index,
      onSelected: (index) => setState(() => _tabController.animateTo(index)),
      labelBuilder: _getTabLabel,
      countBuilder: (tab) =>
          allBookings.where((b) => _matchesTab(tab, b)).length,
      colorBuilder: (tab, colorScheme) => _getStatusColor(tab, colorScheme),
    );
  }

  Widget _buildBookingCard(Booking booking, {bool isToday = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: booking.workerProfileId == null
                      ? null
                      : () => Navigator.pushNamed(
                          context,
                          '${AppRouter.workerProfile}/${booking.workerProfileId}',
                        ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        UserAvatar(
                          name: booking.workerName ?? 'Worker',
                          radius: 24,
                          photoPath: booking.workerPhotoUrl,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.workerName ?? 'Worker',
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                booking.category,
                                style: AppTypography.bodySmall.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Code: ${booking.bookingCode}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusPill(booking.status),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppFormatters.date(booking.date)} • ${booking.time}',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButtons(booking, isToday: isToday),
          if (booking.status != BookingStatus.cancelled &&
              booking.status != BookingStatus.declined) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openConversation(booking),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Message Worker'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.45),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPill(BookingStatus status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color color;
    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        break;
      case BookingStatus.accepted:
        color = Colors.amber;
        break;
      case BookingStatus.active:
        color = colorScheme.primary;
        break;
      case BookingStatus.completed:
        color = Colors.grey.shade600;
        break;
      case BookingStatus.cancelled:
        color = colorScheme.error;
        break;
      default:
        color = Colors.grey;
    }

    return StatusBadge(
      label: _getStatusLabel(status),
      color: color,
      opacity: 0.15,
    );
  }

  Widget _buildActionButtons(Booking booking, {bool isToday = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isToday) {
      return Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: 'View Details',
              onPressed: () => _showReviewRequestSheet(booking),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PrimaryButton(
              label: 'Start Traveling',
              onPressed: () => Navigator.pushNamed(
                context,
                '${AppRouter.liveTracking}/${booking.id}',
              ),
            ),
          ),
        ],
      );
    }

    if (booking.status == BookingStatus.active) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  _handleUpdateStatus(booking, BookingStatus.completed),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm Done',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Track',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '${AppRouter.bookingDetail}/${booking.id}?track=true',
                );
              },
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (booking.status == BookingStatus.pending ||
            booking.status == BookingStatus.accepted) ...[
          Expanded(
            child: PrimaryButton(
              label: 'Review Request',
              onPressed: () => _showReviewRequestSheet(booking),
            ),
          ),
        ] else if (booking.status == BookingStatus.completed &&
            !booking.isRated) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '${AppRouter.rateReview}/${booking.id}',
                );
                if (result == true) {
                  _loadBookings();
                  setState(() {});
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Rate',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Details',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '${AppRouter.bookingDetail}/${booking.id}',
                );
              },
            ),
          ),
        ] else ...[
          Expanded(
            child: PrimaryButton(
              label: 'Details',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '${AppRouter.bookingDetail}/${booking.id}',
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openConversation(Booking booking) async {
    final conversationId = await context
        .read<ChatProvider>()
        .resolveConversationId(
          otherUserId: booking.workerId,
          fallbackBookingId: booking.id,
        );
    if (mounted) {
      Navigator.pushNamed(context, '${AppRouter.chatThread}/$conversationId');
    }
  }

  Future<void> _handleUpdateStatus(
    Booking booking,
    BookingStatus newStatus,
  ) async {
    final theme = Theme.of(context);
    final isCancelling = newStatus == BookingStatus.cancelled;

    String? reason;
    if (isCancelling) {
      final reasonController = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cancel Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Why are you cancelling this booking?'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Cancellation reason (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Back'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, reasonController.text.trim()),
              child: Text(
                'Confirm Cancel',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      );
      if (reason == null) return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCancelling ? 'Cancel Booking' : 'Confirm Completion'),
        content: Text(
          isCancelling
              ? 'Are you sure you want to cancel this booking?'
              : 'Are you sure you want to mark this booking as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes',
              style: TextStyle(
                color: isCancelling
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (isCancelling) {
        final result = await context.read<BookingProvider>().cancelBooking(
          bookingId: booking.id,
          reason: reason,
        );
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(result.message)));
          _loadBookings();
          setState(() {});
        }
      } else {
        final result = await context
            .read<BookingProvider>()
            .updateBookingStatus(bookingId: booking.id, status: newStatus);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(result.message)));
          _loadBookings();
          setState(() {});
        }
      }
    }
  }

  void _showRescheduleDialog(Booking booking) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: booking.date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(booking.date),
      );

      if (pickedTime != null && mounted) {
        final scheduledAt = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        final result = await context.read<BookingProvider>().rescheduleBooking(
          bookingId: booking.id,
          scheduledAt: scheduledAt,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: result.success
                  ? null
                  : Theme.of(context).colorScheme.error,
            ),
          );
          if (result.success) {
            _loadBookings();
            setState(() {});
          }
        }
      }
    }
  }

  void _showReviewRequestSheet(Booking booking) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header — worker info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(
                              booking.workerPhotoUrl ??
                                  'https://i.pravatar.cc/150',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.workerName ?? 'Worker',
                                  style: AppTypography.headlineMedium.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    booking.category,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusPill(booking.status),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Details
                      Text(
                        'Booking Details',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSheetDetailRow(
                        colorScheme,
                        Icons.tag,
                        'Booking Code',
                        booking.bookingCode,
                      ),
                      const SizedBox(height: 14),
                      _buildSheetDetailRow(
                        colorScheme,
                        Icons.calendar_today_outlined,
                        'Date & Time',
                        '${AppFormatters.date(booking.date)} • ${booking.time}',
                      ),
                      const SizedBox(height: 14),
                      _buildSheetDetailRow(
                        colorScheme,
                        Icons.location_on_outlined,
                        'Location',
                        booking.barangay,
                      ),
                      const SizedBox(height: 14),
                      _buildSheetDetailRow(
                        colorScheme,
                        Icons.build_outlined,
                        'Service',
                        booking.category,
                      ),
                      if (booking.notes.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Divider(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your Notes',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            booking.notes,
                            style: AppTypography.bodyMedium.copyWith(
                              color: colorScheme.onSurface,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Action buttons — Cancel + Reschedule
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  12,
                  24,
                  MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleUpdateStatus(booking, BookingStatus.cancelled);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: colorScheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Reschedule',
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRescheduleDialog(booking);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetDetailRow(
    ColorScheme colorScheme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(dynamic tab) {
    final theme = Theme.of(context);
    final label = _getTabLabel(tab).toLowerCase();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 64,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No $label bookings',
            style: AppTypography.headlineMedium.copyWith(
              fontSize: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tab == _todayTab
                ? 'No bookings are scheduled for today.'
                : 'You don\'t have any $label service requests at the moment.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
