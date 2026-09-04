import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/booking_provider.dart';
import '../../providers/worker_provider.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/worker_model.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/maps/live_tracking_map.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String bookingId;

  const LiveTrackingScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final GlobalKey<LiveTrackingMapState> _mapKey = GlobalKey<LiveTrackingMapState>();
  Booking? _booking;
  Worker? _worker;
  bool _isLoading = true;
  bool _isTracking = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final booking = await context.read<BookingProvider>().getBookingById(widget.bookingId);
    if (booking != null) {
      final worker = await context.read<WorkerProvider>().getWorkerById(booking.workerId);
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_booking == null || _worker == null) {
      return const Scaffold(body: Center(child: Text('Booking not found')));
    }

    final booking = _booking!;
    final worker = _worker!;
    final colorScheme = Theme.of(context).colorScheme;
    const clientLoc = LatLng(9.9575, 124.3517);
    final workerLoc = worker.barangayCoordinates ?? const LatLng(9.9312, 124.3121);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Map
          LiveTrackingMap(
            key: _mapKey,
            clientLocation: clientLoc,
            workerLocation: workerLoc,
            isTracking: _isTracking,
            onArrival: () => setState(() => _isTracking = false),
          ),

          // 2. Custom Header (Overlay)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colorScheme.shadow.withValues(alpha: 0.2), Colors.transparent],
                ),
              ),
              child: const AppHeader(
                title: 'Live Tracking',
                backgroundColor: Colors.transparent,
              ),
            ),
          ),

          // 3. Floating Action Buttons
          Positioned(
            right: 16,
            bottom: 240, // Above bottom card
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'center_map',
                  onPressed: () {
                    _mapKey.currentState?.centerMap();
                  },
                  backgroundColor: colorScheme.surface,
                  child: Icon(Icons.my_location, color: colorScheme.primary),
                ),
              ],
            ),
          ),

          // 4. Bottom Info Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCard(worker),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(Worker worker) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 32, backgroundImage: NetworkImage(worker.avatarUrl)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(worker.name, style: AppTypography.headlineMedium.copyWith(fontSize: 20)),
                        const SizedBox(width: 6),
                        if (worker.isVerified)
                          Icon(Icons.verified, color: Theme.of(context).colorScheme.primary, size: 18),
                      ],
                    ),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text('En Route', style: AppTypography.labelLarge.copyWith(color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              _buildIconButton(Icons.chat_bubble_outline, () {
                Navigator.pushNamed(context, '${AppRouter.chatThread}/c1'); // Mock ID
              }),
              const SizedBox(width: 12),
              _buildIconButton(Icons.call_outlined, () {}),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('ETA', '10 mins'),
              _buildMetric('Distance', worker.distance),
              _buildMetric('Price', '₱${worker.hourlyRate.toInt()}/hr'),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Text('View Booking Details', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: colorScheme.primary),
        onPressed: onTap,
      ),
    );
  }
}
