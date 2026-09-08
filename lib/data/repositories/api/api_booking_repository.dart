import '../../../core/api/api_client.dart';
import '../../models/booking_model.dart';
import '../booking_repository.dart';
import '../../models/auth_result_model.dart';

class ApiBookingRepository implements BookingRepository {
  @override
  Future<List<Booking>> getBookings({String? status}) async {
    // GET /api/bookings?status=...
    final res = await ApiClient.get(
      status != null ? '/bookings?status=$status' : '/bookings',
      requiresAuth: true,
    );
    if (res['success'] != true) return [];
    final bookingsData = res['data']?['bookings'] as List<dynamic>? ?? [];
    return bookingsData
        .whereType<Map<String, dynamic>>()
        .map((item) => Booking.fromJson(item))
        .toList();
  }

  @override
  Future<Booking?> getBookingById(String id) async {
    // GET /api/bookings/{id}
    final res = await ApiClient.get('/bookings/$id', requiresAuth: true);
    if (res['success'] != true) return null;
    final bookingJson = res['data']?['booking'];
    if (bookingJson is Map<String, dynamic>) return Booking.fromJson(bookingJson);
    return null;
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
    final res = await ApiClient.post(
      '/bookings',
      body: {
        'worker_id': int.tryParse(workerId) ?? workerId,
        'service_category_id': serviceCategoryId,
        'scheduled_at': scheduledAt.toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (jobPostId != null) 'job_post_id': int.tryParse(jobPostId) ?? jobPostId,
      },
      requiresAuth: true,
    );
    if (res['success'] == true) {
      return AuthResult.success(
        message: res['message'] ?? 'Booking request sent.',
        data: res['data'],
      );
    }
    return AuthResult.failure(
      message: res['message'] ?? 'Failed to send booking request.',
      errors: (res['errors'] is Map) ? res['errors'] as Map<String, dynamic> : null,
    );
  }

  @override
  Future<AuthResult> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    final res = await ApiClient.post(
      '/bookings/$bookingId/cancel',
      body: {'reason': reason},
      requiresAuth: true,
    );
    if (res['success'] == true) {
      return AuthResult.success(
        message: res['message'] ?? 'Booking cancelled.',
        data: res['data'],
      );
    }
    return AuthResult.failure(
      message: res['message'] ?? 'Failed to cancel booking.',
      errors: (res['errors'] is Map) ? res['errors'] as Map<String, dynamic> : null,
    );
  }

  @override
  Future<AuthResult> completeBooking({required String bookingId}) async {
    final res = await ApiClient.post(
      '/bookings/$bookingId/complete',
      requiresAuth: true,
    );
    if (res['success'] == true) {
      return AuthResult.success(
        message: res['message'] ?? 'Booking completed.',
        data: res['data'],
      );
    }
    return AuthResult.failure(
      message: res['message'] ?? 'Failed to complete booking.',
      errors: (res['errors'] is Map) ? res['errors'] as Map<String, dynamic> : null,
    );
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
    final res = await ApiClient.post(
      '/bookings/$bookingId/tracking/location',
      body: {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
      },
      requiresAuth: true,
    );
    if (res['success'] == true) {
      return AuthResult.success(
        message: res['message'] ?? 'Location updated.',
        data: res['data'],
      );
    }
    return AuthResult.failure(
      message: res['message'] ?? 'Failed to update location.',
      errors: (res['errors'] is Map) ? res['errors'] as Map<String, dynamic> : null,
    );
  }

  Future<AuthResult> _trackingAction(String bookingId, String action) async {
    final res = await ApiClient.post(
      '/bookings/$bookingId/tracking/$action',
      requiresAuth: true,
    );
    if (res['success'] == true) {
      return AuthResult.success(
        message: res['message'] ?? 'Tracking $action.',
        data: res['data'],
      );
    }
    return AuthResult.failure(
      message: res['message'] ?? 'Failed to $action tracking.',
      errors: (res['errors'] is Map) ? res['errors'] as Map<String, dynamic> : null,
    );
  }

  @override
  Future<Map<String, dynamic>?> getTrackingStatus(String bookingId) async {
    final res = await ApiClient.get(
      '/bookings/$bookingId/tracking',
      requiresAuth: true,
    );
    if (res['success'] != true) return null;
    return res['data'] as Map<String, dynamic>?;
  }

  @override
  Future<AuthResult> submitReview({
    required String bookingId,
    required String workerId,
    required int rating,
    required String comment,
  }) async {
    // POST /api/bookings/{id}/rate
    // Body: { score: int, comment: string (optional) }
    final res = await ApiClient.post(
      '/bookings/$bookingId/rate',
      body: {
        'score': rating,
        if (comment.isNotEmpty) 'comment': comment,
      },
      requiresAuth: true,
    );
    if (res['success'] == true) {
      return AuthResult.success(
        message: res['message'] ?? 'Review submitted successfully.',
        data: res['data'],
      );
    }
    return AuthResult.failure(
      message: res['message'] ?? 'Failed to submit review.',
      errors: (res['errors'] is Map) ? res['errors'] as Map<String, dynamic> : null,
    );
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
