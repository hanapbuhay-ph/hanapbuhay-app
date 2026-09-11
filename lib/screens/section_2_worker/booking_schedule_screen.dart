import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/status/status_badge.dart';
import '../../widgets/info/compact_info_row.dart';
import '../../providers/booking_provider.dart';
import '../../providers/chat_provider.dart';
import '../../data/models/booking_model.dart';
import '../../widgets/filters/status_filter_chips.dart';
import '../../widgets/info/detail_info_row.dart';

class BookingScheduleScreen extends StatefulWidget {
  const BookingScheduleScreen({super.key});

  @override
  State<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends State<BookingScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Booking>> _bookingsFuture;
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

  void jumpToTab(int index) {
    _tabController.animateTo(index);
  }

  void _loadBookings() {
    // GET /api/bookings — no status filter; load all and filter client-side by tab.
    // The API supports ?status= but returning all at once avoids 5 separate requests.
    _bookingsFuture = context.read<BookingProvider>().getBookings();
  }

  Future<void> _handleResponse(String bookingId, bool accept) async {
    final bookingProvider = context.read<BookingProvider>();
    // Use dedicated accept/decline routes (wired in C1)
    final result = accept
        ? await bookingProvider.acceptBooking(bookingId: bookingId)
        : await bookingProvider.declineBooking(bookingId: bookingId);
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
            color: colorScheme.surface,
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
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(AppConstants.getPhotoUrl(request.clientPhotoUrl)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(request.clientName ?? 'Client', style: AppTypography.headlineMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
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
                      _buildSheetDetailRow(colorScheme, Icons.calendar_today_outlined, 'Date & Time', '${AppFormatters.date(request.date)} • ${request.time}'),
                      const SizedBox(height: 14),
                      _buildSheetDetailRow(colorScheme, Icons.location_on_outlined, 'Location', '${AppConstants.municipalityName} (${request.clientBarangay ?? request.barangay})'),
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
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
    return DetailInfoRow(
      icon: icon,
      label: label,
      value: value,
      iconColor: colorScheme.primary,
      labelColor: colorScheme.onSurfaceVariant,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getTabLabel(dynamic tab) {
    if (tab == _todayTab) return 'Today';
    switch (tab as BookingStatus) {
      case BookingStatus.pending: return 'Requests';
      case BookingStatus.accepted: return 'Upcoming';
      case BookingStatus.active: return 'Ongoing';
      case BookingStatus.completed: return 'Completed';
      case BookingStatus.cancelled: return 'Cancelled';
      default: return '';
    }
  }

  String _getStatusLabel(BookingStatus status) => _getTabLabel(status);

  bool _isToday(Booking booking) {
    final today = DateTime.now();
    return booking.date.year == today.year &&
        booking.date.month == today.month &&
        booking.date.day == today.day;
  }

  bool _matchesTab(dynamic tab, Booking booking) {
    if (tab == _todayTab) {
      return booking.status == BookingStatus.accepted && _isToday(booking);
    }
    if (tab == BookingStatus.accepted) {
      // Exclude today's bookings — they belong to the Today tab only
      return booking.status == BookingStatus.accepted && !_isToday(booking);
    }
    return booking.status == (tab as BookingStatus);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
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
                Expanded(
                  child: FutureBuilder<List<Booking>>(
                    future: _bookingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: colorScheme.primary));
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
                                final filteredList = allBookings.where((b) => _matchesTab(tab, b)).toList();
                                if (filteredList.isEmpty) return _buildEmptyState(tab);
                                return RefreshIndicator(
                                  onRefresh: () async => setState(() => _loadBookings()),
                                  color: colorScheme.primary,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: filteredList.length,
                                    itemBuilder: (context, index) => _buildJobCard(filteredList[index], isToday: tab == _todayTab),
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

  Color _getTabColor(dynamic tab, ColorScheme colorScheme) {
    if (tab == _todayTab) return Colors.green.shade600;
    switch (tab as BookingStatus) {
      case BookingStatus.pending: return colorScheme.primary;
      case BookingStatus.accepted: return Colors.amber.shade700;
      case BookingStatus.active: return Colors.blue;
      case BookingStatus.completed: return Colors.grey.shade600;
      case BookingStatus.cancelled: return colorScheme.error;
      default: return Colors.grey;
    }
  }

  Widget _buildFilterChips(List<Booking> allBookings) {
    return StatusFilterChips<dynamic>(
      items: _tabs,
      selectedIndex: _tabController.index,
      onSelected: (index) => setState(() => _tabController.animateTo(index)),
      labelBuilder: _getTabLabel,
      countBuilder: (tab) => allBookings.where((b) => _matchesTab(tab, b)).length,
      colorBuilder: (tab, colorScheme) => _getTabColor(tab, colorScheme),
    );
  }

  Widget _buildJobCard(Booking booking, {bool isToday = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    // Pending requests
    if (booking.status == BookingStatus.pending) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(radius: 24, backgroundImage: NetworkImage(AppConstants.getPhotoUrl(booking.clientPhotoUrl))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.clientName ?? 'Client', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
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
            Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3), height: 1),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today_outlined, AppFormatters.relativeDate(booking.date), '${AppFormatters.date(booking.date)} • ${booking.time}'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, '${AppConstants.municipalityName} (${booking.clientBarangay ?? booking.barangay})', ''),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showRequestDetail(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Review Request', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    // Today card — View Details + Start Traveling + Message
    if (isToday) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
          boxShadow: [
            BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(radius: 24, backgroundImage: NetworkImage(AppConstants.getPhotoUrl(booking.clientPhotoUrl))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.clientName ?? 'Client', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('Today', style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                StatusBadge(label: booking.time, color: Colors.green.shade600),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3), height: 1),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.build_outlined, booking.category, ''),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, '${AppConstants.municipalityName} (${booking.clientBarangay ?? booking.barangay})', ''),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '${AppRouter.jobDetail}/${booking.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurface,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _startTraveling(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Start Traveling', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _openConversation(booking),
                    icon: Icon(Icons.chat_bubble_outline, color: colorScheme.onSurfaceVariant, size: 20),
                  ),
                ),
              ],
            ),
          ],
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
          BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 24, backgroundImage: NetworkImage(AppConstants.getPhotoUrl(booking.clientPhotoUrl))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.clientName ?? 'Client', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
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
          _buildInfoRow(Icons.calendar_today_outlined, AppFormatters.relativeDate(booking.date), '${AppFormatters.date(booking.date)} • ${booking.time}'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, '${AppConstants.municipalityName} (${booking.clientBarangay ?? booking.barangay})', ''),
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
                    backgroundColor: booking.status == BookingStatus.accepted ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                    foregroundColor: booking.status == BookingStatus.accepted ? colorScheme.onPrimary : colorScheme.onSurface,
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
                  onPressed: () => _openConversation(booking),
                  icon: Icon(Icons.chat_bubble_outline, color: colorScheme.onSurfaceVariant, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openConversation(Booking booking) async {
    final conversationId = await context.read<ChatProvider>().resolveConversationId(
      otherUserId: booking.clientId,
      fallbackBookingId: booking.id,
    );
    if (mounted) {
      Navigator.pushNamed(context, '${AppRouter.chatThread}/$conversationId');
    }
  }

  Future<void> _startTraveling(Booking booking) async {
    if (booking.status == BookingStatus.active) {
      if (mounted) {
        Navigator.pushNamed(context, '${AppRouter.workerMap}/${booking.id}');
      }
      return;
    }

    if (booking.status != BookingStatus.accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This booking is not ready to start.')),
      );
      return;
    }

    final result = await context.read<BookingProvider>().startBooking(bookingId: booking.id);
    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    Navigator.pushNamed(context, '${AppRouter.workerMap}/${booking.id}');
  }

  Widget _buildStatusPill(BookingStatus status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color color;
    String label = _getStatusLabel(status);
    
    switch (status) {
      case BookingStatus.accepted: 
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
    
    return StatusBadge(
      label: label,
      color: color,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String sublabel) {
    return CompactInfoRow(
      icon: icon,
      label: label,
      value: sublabel,
    );
  }

  Widget _buildEmptyState(dynamic tab) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            tab == _todayTab
                ? 'No jobs scheduled for today.'
                : tab == BookingStatus.pending
                    ? 'No pending requests.'
                    : 'No more ${_getTabLabel(tab).toLowerCase()} jobs.',
            style: AppTypography.headlineMedium.copyWith(fontSize: 20, color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
