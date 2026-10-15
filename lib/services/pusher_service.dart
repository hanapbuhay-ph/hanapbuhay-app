import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../core/constants/app_constants.dart';
import 'secure_storage_service.dart';

class LocationEvent {
  final String role;
  final double latitude;
  final double longitude;

  const LocationEvent({
    required this.role,
    required this.latitude,
    required this.longitude,
  });
}

class TrackingStateEvent {
  final String role;
  final bool started;

  const TrackingStateEvent({required this.role, required this.started});
}

class NewMessageEvent {
  final int bookingId;
  final int senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;

  const NewMessageEvent({
    required this.bookingId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });
}

/// Shares authenticated Ably Pusher-channel subscriptions across tracking and chat.
class PusherService {
  PusherService._();
  static final PusherService instance = PusherService._();

  final _pusher = PusherChannelsFlutter.getInstance();
  final Map<String, int> _bookingSubscriptionCounts = {};
  bool _initialized = false;

  void Function(LocationEvent)? onLocation;
  void Function(TrackingStateEvent)? onTrackingState;
  void Function(NewMessageEvent)? onNewMessage;

  Future<void> init() async {
    if (_initialized) return;
    if (AppConstants.pusherKey.isEmpty) {
      throw StateError(
        'Missing ABLY_PUSHER_KEY. Pass the Ably key name using --dart-define.',
      );
    }

    final storage = SecureStorageService();
    await _pusher.init(
      apiKey: AppConstants.pusherKey,
      cluster: AppConstants.pusherCluster,
      useTLS: true,
      wsHost: AppConstants.pusherHost,
      onAuthorizer: (channelName, socketId, options) async {
        final token = await storage.getToken();
        if (token == null || token.isEmpty) {
          throw StateError('Sign in is required to subscribe to booking updates.');
        }

        final response = await http.post(
          Uri.parse(
            '${AppConstants.apiBaseUrl.replaceAll('/api', '')}/broadcasting/auth',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: 'socket_id=$socketId&channel_name=$channelName',
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw StateError(
            'Booking channel authorization failed (${response.statusCode}).',
          );
        }
        return jsonDecode(response.body);
      },
    );

    _initialized = true;
    await _pusher.connect();
  }

  Future<void> subscribe(String bookingId) async {
    await init();
    final currentCount = _bookingSubscriptionCounts[bookingId] ?? 0;
    _bookingSubscriptionCounts[bookingId] = currentCount + 1;
    if (currentCount > 0) return;

    try {
      await _pusher.subscribe(
        channelName: 'private-booking.$bookingId',
        onEvent: (event) {
          final data = _decodeEventData(event.data);
          if (data == null) return;

          final name = event.eventName;
          if (_matchesEvent(name, 'LocationUpdated')) {
            final latitude = data['latitude'];
            final longitude = data['longitude'];
            if (latitude is! num || longitude is! num) {
              debugPrint('[PusherService] LocationUpdated has invalid coordinates.');
              return;
            }
            onLocation?.call(LocationEvent(
              role: data['role']?.toString() ?? '',
              latitude: latitude.toDouble(),
              longitude: longitude.toDouble(),
            ));
          } else if (_matchesEvent(name, 'LocationTrackingStarted')) {
            onTrackingState?.call(TrackingStateEvent(
              role: data['role']?.toString() ?? '',
              started: true,
            ));
          } else if (_matchesEvent(name, 'LocationTrackingStopped')) {
            onTrackingState?.call(TrackingStateEvent(
              role: data['role']?.toString() ?? '',
              started: false,
            ));
          } else if (_matchesEvent(name, 'NewMessage')) {
            final bookingIdValue = data['booking_id'];
            final sender = data['sender'];
            final senderId = sender is Map ? sender['id'] : null;
            final createdAt = DateTime.tryParse(
              data['created_at']?.toString() ?? '',
            );
            if (bookingIdValue is! num || senderId is! num || createdAt == null) {
              debugPrint('[PusherService] NewMessage has an invalid payload.');
              return;
            }
            onNewMessage?.call(NewMessageEvent(
              bookingId: bookingIdValue.toInt(),
              senderId: senderId.toInt(),
              senderName: sender is Map ? sender['name']?.toString() ?? '' : '',
              message: data['message']?.toString() ?? '',
              createdAt: createdAt,
            ));
          }
        },
      );
    } catch (_) {
      _bookingSubscriptionCounts.remove(bookingId);
      rethrow;
    }
  }

  Future<void> unsubscribe(String bookingId) async {
    final currentCount = _bookingSubscriptionCounts[bookingId] ?? 0;
    if (currentCount > 1) {
      _bookingSubscriptionCounts[bookingId] = currentCount - 1;
      return;
    }
    _bookingSubscriptionCounts.remove(bookingId);
    if (currentCount == 0) return;
    await _pusher.unsubscribe(channelName: 'private-booking.$bookingId');
  }

  Map<String, dynamic>? _decodeEventData(dynamic data) {
    try {
      final decoded = data is String ? jsonDecode(data) : data;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } on FormatException catch (error) {
      debugPrint('[PusherService] Unable to decode event payload: $error');
    }
    return null;
  }

  bool _matchesEvent(String eventName, String eventClass) {
    return eventName == 'App\\Events\\$eventClass' ||
        eventName == 'App.Events.$eventClass';
  }
}
