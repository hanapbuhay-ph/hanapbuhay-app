import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/booking_provider.dart';
import '../../data/models/booking_model.dart';
import '../../widgets/maps/live_tracking_map.dart';
import '../../services/tracking_service.dart';
import '../../widgets/user_avatar.dart';

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

  bool _isTraveling = false;
  bool _isClientTraveling = false;
  LatLng? _liveWorkerLocation;
  LatLng? _liveClientLocation;

  LatLng _clientBarangayCoords = const LatLng(9.9575, 124.3517);
  LatLng _workerBarangayCoords = const LatLng(9.9312, 124.3121);

  late TrackingService _trackingService;

  @override
  void initState() {
    super.initState();
    _trackingService = TrackingService(
      bookingId: widget.bookingId,
      provider: context.read<BookingProvider>(),
    );
    _trackingService.onOwnLocation = (pos) {
      if (mounted) setState(() => _liveWorkerLocation = pos);
    };
    _trackingService.onOtherLocation = (pos) {
      if (mounted) setState(() => _liveClientLocation = pos);
    };
    _trackingService.onOtherTrackingState = (started) {
      if (mounted) setState(() => _isClientTraveling = started);
    };
    _trackingService.onMessage = (msg, {isError = false}) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ));
    };
    _loadData();
  }

  Future<void> _loadData() async {
    final bookingProvider = context.read<BookingProvider>();
    final booking = await bookingProvider.getBookingById(widget.bookingId);
    final trackingStatus = await bookingProvider.getTrackingStatus(widget.bookingId);

    if (mounted) {
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
      }

      clientCoords ??= booking?.clientBarangayCoordinates;
      workerCoords ??= booking?.barangayCoordinates;

      setState(() {
        _booking = booking;
        _isTraveling = trackingStatus?['is_worker_tracking'] == true;
        _isClientTraveling = trackingStatus?['is_client_tracking'] == true;
        _clientBarangayCoords = clientCoords ?? _clientBarangayCoords;
        _workerBarangayCoords = workerCoords ?? _workerBarangayCoords;
        _liveClientLocation = TrackingService.locationFromStatus(
          trackingStatus?['last_client_location'],
        );
        _liveWorkerLocation = TrackingService.locationFromStatus(
          trackingStatus?['last_worker_location'],
        );
        _isLoading = false;
      });

      await _trackingService.subscribeToOtherParty(myRole: 'worker');
      if (_isTraveling) {
        await _trackingService.resumeTraveling();
      }
    }
  }

  Future<void> _handleOnMyWay() async {
    await _trackingService.startTraveling();
    if (mounted) setState(() => _isTraveling = _trackingService.isTraveling);
  }

  Future<void> _handleArrived() async {
    await _trackingService.arrived();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _trackingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_booking == null) {
      return const Scaffold(body: Center(child: Text('Booking not found')));
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          LiveTrackingMap(
            key: _mapKey,
            clientLocation: _clientBarangayCoords,
            workerLocation: _workerBarangayCoords,
            liveClientLocation: _liveClientLocation,
            liveWorkerLocation: _liveWorkerLocation,
          ),

          // Header
          Positioned(
            top: 0, left: 0, right: 0,
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
                        icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text('Track Location',
                          style: AppTypography.headlineSmall.copyWith(color: colorScheme.onPrimary)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Client-started-traveling banner
          if (_isClientTraveling && !_isTraveling)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_walk, color: colorScheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_booking!.clientName ?? 'Client'} is on their way!',
                        style: AppTypography.labelSmall.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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
              backgroundColor: colorScheme.surfaceContainerHigh,
              child: Icon(Icons.my_location, color: colorScheme.primary),
            ),
          ),

          // Bottom card
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomCard()),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final booking = _booking!;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
          ),
          Row(
            children: [
              UserAvatar(
                name: booking.clientName ?? 'Client',
                radius: 22,
                photoPath: booking.clientPhotoUrl,
                onTap: () => Navigator.pushNamed(
                  context,
                  '${AppRouter.clientProfile}/${booking.clientId}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.clientName ?? 'Client',
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                    Text(
                      '${booking.bookingCode} · ${booking.category}',
                      style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '${AppRouter.chatThread}/${booking.id}'),
                icon: Icon(Icons.chat_bubble_outline, color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tracking status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isTraveling
                  ? colorScheme.primary.withValues(alpha: 0.08)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isTraveling) ...[
                  _PulsingDot(color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Sharing your location',
                      style: AppTypography.labelSmall.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700)),
                ] else ...[
                  Icon(Icons.location_off_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text("Client can't see you yet",
                      style: AppTypography.labelSmall.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isTraveling ? _handleArrived : _handleOnMyWay,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _isTraveling ? "I've Arrived ✓" : "I'm on my way",
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
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _animation.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
