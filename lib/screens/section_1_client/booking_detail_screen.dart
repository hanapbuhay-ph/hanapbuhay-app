import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/info/compact_info_row.dart';
import '../../providers/booking_provider.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/worker_model.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/navigation/app_bottom_nav.dart';
import '../../widgets/maps/live_tracking_map.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final bool autoTrack;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    this.autoTrack = false,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Booking? _booking;
  Worker? _worker;
  bool _isLoading = true;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _isTracking = widget.autoTrack;
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
        });
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
      return const Scaffold(body: Center(child: Text('Booking not found')));
    }

    final booking = _booking!;
    final worker = _worker!;
    final showMap = booking.status == BookingStatus.accepted || booking.status == BookingStatus.active;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          AppHeader(title: 'Booking ${booking.bookingCode}'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWorkerCard(worker),
                  const SizedBox(height: 24),
                  
                  if (showMap) ...[
                    _buildMapSection(booking, worker),
                    const SizedBox(height: 24),
                  ],

                  _buildJobDetails(booking),
                  const SizedBox(height: 24),

                  _buildTimeline(booking),
                  const SizedBox(height: 32),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '${AppRouter.fileReport}/${booking.id}');
                      },
                      child: Text(
                        'File an Issue Report',
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildWorkerCard(Worker worker) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          CircleAvatar(radius: 24, backgroundImage: NetworkImage(worker.avatarUrl)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(worker.rating.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '${AppRouter.chatThread}/c1'); // Mock ID
            },
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
    // Conceptual client location: Poblacion center
    const clientLoc = LatLng(9.9575, 124.3517);
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
          
          // Map Overlays
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'view_map',
              onPressed: () => Navigator.pushNamed(context, '${AppRouter.bookingDetail}/${booking.id}/tracking'),
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
                          _isTracking ? 'Worker is en route' : 'Booking Confirmed',
                          style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                        ),
                        Text(
                          _isTracking ? 'Arriving in ~10 mins' : 'Worker will arrive on schedule',
                          style: AppTypography.bodySmall.copyWith(fontSize: 10, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => _isTracking = !_isTracking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTracking ? colorScheme.errorContainer : colorScheme.primary,
                      foregroundColor: _isTracking ? colorScheme.error : colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_isTracking ? 'I\'ve Arrived' : 'I\'m on my way', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetails(Booking booking) {
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
          Text('Job Details', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.category_outlined, 'Service', booking.category),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.calendar_today_outlined, 'Date & Time', '${AppFormatters.date(booking.date)} at ${booking.time}'),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.location_on_outlined, 'Service Barangay', booking.barangay),
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
    return CompactInfoRow(
      icon: icon,
      label: label,
      value: value,
      iconColor: Theme.of(context).colorScheme.primary,
      labelStyle: AppTypography.bodySmall.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 10,
      ),
      valueStyle: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTimeline(Booking booking) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status Timeline', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
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

}
