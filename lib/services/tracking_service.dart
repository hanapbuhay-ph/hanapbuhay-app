import 'dart:async';
import 'package:flutter/material.dart';
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

  StreamSubscription<Position>? _positionSub;
  static const _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0, // TODO: restore to 10 before production
  );

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

    // Stream own GPS → send to API every emission (distanceFilter handles throttle)
    _positionSub = Geolocator.getPositionStream(locationSettings: _locationSettings)
        .listen((pos) {
      onOwnLocation?.call(LatLng(pos.latitude, pos.longitude));
      provider.updateTrackingLocation(
        bookingId: bookingId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
      );
    });

    onMessage?.call('Sharing your location.');
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
