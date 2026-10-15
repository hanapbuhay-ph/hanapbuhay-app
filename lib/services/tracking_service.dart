import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/booking_provider.dart';
import 'pusher_service.dart';

/// Manages the full live-tracking lifecycle for one party (client or worker).
///
/// Usage:
///   final svc = TrackingService(bookingId: id, provider: bookingProvider);
///   svc.onOwnLocation = (pos) { ... };
///   svc.onOtherLocation = (pos) { ... };
///   svc.onOtherTrackingState = (started) { ... };
///   await svc.startTraveling();
///   ...
///   await svc.arrived();   // stops tracking + pops screen
///   svc.dispose();         // always call in State.dispose()
class TrackingService {
  final String bookingId;
  final BookingProvider provider;

  TrackingService({required this.bookingId, required this.provider});

  // Callbacks — set these before calling startTraveling()
  void Function(LatLng)? onOwnLocation;
  void Function(LatLng)? onOtherLocation;
  void Function(bool started)? onOtherTrackingState;
  void Function(String message, {bool isError})? onMessage;

  bool _isTraveling = false;
  bool get isTraveling => _isTraveling;
  bool _locationUpdateErrorReported = false;

  StreamSubscription<Position>? _positionSub;
  static const _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );

  static LatLng? locationFromStatus(dynamic value) {
    if (value is! Map) return null;
    final latitude = double.tryParse(value['latitude']?.toString() ?? '');
    final longitude = double.tryParse(value['longitude']?.toString() ?? '');
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }

  /// Request GPS permission. Returns true if granted.
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Start traveling: request GPS → call API → begin streaming location.
  Future<void> startTraveling() async {
    if (_isTraveling) return;

    final granted = await requestPermission();
    if (!granted) {
      onMessage?.call('Location permission is required to share your location.', isError: true);
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      onMessage?.call('Please turn on GPS to share your location.', isError: true);
      return;
    }

    final result = await provider.startTracking(bookingId: bookingId);
    if (!result.success) {
      onMessage?.call(result.message, isError: true);
      return;
    }

    _isTraveling = true;
    _locationUpdateErrorReported = false;

    _startLocationUpdates();
    onMessage?.call('Sharing your location.');
  }

  /// Resume GPS updates when reopening a screen for an already-active trip.
  Future<void> resumeTraveling() async {
    if (_isTraveling) return;

    final granted = await requestPermission();
    if (!granted) {
      onMessage?.call('Location permission is required to share your location.', isError: true);
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      onMessage?.call('Please turn on GPS to share your location.', isError: true);
      return;
    }

    _isTraveling = true;
    _locationUpdateErrorReported = false;
    _startLocationUpdates();
    onMessage?.call('Resuming location sharing.');
  }

  void _startLocationUpdates() {
    _positionSub = Geolocator.getPositionStream(locationSettings: _locationSettings)
        .listen(
          (position) => unawaited(_publishPosition(position)),
          onError: (Object error) {
            onMessage?.call('Unable to read GPS location: $error', isError: true);
          },
        );
    unawaited(_publishCurrentPosition());
  }

  Future<void> _publishCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );
      await _publishPosition(position);
    } catch (error) {
      onMessage?.call('Unable to get your current GPS location: $error', isError: true);
    }
  }

  Future<void> _publishPosition(Position position) async {
    if (!_isTraveling) return;

    onOwnLocation?.call(LatLng(position.latitude, position.longitude));
    try {
      final result = await provider.updateTrackingLocation(
        bookingId: bookingId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
      if (!result.success && !_locationUpdateErrorReported) {
        _locationUpdateErrorReported = true;
        onMessage?.call('Location update failed: ${result.message}', isError: true);
      } else if (result.success) {
        _locationUpdateErrorReported = false;
      }
    } catch (error) {
      if (!_locationUpdateErrorReported) {
        _locationUpdateErrorReported = true;
        onMessage?.call('Location update failed: $error', isError: true);
      }
    }
  }

  /// Stop traveling: cancel GPS stream → call stop API.
  Future<void> arrived() async {
    await _stopInternal(callApi: true);
  }

  /// Subscribe to Pusher to receive the other party's live location.
  /// [myRole] must be 'client' or 'worker' — events from own role are ignored.
  Future<void> subscribeToOtherParty({required String myRole}) async {
    final pusher = PusherService.instance;

    pusher.onLocation = (event) {
      if (event.role == myRole) return; // ignore own GPS echoes
      onOtherLocation?.call(LatLng(event.latitude, event.longitude));
    };

    pusher.onTrackingState = (event) {
      if (event.role == myRole) return; // ignore own start/stop echoes
      onOtherTrackingState?.call(event.started);
    };

    await pusher.subscribe(bookingId);
  }

  Future<void> _stopInternal({required bool callApi}) async {
    _positionSub?.cancel();
    _positionSub = null;
    _isTraveling = false;

    if (callApi) {
      final result = await provider.stopTracking(bookingId: bookingId);
      if (!result.success) {
        onMessage?.call(result.message, isError: true);
      }
    }
  }

  void dispose() {
    _positionSub?.cancel();
    PusherService.instance.unsubscribe(bookingId);
    PusherService.instance.onLocation = null;
    PusherService.instance.onTrackingState = null;
  }
}
