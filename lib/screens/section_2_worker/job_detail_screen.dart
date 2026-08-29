import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../services/service_locator.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/worker_model.dart';
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
    final booking = await bookingRepository.getBookingById(widget.bookingId);
    if (booking != null) {
      final worker = await workerRepository.getWorkerById(booking.workerId);
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
    // In a real app, we'd call an API. For mock, we'll update the local state.
    // Tapping 'Start Traveling' -> status becomes active (En Route)
    // Tapping 'I've Arrived' -> status stays active but we stop simulation, or moves to inProgress
    
    // For this mock flow:
    // Accepted -> tapping button -> status: active (En Route)
    // Active -> tapping button -> status: inProgress
    // In Progress -> tapping button -> status: completed

    setState(() => _isLoading = true);
    // TODO: POST /api/bookings/{id}/respond or /api/bookings/{id}/status
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      // Logic to move to next status based on current
      BookingStatus next;
      switch (_booking!.status) {
        case BookingStatus.upcoming: next = BookingStatus.active; break;
        case BookingStatus.active: next = BookingStatus.completed; break; // Simple jump for now
        default: next = _booking!.status;
      }
      
      // Update repository mock state if needed, or just refresh
      // Since our mock repository currently doesn't persist status changes across navigations 
      // without a proper state management solution (which we have in Provider, but repository is the source here)
      // we'll just simulate the local UI update.
      
      await _loadData(); // Refresh from repository
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (_booking == null || _worker == null) {
      return const Scaffold(body: Center(child: Text('Job not found')));
    }

    final booking = _booking!;
    final worker = _worker!;
    final showMap = booking.status == BookingStatus.active;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppHeader(title: 'Job Details'),
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
                      onPressed: () => context.push('${AppRouter.fileReport}/${booking.id}'),
                      icon: const Icon(Icons.report_problem_outlined, size: 16, color: AppColors.error),
                      label: const Text(
                        'File a Report',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24, 
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=client123'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Maria Santos', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800)),
                Text('Client', style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.push('${AppRouter.chatThread}/c1'); // Mock ID
            },
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(Booking booking, Worker worker) {
    const clientLoc = LatLng(9.9575, 124.3517);
    final workerLoc = worker.barangayCoordinates ?? const LatLng(9.9312, 124.3121);

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHigh),
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
              onPressed: () => context.push('${AppRouter.bookingDetail}/${booking.id}/tracking'),
              backgroundColor: Colors.white,
              child: const Icon(Icons.fullscreen, color: AppColors.onSurfaceVariant),
            ),
          ),

          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
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
                          style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _isTracking ? 'Estimated arrival: 10 mins' : 'Please proceed with the service',
                          style: AppTypography.bodySmall.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  if (_isTracking)
                    ElevatedButton(
                      onPressed: () => setState(() => _isTracking = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('I\'ve Arrived', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking Details', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.build_outlined, 'Service Type', booking.category),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.calendar_today_outlined, 'Date & Time', '${_formatDate(booking.date)} • ${booking.time}'),
          const SizedBox(height: 16),
          _buildLocationRow(booking),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Text('Notes', style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(booking.notes, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 10)),
            Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationRow(Booking booking) {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location', style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 10)),
              Text('Trinidad (${booking.barangay})', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            // Toggles map section visibility by changing status to active if it was upcoming
            if (_booking!.status == BookingStatus.upcoming) {
              _updateStatus(BookingStatus.active);
            }
          },
          child: const Text('View on Map', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildTimeline(Booking booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Job Status', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
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
                        color: step.isCompleted ? AppColors.primary : AppColors.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: step.isCompleted ? null : Border.all(color: AppColors.outlineVariant),
                      ),
                      child: step.isCompleted 
                        ? const Icon(Icons.check, size: 12, color: Colors.white) 
                        : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: step.isCompleted ? AppColors.primary : AppColors.surfaceContainerHighest,
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
                            color: step.isCompleted ? AppColors.onSurface : AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (step.timestamp != null)
                          Text(
                            '${step.timestamp!.hour}:${step.timestamp!.minute.toString().padLeft(2, '0')}',
                            style: AppTypography.bodySmall.copyWith(fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildConditionalAction(Booking booking) {
    if (booking.status == BookingStatus.upcoming) {
      return PrimaryButton(
        label: 'Start Traveling',
        onPressed: () => _updateStatus(BookingStatus.active),
      );
    }
    
    // Status In Progress logic (not explicitly in enum yet but simulated)
    // For now, if active and NOT tracking (meaning arrived), show complete
    if (booking.status == BookingStatus.active && !_isTracking) {
      return PrimaryButton(
        label: 'Mark as Completed',
        onPressed: () => _updateStatus(BookingStatus.completed),
      );
    }

    return const SizedBox.shrink();
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
