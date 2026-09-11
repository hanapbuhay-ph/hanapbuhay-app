import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/info/compact_info_row.dart';
import '../../providers/booking_provider.dart';
import '../../providers/chat_provider.dart';
import '../../data/models/booking_model.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/navigation/app_bottom_nav.dart';
import '../../widgets/maps/live_tracking_map.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Booking? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookingProvider = context.read<BookingProvider>();
    final booking = await bookingProvider.getBookingById(widget.bookingId);
    if (booking != null) {
      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
      }
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    }

    if (_booking == null) {
      return const Scaffold(body: Center(child: Text('Booking not found')));
    }

    final booking = _booking!;
    final showMap = booking.status == BookingStatus.active;

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
                  _buildWorkerCard(booking),
                  const SizedBox(height: 24),
                  
                  if (showMap) ...[
                    _buildMapSection(booking),
                    const SizedBox(height: 24),
                  ],

                  _buildJobDetails(booking),
                  const SizedBox(height: 24),

                  _buildActionButtons(booking),
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

  Widget _buildActionButtons(Booking booking) {
    final colorScheme = Theme.of(context).colorScheme;

    if (booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.accepted) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _handleCancel(booking),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: colorScheme.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Cancel Request', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    }

    if (booking.status == BookingStatus.active &&
        booking.startedAt != null) {
      // Only the worker can mark a job as complete via the backend.
      // The client sees a read-only status message here.
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Job is in progress. The worker will mark it as completed when done.',
                style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurface),
              ),
            ),
          ],
        ),
      );
    }

    if (booking.status == BookingStatus.completed && !booking.isRated) {
      return SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          label: 'Rate & Review',
          onPressed: () {
            Navigator.pushNamed(context, '${AppRouter.rateReview}/${booking.id}');
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _handleCancel(Booking booking) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
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
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Back')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, reasonController.text.trim()),
            child: Text('Confirm Cancel', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;

    final result = await context.read<BookingProvider>().cancelBooking(bookingId: booking.id, reason: reason);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      setState(() {
        _isLoading = true;
      });
      _loadData();
    }
  }

  Widget _buildWorkerCard(Booking booking) {
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
          CircleAvatar(radius: 24, backgroundImage: NetworkImage(booking.workerPhotoUrl ?? AppConstants.defaultAvatar)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.workerName ?? 'Worker', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final conversationId = await context.read<ChatProvider>().resolveConversationId(
                otherUserId: booking.workerId,
                fallbackBookingId: booking.id,
              );
              if (mounted) {
                Navigator.pushNamed(context, '${AppRouter.chatThread}/$conversationId');
              }
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

  Widget _buildMapSection(Booking booking) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Blue pin: client's registered barangay; Green pin: worker's registered barangay.
    final clientLoc = booking.clientBarangayCoordinates ?? const LatLng(9.9575, 124.3517);
    final workerLoc = booking.barangayCoordinates ?? const LatLng(9.9312, 124.3121);

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
            liveWorkerLocation: (booking.isWorkerTracking ?? false) ? workerLoc : null,
          ),

          // Zoom button
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

          // Read-only status banner
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: (booking.isWorkerTracking ?? false) ? colorScheme.primary : colorScheme.outlineVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    (booking.isWorkerTracking ?? false) ? 'Worker is en route' : 'Waiting for worker to start',
                    style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
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
