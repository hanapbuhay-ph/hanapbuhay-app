import 'package:flutter/material.dart';

import 'dart:async';

import '../data/models/auth_result_model.dart';
import '../data/models/booking_model.dart';
import '../data/repositories/booking_repository.dart';
import '../services/fcm_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository _repository;
  final bool Function()? isAuthenticated;
  final Stream<void> _notificationEvents;
  late final StreamSubscription<void> _notificationSubscription;
  int _pendingCount = 0;
  Future<void>? _pendingCountRefresh;

  BookingProvider(
    this._repository, {
    this.isAuthenticated,
    Stream<void>? notificationEvents,
  }) : _notificationEvents =
           notificationEvents ?? FcmService.onNotificationReceived {
    _notificationSubscription = _notificationEvents.listen((_) {
      unawaited(refreshPendingCount());
    });
  }

  Future<List<Booking>> getBookings({String? status}) async {
    final bookings = await _repository.getBookings(status: status);
    if (status == null || status == 'pending') {
      _publishPendingCount(bookings);
    }
    return bookings;
  }

  final StreamController<int> _pendingCountController =
      StreamController<int>.broadcast();

  int get pendingCount => _pendingCount;

  Stream<int> getPendingCount() => _pendingCountController.stream;

  Future<void> refreshPendingCount() {
    if (isAuthenticated?.call() == false) return Future.value();
    final currentRefresh = _pendingCountRefresh;
    if (currentRefresh != null) return currentRefresh;

    final refresh = _loadPendingCount();
    _pendingCountRefresh = refresh;
    return refresh.whenComplete(() {
      if (identical(_pendingCountRefresh, refresh)) {
        _pendingCountRefresh = null;
      }
    });
  }

  Future<void> _loadPendingCount() async {
    try {
      final bookings = await _repository.getBookings();
      _publishPendingCount(bookings);
    } catch (error, stackTrace) {
      debugPrint(
        '[BookingProvider] Failed to refresh pending booking count: '
        '$error\n$stackTrace',
      );
    }
  }

  void _publishPendingCount(List<Booking> bookings) {
    _pendingCount = bookings
        .where((booking) => booking.status == BookingStatus.pending)
        .length;
    _pendingCountController.add(_pendingCount);
  }

  void _notifyBookingMutation(AuthResult result) {
    notifyListeners();
    if (result.success) unawaited(refreshPendingCount());
  }

  Future<Booking?> getBookingById(String id) => _repository.getBookingById(id);

  Future<AuthResult> createBooking({
    required String workerId,
    required int? serviceCategoryId,
    required DateTime scheduledAt,
    String? notes,
    String? jobPostId,
  }) async {
    final result = await _repository.createBooking(
      workerId: workerId,
      serviceCategoryId: serviceCategoryId,
      scheduledAt: scheduledAt,
      notes: notes,
      jobPostId: jobPostId,
    );
    _notifyBookingMutation(result);
    return result;
  }

  @override
  void dispose() {
    unawaited(_notificationSubscription.cancel());
    _pendingCountController.close();
    super.dispose();
  }

  Future<AuthResult> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    final result = await _repository.cancelBooking(
      bookingId: bookingId,
      reason: reason,
    );
    _notifyBookingMutation(result);
    return result;
  }

  Future<AuthResult> completeBooking({required String bookingId}) async {
    final result = await _repository.completeBooking(bookingId: bookingId);
    notifyListeners();
    return result;
  }

  Future<AuthResult> startTracking({required String bookingId}) async {
    final result = await _repository.startTracking(bookingId: bookingId);
    notifyListeners();
    return result;
  }

  Future<AuthResult> stopTracking({required String bookingId}) async {
    final result = await _repository.stopTracking(bookingId: bookingId);
    notifyListeners();
    return result;
  }

  Future<AuthResult> updateTrackingLocation({
    required String bookingId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    final result = await _repository.updateTrackingLocation(
      bookingId: bookingId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>?> getTrackingStatus(String bookingId) =>
      _repository.getTrackingStatus(bookingId);

  Future<AuthResult> submitReview({
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    final result = await _repository.submitReview(
      bookingId: bookingId,
      rating: rating,
      comment: comment,
    );
    notifyListeners();
    return result;
  }

  Future<AuthResult> submitClientRating({
    required String bookingId,
    required String clientId,
    required int rating,
    String? comment,
  }) async {
    final result = await _repository.submitClientRating(
      bookingId: bookingId,
      clientId: clientId,
      rating: rating,
      comment: comment,
    );
    notifyListeners();
    return result;
  }

  Future<AuthResult> respondToBooking({
    required String bookingId,
    required bool accept,
  }) async {
    final result = await _repository.respondToBooking(
      bookingId: bookingId,
      accept: accept,
    );
    _notifyBookingMutation(result);
    return result;
  }

  /// POST /api/bookings/{id}/accept — Worker accepts a pending booking.
  Future<AuthResult> acceptBooking({required String bookingId}) async {
    final result = await _repository.acceptBooking(bookingId: bookingId);
    _notifyBookingMutation(result);
    return result;
  }

  /// POST /api/bookings/{id}/decline — Worker declines a pending booking.
  Future<AuthResult> declineBooking({required String bookingId}) async {
    final result = await _repository.declineBooking(bookingId: bookingId);
    _notifyBookingMutation(result);
    return result;
  }

  /// POST /api/bookings/{id}/start — Worker marks job as active (started).
  Future<AuthResult> startBooking({required String bookingId}) async {
    final result = await _repository.startBooking(bookingId: bookingId);
    _notifyBookingMutation(result);
    return result;
  }

  Future<AuthResult> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    final result = await _repository.updateBookingStatus(
      bookingId: bookingId,
      status: status,
    );
    _notifyBookingMutation(result);
    return result;
  }

  Future<AuthResult> rescheduleBooking({
    required String bookingId,
    required DateTime scheduledAt,
  }) async {
    final result = await _repository.rescheduleBooking(
      bookingId: bookingId,
      scheduledAt: scheduledAt,
    );
    _notifyBookingMutation(result);
    return result;
  }
}
