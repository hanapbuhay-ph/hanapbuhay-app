import '../models/booking_model.dart';
import '../models/auth_result_model.dart';

abstract class BookingRepository {
  Future<List<Booking>> getBookings({String? status});
  Future<Booking?> getBookingById(String id);
  
  Future<AuthResult> createBooking({
    required String workerId,
    required int? serviceCategoryId,
    required DateTime scheduledAt,
    String? notes,
    String? jobPostId,
  });

  Future<AuthResult> cancelBooking({
    required String bookingId,
    String? reason,
  });

  Future<AuthResult> completeBooking({required String bookingId});

  Future<AuthResult> startTracking({required String bookingId});

  Future<AuthResult> stopTracking({required String bookingId});

  Future<AuthResult> updateTrackingLocation({
    required String bookingId,
    required double latitude,
    required double longitude,
    double? accuracy,
  });

  Future<Map<String, dynamic>?> getTrackingStatus(String bookingId);

  Future<AuthResult> submitReview({
    required String bookingId,
    required String workerId,
    required int rating,
    required String comment,
  });

  Future<AuthResult> submitClientRating({
    required String bookingId,
    required String clientId,
    required int rating,
    String? comment,
  });

  Future<AuthResult> respondToBooking({
    required String bookingId,
    required bool accept,
  });

  Future<AuthResult> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  });
}
