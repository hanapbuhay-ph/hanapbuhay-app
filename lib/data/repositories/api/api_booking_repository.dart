import '../../models/booking_model.dart';
import '../booking_repository.dart';
import '../../models/auth_result_model.dart';

class ApiBookingRepository implements BookingRepository {
  @override
  Future<List<Booking>> getBookings() async {
    // TODO: Implement real API call: GET /api/bookings
    throw UnimplementedError('Real API getBookings not implemented yet.');
  }

  @override
  Future<Booking?> getBookingById(String id) async {
    // TODO: Implement real API call: GET /api/bookings/{id}
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> createBooking({
    required String workerId,
    required String category,
    required DateTime date,
    required String time,
    required String notes,
    required String barangay,
  }) async {
    // TODO: This endpoint is not yet live on the backend.
    // POST /api/bookings
    throw UnimplementedError('Real API booking creation not implemented yet.');
  }

  @override
  Future<AuthResult> submitReview({
    required String bookingId,
    required String workerId,
    required int rating,
    required String comment,
  }) async {
    // TODO: POST /api/ratings
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> submitClientRating({
    required String bookingId,
    required String clientId,
    required int rating,
    String? comment,
  }) async {
    // TODO: POST /api/client-ratings
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> respondToBooking({
    required String bookingId,
    required bool accept,
  }) async {
    // TODO: POST /api/bookings/{id}/respond
    throw UnimplementedError();
  }
}
