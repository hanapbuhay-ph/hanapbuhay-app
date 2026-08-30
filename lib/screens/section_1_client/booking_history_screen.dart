import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/booking_provider.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/worker_model.dart';
import '../../widgets/navigation/client_bottom_nav.dart';
import '../../widgets/navigation/app_header.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 1. Header
          AppHeader(
            title: 'My Bookings',
            onBackPressed: () => Navigator.pushReplacementNamed(context, AppRouter.clientHome),
          ),

          // 2. Segmented Control (Pill-shaped tabs)
          _buildSegmentedControl(),

          // 3. Bookings List
          Expanded(
            child: FutureBuilder<List<Booking>>(
              future: _bookingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                
                final allBookings = snapshot.data ?? [];
                
                return TabBarView(
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
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) => _buildBookingCard(filteredList[index]),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ClientBottomNav(currentIndex: 1),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(32),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTypography.labelLarge,
        tabs: _tabs.map((status) => Tab(text: _getStatusLabel(status))).toList(),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return FutureBuilder<Worker?>(
      future: context.read<WorkerProvider>().getWorkerById(booking.workerId),
      builder: (context, snapshot) {
        final worker = snapshot.data;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceContainerHigh),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          booking.category,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
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
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDate(booking.date)} • ${booking.time}',
                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
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
    Color color;
    switch (status) {
      case BookingStatus.upcoming: color = Colors.amber; break;
      case BookingStatus.active: color = AppColors.primary; break;
      case BookingStatus.completed: color = AppColors.onSurfaceVariant; break;
      case BookingStatus.cancelled: color = AppColors.error; break;
      default: color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildActionButtons(Booking booking) {
    if (booking.status == BookingStatus.active) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _handleUpdateStatus(booking, BookingStatus.completed),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Done', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
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
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
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
                side: const BorderSide(color: AppColors.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Rate', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus == BookingStatus.cancelled ? 'Cancel Booking' : 'Confirm Completion'),
        content: Text('Are you sure you want to ${newStatus == BookingStatus.cancelled ? 'cancel this booking' : 'mark this booking as completed'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes', style: TextStyle(color: newStatus == BookingStatus.cancelled ? AppColors.error : AppColors.primary)),
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
        // TODO: Call repository to update booking
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No ${_getStatusLabel(status).toLowerCase()} bookings',
            style: AppTypography.headlineMedium.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any ${_getStatusLabel(status).toLowerCase()} service requests at the moment.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
