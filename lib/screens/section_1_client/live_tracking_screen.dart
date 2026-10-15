import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/booking_provider.dart';
import '../../data/models/booking_model.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/maps/live_tracking_map.dart';
import '../../services/tracking_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String bookingId;

  const LiveTrackingScreen({super.key, required this.bookingId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final GlobalKey<LiveTrackingMapState> _mapKey = GlobalKey<LiveTrackingMapState>();

  Booking? _booking;
  bool _isLoading = true;

  // Tracking state
  bool _isTraveling = false;
  bool _isWorkerTraveling = false;
  LatLng? _liveClientLocation;
  LatLng? _liveWorkerLocation;

  late TrackingService _trackingService;

  @override
  void initState() {
    super.initState();
    _trackingService = TrackingService(
      bookingId: widget.bookingId,
      provider: context.read<BookingProvider>(),
    );
    _trackingService.onOwnLocation = (pos) {
      if (mounted) setState(() => _liveClientLocation = pos);
    };
    _trackingService.onOtherLocation = (pos) {
      if (mounted) setState(() => _liveWorkerLocation = pos);
    };
    _trackingService.onOtherTrackingState = (started) {
      if (mounted) setState(() => _isWorkerTraveling = started);
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
    final tracking = await bookingProvider.getTrackingStatus(widget.bookingId);

    if (mounted) {
      setState(() {
        _booking = booking;
        _isWorkerTraveling = tracking?['is_worker_tracking'] == true;
        _isTraveling = tracking?['is_client_tracking'] == true;
        _liveClientLocation = TrackingService.locationFromStatus(
          tracking?['last_client_location'],
        );
        _liveWorkerLocation = TrackingService.locationFromStatus(
          tracking?['last_worker_location'],
        );
        _isLoading = false;
      });
      // Subscribe to the other party and resume this user's GPS if tracking
      // was already active when the screen was opened.
      await _trackingService.subscribeToOtherParty(myRole: 'client');
      if (_isTraveling) {
        await _trackingService.resumeTraveling();
      }
    }
  }

  Future<void> _handleStartTraveling() async {
    await _trackingService.startTraveling();
    if (mounted) setState(() => _isTraveling = _trackingService.isTraveling);
  }

  Future<void> _handleArrived() async {
    await _trackingService.arrived();
    if (mounted) {
      setState(() => _isTraveling = false);
      Navigator.pop(context);
    }
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

    final booking = _booking!;
    final colorScheme = Theme.of(context).colorScheme;
    final workerLoc = booking.barangayCoordinates ?? const LatLng(9.9312, 124.3121);
    final clientLoc = booking.clientBarangayCoordinates ?? const LatLng(9.9575, 124.3517);

    return Scaffold(
      body: Stack(
        children: [
          LiveTrackingMap(
            key: _mapKey,
            clientLocation: clientLoc,
            workerLocation: workerLoc,
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
                  colors: [colorScheme.shadow.withValues(alpha: 0.2), Colors.transparent],
                ),
              ),
              child: const AppHeader(title: 'Live Tracking', backgroundColor: Colors.transparent),
            ),
          ),

          // Worker-started-traveling banner
          if (_isWorkerTraveling && !_isTraveling)
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
                        '${booking.workerName ?? 'Worker'} is on their way!',
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
            bottom: 240,
            child: FloatingActionButton(
              heroTag: 'center_map',
              onPressed: () => _mapKey.currentState?.centerMap(),
              backgroundColor: colorScheme.surface,
              child: Icon(Icons.my_location, color: colorScheme.primary),
            ),
          ),

          // Bottom card
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomCard(booking),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(Booking booking) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(
                  AppConstants.getPhotoUrl(booking.workerPhotoUrl),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(booking.workerName ?? 'Worker',
                            style: AppTypography.headlineMedium.copyWith(fontSize: 20)),
                        const SizedBox(width: 6),
                        Icon(Icons.verified, color: colorScheme.primary, size: 18),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: _isWorkerTraveling ? colorScheme.primary : colorScheme.outlineVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isWorkerTraveling ? 'Worker En Route' : 'Waiting for Worker',
                          style: AppTypography.labelLarge.copyWith(
                            color: _isWorkerTraveling ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildIconButton(Icons.chat_bubble_outline, () {
                Navigator.pushNamed(context, '${AppRouter.chatThread}/${booking.id}');
              }),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Service', booking.category),
              _buildMetric('Scheduled', booking.time),
              _buildMetric('Status', _isTraveling ? 'Traveling' : 'Waiting'),
            ],
          ),
          const SizedBox(height: 24),
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
                    child: Text('Details',
                        style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isTraveling ? _handleArrived : _handleStartTraveling,
                    style: FilledButton.styleFrom(
                      backgroundColor: _isTraveling ? colorScheme.errorContainer : colorScheme.primary,
                      foregroundColor: _isTraveling ? colorScheme.error : colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _isTraveling ? "I've Arrived" : 'Start Traveling',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
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
      child: IconButton(icon: Icon(icon, color: colorScheme.primary), onPressed: onTap),
    );
  }
}
