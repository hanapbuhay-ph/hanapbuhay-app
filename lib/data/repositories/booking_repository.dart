import '../models/booking_model.dart';
import '../models/auth_result_model.dart';

abstract class BookingRepository {
  Future<List<Booking>> getBookings();
  Future<Booking?> getBookingById(String id);
  
  Future<AuthResult> createBooking({
    required String workerId,
    required String category,
    required DateTime date,
    required String time,
    required String notes,
    required String barangay,
    String? jobPostId,
  });

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
