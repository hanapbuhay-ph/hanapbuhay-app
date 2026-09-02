import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/booking_provider.dart';
import '../../data/models/booking_model.dart';
import '../../providers/auth_provider.dart';

class BookingScheduleScreen extends StatefulWidget {
  const BookingScheduleScreen({super.key});

  @override
  State<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends State<BookingScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Booking>> _bookingsFuture;
  final List<BookingStatus> _tabs = [
    BookingStatus.pending,
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

  void jumpToTab(int index) {
    _tabController.animateTo(index);
  }

  void _loadBookings() {
    _bookingsFuture = context.read<BookingProvider>().getBookings();
  }

  Future<void> _handleResponse(String bookingId, bool accept) async {
    final bookingProvider = context.read<BookingProvider>();
    final result = await bookingProvider.respondToBooking(bookingId: bookingId, accept: accept);
    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: accept ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
      );
      if (accept) Navigator.pushNamed(context, '${AppRouter.jobDetail}/$bookingId');
      setState(() => _loadBookings());
    }
  }

  void _showRequestDetail(Booking request) {
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
            color: colorScheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(radius: 28, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=client')),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Client Name', style: AppTypography.headlineMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(request.category, style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 20),
                      Text('Request Details', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      _buildSheetDetailRow(colorScheme, Icons.calendar_today_outlined, 'Date & Time', '${_formatDate(request.date)} • ${request.time}'),
                      const SizedBox(height: 14),
                      _buildSheetDetailRow(colorScheme, Icons.location_on_outlined, 'Location', 'Trinidad (${request.barangay})'),
                      const SizedBox(height: 14),
                      _buildSheetDetailRow(colorScheme, Icons.build_outlined, 'Service', request.category),
                      if (request.notes.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text('Client Notes', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request.notes,
                            style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleResponse(request.id, false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: colorScheme.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Decline', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleResponse(request.id, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildSheetDetailRow(ColorScheme colorScheme, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return 'Requests';
      case BookingStatus.upcoming: return 'Upcoming';
      case BookingStatus.active: return 'Ongoing';
      case BookingStatus.completed: return 'Completed';
      case BookingStatus.cancelled: return 'Cancelled';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
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
                      Text('Job Schedule', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your upcoming and past bookings.',
                        style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSegmentedControl(),
                Expanded(
                  child: FutureBuilder<List<Booking>>(
                    future: _bookingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: colorScheme.primary));
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
                            color: colorScheme.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) => _buildJobCard(filteredList[index]),
                            ),
                          );
                        }).toList(),
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

  Widget _buildHeader(AuthProvider authProvider) => const SizedBox.shrink();

  Widget _buildSegmentedControl() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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

  Widget _buildJobCard(Booking booking) {
    final colorScheme = Theme.of(context).colorScheme;

    // Pending requests use a distinct tappable card that opens the detail sheet
    if (booking.status == BookingStatus.pending) {
      return GestureDetector(
        onTap: () => _showRequestDetail(booking),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border(left: BorderSide(color: colorScheme.primary, width: 4)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 24, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=client')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Client Name', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(booking.category, style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusPill(booking.status),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('${_formatDate(booking.date)} • ${booking.time}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(booking.barangay, style: AppTypography.bodySmall),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.touch_app_outlined, size: 13, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('Tap to view full details', style: AppTypography.bodySmall.copyWith(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // All other statuses use the standard job card
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 24, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=client')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client Name', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(booking.category, style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Text('Ref: ${booking.bookingCode}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              _buildStatusPill(booking.status),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today_outlined, _getRelativeDate(booking.date), '${_formatDate(booking.date)} • ${booking.time}'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, 'Trinidad (${booking.barangay})', '~1.5 km away'),
          const SizedBox(height: 20),
          Row(
            children: [
              if (booking.status == BookingStatus.completed && !booking.isClientRated) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final result = await Navigator.pushNamed(context, '${AppRouter.rateClient}/${booking.id}');
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
                    child: Text('Rate Client', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '${AppRouter.jobDetail}/${booking.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: booking.status == BookingStatus.upcoming ? colorScheme.primary : colorScheme.surfaceVariant,
                    foregroundColor: booking.status == BookingStatus.upcoming ? colorScheme.onPrimary : colorScheme.onSurface,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pushNamed(context, '${AppRouter.chatThread}/c1'),
                  icon: Icon(Icons.chat_bubble_outline, color: colorScheme.onSurfaceVariant, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(BookingStatus status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color color;
    String label = _getStatusLabel(status);
    
    switch (status) {
      case BookingStatus.upcoming: 
        color = Colors.amber;
        label = 'Scheduled';
        break;
      case BookingStatus.active: 
        color = colorScheme.primary;
        label = 'Confirmed';
        break;
      case BookingStatus.completed: color = colorScheme.onSurfaceVariant; break;
      case BookingStatus.cancelled: color = colorScheme.error; break;
      default: color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String sublabel) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            Text(sublabel, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
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
          Icon(Icons.inventory_2_outlined, size: 64, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            status == BookingStatus.pending
                ? 'No pending requests.'
                : 'No more ${_getStatusLabel(status).toLowerCase()} jobs.',
            style: AppTypography.headlineMedium.copyWith(fontSize: 20, color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
