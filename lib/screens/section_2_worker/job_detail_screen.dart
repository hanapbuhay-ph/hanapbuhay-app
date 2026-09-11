import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../providers/booking_provider.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/auth_result_model.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/navigation/worker_bottom_nav.dart';
import '../../widgets/maps/live_tracking_map.dart';
import '../../widgets/buttons/primary_button.dart';

class JobDetailScreen extends StatefulWidget {
  final String bookingId;

  const JobDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Booking? _booking;
  Worker? _worker;
  bool _isLoading = true;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookingProvider = context.read<BookingProvider>();
    final workerProvider = context.read<WorkerProvider>();
    final booking = await bookingProvider.getBookingById(widget.bookingId);
    if (booking != null) {
      final worker = await workerProvider.getWorkerById(booking.workerId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _worker = worker;
          _isLoading = false;
          // Conceptually, if status is 'active' (en route), we show the map
          _isTracking = booking.status == BookingStatus.active;
        });
      }
    }
  }

  Future<void> _updateStatus(BookingStatus newStatus) async {
    setState(() => _isLoading = true);
    final bookingProvider = context.read<BookingProvider>();
    final AuthResult result;

    if (newStatus == BookingStatus.active) {
      // POST /api/bookings/{id}/start — sets started_at on the booking.
      // Do NOT use startTracking() here — that is the location-sharing endpoint.
      result = await bookingProvider.startBooking(bookingId: widget.bookingId);
    } else if (newStatus == BookingStatus.completed) {
      // POST /api/bookings/{id}/complete
      result = await bookingProvider.completeBooking(bookingId: widget.bookingId);
    } else {
      result = await bookingProvider.updateBookingStatus(bookingId: widget.bookingId, status: newStatus);
    }

    if (mounted) {
      if (result.success) {
        await _loadData();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    }

    if (_booking == null || _worker == null) {
      return const Scaffold(body: Center(child: Text('Job not found')));
    }

    final booking = _booking!;
    final worker = _worker!;
    final showMap = booking.status == BookingStatus.active;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          AppHeader(title: 'Job ${booking.bookingCode}'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClientCard(),
                  const SizedBox(height: 24),
                  
                  if (showMap) ...[
                    _buildMapSection(booking, worker),
                    const SizedBox(height: 24),
                  ],

                  _buildBookingDetails(booking),
                  const SizedBox(height: 24),

                  _buildTimeline(booking),
                  const SizedBox(height: 32),

                  _buildConditionalAction(booking),
                  
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '${AppRouter.fileReport}/${booking.id}'),
                      icon: Icon(Icons.report_problem_outlined, size: 16, color: colorScheme.error),
                      label: Text(
                        'File a Report',
                        style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const WorkerBottomNav(currentIndex: 1),
    );
  }

  Widget _buildClientCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final booking = _booking!;

    // Use real client data from GET /api/bookings/{id} response.
    // Booking.fromJson parses clientName + clientPhotoUrl from the API.
    final clientName = booking.clientName ?? 'Client';
    final clientPhoto = AppConstants.getPhotoUrl(booking.clientPhotoUrl);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(clientPhoto),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clientName, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                Text('Client', style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            // Use booking.id as the chat thread identifier (matches /api/messages/{bookingId})
            onPressed: () => Navigator.pushNamed(context, '${AppRouter.chatThread}/${booking.id}'),
            icon: Icon(Icons.chat_bubble_outline, color: colorScheme.primary),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(Booking booking, Worker worker) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use real client barangay coordinates from GET /api/bookings/{id} response.
    // GET /api/bookings/{id}/tracking returns barangay coords (not live location).
    // Fallback to a default Trinidad coord if not yet available.
    final clientLoc = booking.clientBarangayCoordinates ?? const LatLng(9.9575, 124.3517);
    final workerLoc = worker.barangayCoordinates ?? const LatLng(9.9312, 124.3121);

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          LiveTrackingMap(
            clientLocation: clientLoc,
            workerLocation: workerLoc,
            isTracking: _isTracking,
            onArrival: () => setState(() => _isTracking = false),
          ),
          
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'view_map_worker',
              // Navigate to WorkerMapScreen (not the client LiveTrackingScreen)
              onPressed: () => Navigator.pushNamed(context, '${AppRouter.workerMap}/${booking.id}'),
              backgroundColor: colorScheme.surface,
              child: Icon(Icons.fullscreen, color: colorScheme.onSurfaceVariant),
            ),
          ),

          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isTracking ? 'Traveling to client' : 'Arrived at destination',
                          style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                        ),
                        Text(
                          _isTracking ? 'Sharing location with client' : 'Please proceed with the service',
                          style: AppTypography.bodySmall.copyWith(fontSize: 10, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (_isTracking)
                    ElevatedButton(
                      // POST /api/bookings/{id}/tracking/stop — stop location sharing
                      onPressed: () async {
                        await context.read<BookingProvider>().stopTracking(bookingId: widget.bookingId);
                        if (mounted) setState(() => _isTracking = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("I've Arrived", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails(Booking booking) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking Details', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.build_outlined, 'Service Type', booking.category),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.calendar_today_outlined, 'Date & Time', '${AppFormatters.date(booking.date)} • ${booking.time}'),
          const SizedBox(height: 16),
          _buildLocationRow(booking),
          const SizedBox(height: 20),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Notes', style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(booking.notes, style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 10)),
            Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationRow(Booking booking) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 18, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location', style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 10)),
              Text('Trinidad (${booking.clientBarangay ?? booking.barangay})', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            if (_booking!.status == BookingStatus.accepted) {
              _updateStatus(BookingStatus.active);
            }
          },
          child: Text('View on Map', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildTimeline(Booking booking) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Job Status', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
        const SizedBox(height: 24),
        ...booking.timeline.asMap().entries.map((entry) {
          final idx = entry.key;
          final step = entry.value;
          final isLast = idx == booking.timeline.length - 1;
          
          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: step.isCompleted ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: step.isCompleted ? null : Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: step.isCompleted 
                        ? Icon(Icons.check, size: 12, color: colorScheme.onPrimary) 
                        : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: step.isCompleted ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: step.isCompleted ? FontWeight.w700 : FontWeight.w400,
                            color: step.isCompleted ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (step.timestamp != null)
                          Text(
                            '${step.timestamp!.hour}:${step.timestamp!.minute.toString().padLeft(2, '0')}',
                            style: AppTypography.bodySmall.copyWith(fontSize: 10, color: colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConditionalAction(Booking booking) {
    if (booking.status == BookingStatus.accepted) {
      return PrimaryButton(
        label: 'Start Traveling',
        onPressed: () => _updateStatus(BookingStatus.active),
      );
    }
    
    if (booking.status == BookingStatus.active && !_isTracking) {
      return PrimaryButton(
        label: 'Mark as Completed',
        onPressed: () => _updateStatus(BookingStatus.completed),
      );
    }

    return const SizedBox.shrink();
  }

}
