import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/booking_provider.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/worker_model.dart';
import '../../widgets/buttons/primary_button.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Booking>> _bookingsFuture;
  final List<BookingStatus> _tabs = [
    BookingStatus.upcoming,
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

  String _getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming: return 'Upcoming';
      case BookingStatus.active: return 'Ongoing';
      case BookingStatus.completed: return 'Completed';
      case BookingStatus.cancelled: return 'Cancelled';
      default: return '';
    }
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bookings',
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your upcoming and past bookings.',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Booking>>(
                  future: _bookingsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                    }
                    
                    final allBookings = snapshot.data ?? [];
                    
                    return Column(
                      children: [
                        _buildFilterChips(allBookings),
                        const SizedBox(height: 12),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: _tabs.map((status) {
                              final filteredList = allBookings.where((b) => b.status == status).toList();
                              if (filteredList.isEmpty) {
                                return _buildEmptyState(status);
                              }
                              return RefreshIndicator(
                                onRefresh: () async {
                                  setState(() => _loadBookings());
                                },
                                color: theme.colorScheme.primary,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) => _buildBookingCard(filteredList[index]),
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

  Color _getStatusColor(BookingStatus status, ColorScheme colorScheme) {
    switch (status) {
      case BookingStatus.pending: return colorScheme.primary;
      case BookingStatus.upcoming: return Colors.amber.shade700;
      case BookingStatus.active: return Colors.blue;
      case BookingStatus.completed: return Colors.grey.shade600;
      case BookingStatus.cancelled: return colorScheme.error;
      default: return Colors.grey;
    }
  }

  Widget _buildFilterChips(List<Booking> allBookings) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = _tabs[index];
          final isSelected = _tabController.index == index;
          final count = allBookings.where((booking) => booking.status == status).length;
          final color = _getStatusColor(status, colorScheme);

          return GestureDetector(
            onTap: () => setState(() => _tabController.animateTo(index)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : colorScheme.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.onPrimary : color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.onPrimary.withValues(alpha: 0.25) : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? colorScheme.onPrimary : color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<Worker?>(
      future: context.read<WorkerProvider>().getWorkerById(booking.workerId),
      builder: (context, snapshot) {
        final worker = snapshot.data;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
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
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(worker?.avatarUrl ?? 'https://i.pravatar.cc/150'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker?.name ?? 'Loading...',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          booking.category,
                          style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${booking.bookingCode}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusPill(booking.status),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDate(booking.date)} • ${booking.time}',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButtons(booking),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(BookingStatus status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color color;
    switch (status) {
      case BookingStatus.upcoming: color = Colors.amber; break;
      case BookingStatus.active: color = colorScheme.primary; break;
      case BookingStatus.completed: color = colorScheme.onSurfaceVariant; break;
      case BookingStatus.cancelled: color = colorScheme.error; break;
      default: color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildActionButtons(Booking booking) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (booking.status == BookingStatus.active) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _handleUpdateStatus(booking, BookingStatus.completed),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Confirm Done', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Track',
              onPressed: () {
                Navigator.pushNamed(context, '${AppRouter.bookingDetail}/${booking.id}?track=true');
              },
            ),
          ),
        ],
      );
    }
    
    return Row(
      children: [
        if (booking.status == BookingStatus.upcoming) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => _handleUpdateStatus(booking, BookingStatus.cancelled),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: colorScheme.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Cancel', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Reschedule',
              onPressed: () => _showRescheduleDialog(booking),
            ),
          ),
        ] else if (booking.status == BookingStatus.completed && !booking.isRated) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '${AppRouter.rateReview}/${booking.id}');
                if (result == true) {
                  _loadBookings();
                  setState(() {});
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Rate', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Details',
              onPressed: () {
                Navigator.pushNamed(context, '${AppRouter.bookingDetail}/${booking.id}');
              },
            ),
          ),
        ] else ...[
          Expanded(
            child: PrimaryButton(
              label: 'Details',
              onPressed: () {
                Navigator.pushNamed(context, '${AppRouter.bookingDetail}/${booking.id}');
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleUpdateStatus(Booking booking, BookingStatus newStatus) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus == BookingStatus.cancelled ? 'Cancel Booking' : 'Confirm Completion'),
        content: Text('Are you sure you want to ${newStatus == BookingStatus.cancelled ? 'cancel this booking' : 'mark this booking as completed'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes', style: TextStyle(color: newStatus == BookingStatus.cancelled ? theme.colorScheme.error : theme.colorScheme.primary)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await context.read<BookingProvider>().updateBookingStatus(bookingId: booking.id, status: newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
        _loadBookings();
        setState(() {});
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
        initialTime: TimeOfDay.now(),
      );
      
      if (pickedTime != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking rescheduled successfully! (Mock)')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildEmptyState(BookingStatus status) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 64, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No ${_getStatusLabel(status).toLowerCase()} bookings',
            style: AppTypography.headlineMedium.copyWith(fontSize: 20, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any ${_getStatusLabel(status).toLowerCase()} service requests at the moment.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
