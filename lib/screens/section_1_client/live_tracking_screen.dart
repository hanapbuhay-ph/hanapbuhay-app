import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/booking_provider.dart';
import '../../data/models/booking_model.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/maps/live_tracking_map.dart';
import '../../core/constants/app_constants.dart';

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
  bool _isLoading = true;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookingProvider = context.read<BookingProvider>();
    final booking = await bookingProvider.getBookingById(widget.bookingId);
    if (booking != null) {
      // Load REST tracking status (B3.5)
      final tracking = await bookingProvider.getTrackingStatus(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _isTracking = tracking?['is_worker_tracking'] == true || tracking?['is_client_tracking'] == true;
          _isLoading = false;
        });
      }
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleToggleTracking() async {
    final bookingProvider = context.read<BookingProvider>();
    if (_isTracking) {
      final result = await bookingProvider.stopTracking(bookingId: widget.bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
        if (result.success) setState(() => _isTracking = false);
      }
    } else {
      final result = await bookingProvider.startTracking(bookingId: widget.bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
        if (result.success) setState(() => _isTracking = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_booking == null) {
      return const Scaffold(body: Center(child: Text('Booking not found')));
    }

    final booking = _booking!;
    final colorScheme = Theme.of(context).colorScheme;
    final workerLoc = booking.barangayCoordinates ?? const LatLng(9.9312, 124.3121);
    final clientLoc = booking.clientBarangayCoordinates ?? const LatLng(9.9575, 124.3517);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Map (static barangay pins per B3.5)
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
            child: _buildBottomCard(booking),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(Booking booking) {
    final theme = Theme.of(context);
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
              CircleAvatar(radius: 32, backgroundImage: NetworkImage(booking.workerPhotoUrl ?? AppConstants.defaultAvatar)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(booking.workerName ?? 'Worker', style: AppTypography.headlineMedium.copyWith(fontSize: 20)),
                        const SizedBox(width: 6),
                        Icon(Icons.verified, color: Theme.of(context).colorScheme.primary, size: 18),
                      ],
                    ),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(_isTracking ? 'En Route' : 'Booking Confirmed', style: AppTypography.labelLarge.copyWith(color: Theme.of(context).colorScheme.primary)),
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
              _buildMetric('Service', booking.category),
              _buildMetric('Scheduled', booking.time),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text('Details', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _handleToggleTracking,
                    style: FilledButton.styleFrom(
                      backgroundColor: _isTracking ? theme.colorScheme.errorContainer : theme.colorScheme.primary,
                      foregroundColor: _isTracking ? theme.colorScheme.error : theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
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
