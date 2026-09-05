import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../services/secure_storage_service.dart';
import '../../models/booking_model.dart';
import '../booking_repository.dart';
import '../../models/auth_result_model.dart';

class ApiBookingRepository implements BookingRepository {
  final String baseUrl = AppConstants.apiBaseUrl;
  final SecureStorageService _storage = SecureStorageService();

  @override
  Future<List<Booking>> getBookings() async {
    // GET /api/bookings
    throw UnimplementedError('Real API getBookings not implemented yet.');
  }

  @override
  Future<Booking?> getBookingById(String id) async {
    // GET /api/bookings/{id}
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
    String? jobPostId,
  }) async {
    try {
      final token = await _storage.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'worker_profile_id': int.tryParse(workerId) ?? workerId,
          'service_category_id': int.tryParse(category) ?? category,
          if (jobPostId != null) 'job_post_id': int.tryParse(jobPostId) ?? jobPostId,
          'scheduled_at': '${date.toIso8601String().split('T').first} $time',
          'notes': notes,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.success(
          message: data['message'] ?? 'Booking request sent.',
          data: data['data'],
        );
      } else {
        return AuthResult.failure(
          message: data['message'] ?? 'Failed to send booking request.',
          errors: data['errors'],
        );
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  @override
  Future<AuthResult> submitReview({
    required String bookingId,
    required String workerId,
    required int rating,
    required String comment,
  }) async {
    // POST /api/ratings
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> submitClientRating({
    required String bookingId,
    required String clientId,
    required int rating,
    String? comment,
  }) async {
    // POST /api/client-ratings
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> respondToBooking({
    required String bookingId,
    required bool accept,
  }) async {
    // POST /api/bookings/{id}/respond
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    // POST /api/bookings/{id}/status
    throw UnimplementedError();
  }
}
