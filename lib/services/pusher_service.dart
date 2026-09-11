import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import 'secure_storage_service.dart';

/// Wraps a single decoded LocationUpdated broadcast payload.
class LocationEvent {
  final String role; // 'worker' | 'client'
  final double latitude;
  final double longitude;

  const LocationEvent({required this.role, required this.latitude, required this.longitude});
}

/// Wraps a tracking-started/stopped broadcast payload.
class TrackingStateEvent {
  final String role;
  final bool started; // true = started, false = stopped

  const TrackingStateEvent({required this.role, required this.started});
}

/// Singleton that manages the Pusher/Soketi connection.
/// Call [subscribe] when entering a tracking screen and [unsubscribe] on dispose.
class PusherService {
  PusherService._();
  static final PusherService instance = PusherService._();

  final _pusher = PusherChannelsFlutter.getInstance();
  bool _initialized = false;

  void Function(LocationEvent)? onLocation;
  void Function(TrackingStateEvent)? onTrackingState;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final storage = SecureStorageService();

    await _pusher.init(
      apiKey: AppConstants.pusherKey,
      cluster: AppConstants.pusherCluster,
      useTLS: false,
      onAuthorizer: (channelName, socketId, options) async {
        // Authenticate private channels using the stored Sanctum Bearer token.
        // Soketi validates this against Laravel's /broadcasting/auth endpoint.
        final token = await storage.getToken();
        final response = await http.post(
          Uri.parse('${AppConstants.apiBaseUrl}/broadcasting/auth'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: 'socket_id=$socketId&channel_name=$channelName',
        );
        return jsonDecode(response.body);
      },
    );

    await _pusher.connect();
  }

  Future<void> subscribe(String bookingId) async {
    await init();

    await _pusher.subscribe(
      channelName: 'private-booking.$bookingId',
      onEvent: (event) {
        final data = event.data is String
            ? jsonDecode(event.data as String) as Map<String, dynamic>
            : event.data as Map<String, dynamic>;

        if (event.eventName == 'App\\Events\\LocationUpdated') {
          onLocation?.call(LocationEvent(
            role: data['role'] as String,
            latitude: (data['latitude'] as num).toDouble(),
            longitude: (data['longitude'] as num).toDouble(),
          ));
        } else if (event.eventName == 'App\\Events\\LocationTrackingStarted') {
          onTrackingState?.call(TrackingStateEvent(
            role: data['role'] as String,
            started: true,
          ));
        } else if (event.eventName == 'App\\Events\\LocationTrackingStopped') {
          onTrackingState?.call(TrackingStateEvent(
            role: data['role'] as String,
            started: false,
          ));
        }
      },
    );
  }

  Future<void> unsubscribe(String bookingId) async {
    await _pusher.unsubscribe(channelName: 'private-booking.$bookingId');
  }
}
