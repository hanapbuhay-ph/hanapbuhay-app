import 'package:flutter/material.dart';
import '../data/repositories/booking_repository.dart';
import '../data/models/booking_model.dart';
import '../data/models/auth_result_model.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository _repository;

  BookingProvider(this._repository);

  Future<List<Booking>> getBookings({String? status}) => _repository.getBookings(status: status);
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
    notifyListeners();
    return result;
  }

  Future<AuthResult> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    final result = await _repository.cancelBooking(bookingId: bookingId, reason: reason);
    notifyListeners();
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
    required String workerId,
    required int rating,
    required String comment,
  }) async {
    final result = await _repository.submitReview(
      bookingId: bookingId,
      workerId: workerId,
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
    final result = await _repository.respondToBooking(bookingId: bookingId, accept: accept);
    notifyListeners();
    return result;
  }

  Future<AuthResult> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    final result = await _repository.updateBookingStatus(bookingId: bookingId, status: status);
    notifyListeners();
    return result;
  }
}
