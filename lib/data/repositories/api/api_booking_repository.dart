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

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<Booking>> getBookings({String? status}) async {
    // GET /api/bookings?status=...
    try {
      final headers = await _headers();
      final uri = Uri.parse('$baseUrl/bookings').replace(queryParameters: status != null ? {'status': status} : null);
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookingsData = data['data']?['bookings'] as List<dynamic>? ?? [];
        return bookingsData.whereType<Map<String, dynamic>>().map((item) => Booking.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('[ApiBookingRepository] getBookings error: $e');
      return [];
    }
  }

  @override
  Future<Booking?> getBookingById(String id) async {
    // GET /api/bookings/{id}
    try {
      final headers = await _headers();
      final response = await http.get(Uri.parse('$baseUrl/bookings/$id'), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookingJson = data['data']?['booking'];
        if (bookingJson is Map<String, dynamic>) return Booking.fromJson(bookingJson);
      }
      return null;
    } catch (e) {
      print('[ApiBookingRepository] getBookingById error: $e');
      return null;
    }
  }


  @override
  Future<AuthResult> createBooking({
    required String workerId,
    required int? serviceCategoryId,
    required DateTime scheduledAt,
    String? notes,
    String? jobPostId,
  }) async {
    // POST /api/bookings
    try {
      final headers = await _headers();
      final body = <String, dynamic>{
        'worker_id': int.tryParse(workerId) ?? workerId,
        'service_category_id': serviceCategoryId,
        'scheduled_at': scheduledAt.toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (jobPostId != null) 'job_post_id': int.tryParse(jobPostId) ?? jobPostId,
      };
      final response = await http.post(Uri.parse('$baseUrl/bookings'), headers: headers, body: jsonEncode(body));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.success(message: data['message'] ?? 'Booking request sent.', data: data['data']);
      } else {
        return AuthResult.failure(message: data['message'] ?? 'Failed to send booking request.', errors: data['errors']);
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  @override
  Future<AuthResult> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    try {
      final headers = await _headers();
      final response = await http.post(Uri.parse('$baseUrl/bookings/$bookingId/cancel'), headers: headers, body: jsonEncode({'reason': reason}));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.success(message: data['message'] ?? 'Booking cancelled.', data: data['data']);
      } else {
        return AuthResult.failure(message: data['message'] ?? 'Failed to cancel booking.', errors: data['errors']);
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  @override
  Future<AuthResult> completeBooking({required String bookingId}) async {
    try {
      final headers = await _headers();
      final response = await http.post(Uri.parse('$baseUrl/bookings/$bookingId/complete'), headers: headers);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.success(message: data['message'] ?? 'Booking completed.', data: data['data']);
      } else {
        return AuthResult.failure(message: data['message'] ?? 'Failed to complete booking.', errors: data['errors']);
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }


  @override
  Future<AuthResult> startTracking({required String bookingId}) async {
    return _trackingAction(bookingId, 'start');
  }

  @override
  Future<AuthResult> stopTracking({required String bookingId}) async {
    return _trackingAction(bookingId, 'stop');
  }

  @override
  Future<AuthResult> updateTrackingLocation({
    required String bookingId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    try {
      final headers = await _headers();
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/tracking/location'),
        headers: headers,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          if (accuracy != null) 'accuracy': accuracy,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.success(message: data['message'] ?? 'Location updated.', data: data['data']);
      } else {
        return AuthResult.failure(message: data['message'] ?? 'Failed to update location.', errors: data['errors']);
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  Future<AuthResult> _trackingAction(String bookingId, String action) async {
    try {
      final headers = await _headers();
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/tracking/$action'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.success(message: data['message'] ?? 'Tracking $action.', data: data['data']);
      } else {
        return AuthResult.failure(message: data['message'] ?? 'Failed to $action tracking.', errors: data['errors']);
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getTrackingStatus(String bookingId) async {
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$bookingId/tracking'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  @override
  Future<AuthResult> submitReview({
    required String bookingId,
    required String workerId,
    required int rating,
    required String comment,
  }) async {
    throw UnimplementedError('submitReview uses /api/ratings - not a B3 method.');
  }

  @override
  Future<AuthResult> submitClientRating({
    required String bookingId,
    required String clientId,
    required int rating,
    String? comment,
  }) async {
    throw UnimplementedError('submitClientRating not implemented yet.');
  }

  @override
  Future<AuthResult> respondToBooking({
    required String bookingId,
    required bool accept,
  }) async {
    throw UnimplementedError('respondToBooking is worker-side, not used by B3 client screens.');
  }

  @override
  Future<AuthResult> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    switch (status) {
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return cancelBooking(bookingId: bookingId);
      case BookingStatus.completed:
        return completeBooking(bookingId: bookingId);
      case BookingStatus.active:
        return startTracking(bookingId: bookingId);
      default:
        return AuthResult.failure(message: 'No mapping for status: ${status.name}');
    }
  }
}

