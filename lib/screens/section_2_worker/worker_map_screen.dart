import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/booking_provider.dart';
import '../../data/models/booking_model.dart';
import '../../widgets/maps/live_tracking_map.dart';

/// W9: Worker Map Screen
/// Route: /worker-map/{bookingId}
/// Worker-perspective: green pin = worker (own), blue pin = client
class WorkerMapScreen extends StatefulWidget {
  final String bookingId;

  const WorkerMapScreen({super.key, required this.bookingId});

  @override
  State<WorkerMapScreen> createState() => _WorkerMapScreenState();
}

class _WorkerMapScreenState extends State<WorkerMapScreen> {
  final GlobalKey<LiveTrackingMapState> _mapKey = GlobalKey<LiveTrackingMapState>();
  Booking? _booking;
  bool _isLoading = true;
  bool _isTracking = false;
  // Coordinates loaded from GET /api/bookings/{id}/tracking
  LatLng? _clientBarangayCoords;
  LatLng? _workerBarangayCoords;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookingProvider = context.read<BookingProvider>();

    final booking = await bookingProvider.getBookingById(widget.bookingId);

    // GET /api/bookings/{id}/tracking — returns barangay coords + tracking flags.
    // Note: current location is WebSocket-only; REST only provides barangay center coords.
    final trackingStatus = await bookingProvider.getTrackingStatus(widget.bookingId);

    if (mounted) {
      // Parse client barangay coords from tracking status response
      LatLng? clientCoords;
      LatLng? workerCoords;
      if (trackingStatus != null) {
        final cb = trackingStatus['client_barangay'] as Map<String, dynamic>?;
        final wb = trackingStatus['worker_barangay'] as Map<String, dynamic>?;
        if (cb != null) {
          final lat = double.tryParse(cb['latitude']?.toString() ?? '');
          final lng = double.tryParse(cb['longitude']?.toString() ?? '');
          if (lat != null && lng != null) clientCoords = LatLng(lat, lng);
        }
        if (wb != null) {
          final lat = double.tryParse(wb['latitude']?.toString() ?? '');
          final lng = double.tryParse(wb['longitude']?.toString() ?? '');
          if (lat != null && lng != null) workerCoords = LatLng(lat, lng);
        }
        // Sync local tracking state with backend flag
        _isTracking = trackingStatus['is_worker_tracking'] == true;
      }

      // Fall back to booking's own barangay coords if tracking status unavailable
      if (clientCoords == null && booking != null) {
        clientCoords = booking.clientBarangayCoordinates;
      }
      // Worker coords: prefer tracking API, then auth provider's barangay from GET /api/user
      // (AuthProvider does not store barangay coordinates, so we use the booking's worker barangay)
      if (workerCoords == null && booking != null) {
        workerCoords = booking.barangayCoordinates; // worker barangay from booking response
      }

      setState(() {
        _booking = booking;
        _clientBarangayCoords = clientCoords ?? const LatLng(9.9575, 124.3517);
        _workerBarangayCoords = workerCoords ?? const LatLng(9.9312, 124.3121);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleOnMyWay() async {
    final colorScheme = Theme.of(context).colorScheme;
    // POST /api/bookings/{id}/tracking/start — only works when booking status = active
    final result = await context.read<BookingProvider>().startTracking(bookingId: widget.bookingId);
    if (!mounted) return;
    if (result.success) {
      setState(() => _isTracking = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Sharing your location with the client'), backgroundColor: colorScheme.primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: colorScheme.error),
      );
    }
  }

  Future<void> _handleArrived() async {
    final colorScheme = Theme.of(context).colorScheme;
    // POST /api/bookings/{id}/tracking/stop
    final result = await context.read<BookingProvider>().stopTracking(bookingId: widget.bookingId);
    if (!mounted) return;
    if (result.success) {
      setState(() => _isTracking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Tracking stopped'), backgroundColor: colorScheme.primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: colorScheme.error),
      );
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

    // Worker's barangay = green pin (own), client's barangay = blue pin.
    // Note: these are barangay center coordinates, not live GPS — WebSocket only for live.
    final workerLoc = _workerBarangayCoords ?? const LatLng(9.9312, 124.3121);
    final clientLoc = _clientBarangayCoords ?? const LatLng(9.9575, 124.3517);

    return Scaffold(
      body: Stack(
        children: [
          // Full screen map — worker pin is green (own), client pin is blue
          LiveTrackingMap(
            key: _mapKey,
            clientLocation: clientLoc,
            workerLocation: workerLoc,
            isTracking: _isTracking,
            onArrival: () {},
          ),

          // Header overlay
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
                  colors: [Colors.black.withValues(alpha: 0.25), Colors.transparent],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Track Location',
                        style: AppTypography.headlineSmall.copyWith(color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Center map FAB
          Positioned(
            right: 16,
            bottom: 260,
            child: FloatingActionButton(
              heroTag: 'worker_center_map',
              mini: true,
              onPressed: () => _mapKey.currentState?.centerMap(),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
            ),
          ),

          // Bottom card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final booking = _booking!;

    // Use real client data from booking response (Fix 4 — getPhotoUrl for all photo URLs)
    final clientName = booking.clientName ?? 'Client';
    final clientPhoto = AppConstants.getPhotoUrl(booking.clientPhotoUrl);

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(clientPhoto),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                    Text(
                      '${booking.bookingCode} · ${booking.category}',
                      style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              // Chat uses booking.id as conversation ID (matches /api/messages/{bookingId})
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '${AppRouter.chatThread}/${booking.id}'),
                icon: Icon(Icons.chat_bubble_outline, color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isTracking
                  ? colorScheme.primary.withValues(alpha: 0.08)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isTracking) ...[
                  _PulsingDot(color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Sharing your location',
                    style: AppTypography.labelSmall.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
                  ),
                ] else ...[
                  Icon(Icons.location_off_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    "Client can't see you yet",
                    style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isTracking ? _handleArrived : _handleOnMyWay,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _isTracking ? "I've Arrived ✓" : "I'm on my way",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _animation.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
