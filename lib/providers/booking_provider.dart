import 'package:flutter/material.dart';
import '../data/repositories/booking_repository.dart';
import '../data/models/booking_model.dart';
import '../data/models/auth_result_model.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository _repository;

  BookingProvider(this._repository);

  Future<List<Booking>> getBookings() => _repository.getBookings();
  Future<Booking?> getBookingById(String id) => _repository.getBookingById(id);
  
  Future<AuthResult> createBooking({
    required String workerId,
    required String category,
    required DateTime date,
    required String time,
    required String notes,
    required String barangay,
  }) async {
    final result = await _repository.createBooking(
      workerId: workerId,
      category: category,
      date: date,
      time: time,
      notes: notes,
      barangay: barangay,
    );
    notifyListeners();
    return result;
  }

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
