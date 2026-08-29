import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/booking_model.dart';
import '../booking_repository.dart';
import '../../models/auth_result_model.dart';

class MockBookingRepository implements BookingRepository {
  final List<Booking> _mockBookings = [
    Booking(
      id: 'b1',
      workerId: 'w1',
      clientId: 'c1',
      category: 'Plumbing Services',
      date: DateTime.now().add(const Duration(days: 2)),
      time: '9:00 AM',
      barangay: 'Poblacion',
      barangayCoordinates: const LatLng(9.9575, 124.3517),
      notes: 'Kitchen sink leak',
      status: BookingStatus.upcoming,
      timeline: [
        BookingTimelineStep(label: 'Requested', timestamp: DateTime.now().subtract(const Duration(hours: 2)), isCompleted: true),
        BookingTimelineStep(label: 'Accepted'),
        BookingTimelineStep(label: 'En Route'),
        BookingTimelineStep(label: 'In Progress'),
        BookingTimelineStep(label: 'Completed'),
      ],
    ),
    Booking(
      id: 'b2',
      workerId: 'w2',
      clientId: 'c1',
      category: 'Electrical Repair',
      date: DateTime.now().add(const Duration(days: 4)),
      time: '2:00 PM',
      barangay: 'Poblacion',
      barangayCoordinates: const LatLng(9.9575, 124.3517),
      notes: 'Socket replacement',
      status: BookingStatus.upcoming,
      timeline: [
        BookingTimelineStep(label: 'Requested', timestamp: DateTime.now().subtract(const Duration(days: 1)), isCompleted: true),
        BookingTimelineStep(label: 'Accepted'),
        BookingTimelineStep(label: 'En Route'),
        BookingTimelineStep(label: 'In Progress'),
        BookingTimelineStep(label: 'Completed'),
      ],
    ),
    Booking(
      id: 'b3',
      workerId: 'w1',
      clientId: 'c1',
      category: 'Plumbing Services',
      date: DateTime.now(),
      time: '10:30 AM',
      barangay: 'Poblacion',
      barangayCoordinates: const LatLng(9.9575, 124.3517),
      notes: 'Ongoing maintenance',
      status: BookingStatus.active,
      timeline: [
        BookingTimelineStep(label: 'Requested', timestamp: DateTime.now().subtract(const Duration(hours: 5)), isCompleted: true),
        BookingTimelineStep(label: 'Accepted', timestamp: DateTime.now().subtract(const Duration(hours: 4)), isCompleted: true),
        BookingTimelineStep(label: 'En Route', timestamp: DateTime.now().subtract(const Duration(hours: 1)), isCompleted: true),
        BookingTimelineStep(label: 'In Progress', isCompleted: true),
        BookingTimelineStep(label: 'Completed'),
      ],
    ),
    Booking(
      id: 'b4',
      workerId: 'w3',
      clientId: 'c1',
      category: 'Math Tutoring',
      date: DateTime.now().subtract(const Duration(days: 3)),
      time: '4:00 PM',
      barangay: 'Poblacion',
      barangayCoordinates: const LatLng(9.9575, 124.3517),
      notes: 'Algebra review',
      status: BookingStatus.completed,
      isRated: false,
      timeline: [
        BookingTimelineStep(label: 'Requested', isCompleted: true),
        BookingTimelineStep(label: 'Accepted', isCompleted: true),
        BookingTimelineStep(label: 'En Route', isCompleted: true),
        BookingTimelineStep(label: 'In Progress', isCompleted: true),
        BookingTimelineStep(label: 'Completed', timestamp: DateTime.now().subtract(const Duration(days: 3)), isCompleted: true),
      ],
    ),
    Booking(
      id: 'b6',
      workerId: 'w1',
      clientId: 'c2',
      category: 'Plumbing Repair',
      date: DateTime.now().add(const Duration(days: 1)),
      time: '10:00 AM',
      barangay: 'Guadalupe Nuevo',
      notes: 'Faucet leaking heavily.',
      status: BookingStatus.pending,
    ),
    Booking(
      id: 'b7',
      workerId: 'w1',
      clientId: 'c3',
      category: 'Electrical Install',
      date: DateTime.now().add(const Duration(days: 2)),
      time: '2:00 PM',
      barangay: 'San Isidro',
      notes: 'New light fixtures installation.',
      status: BookingStatus.pending,
    ),
  ];

  @override
  Future<List<Booking>> getBookings() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockBookings;
  }

  @override
  Future<Booking?> getBookingById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      return _mockBookings.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
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
    await Future.delayed(const Duration(seconds: 1));
    return AuthResult.success(message: 'Booking request sent successfully!');
  }

  @override
  Future<AuthResult> submitReview({
    required String bookingId,
    required String workerId,
    required int rating,
    required String comment,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Update local mock state
    final index = _mockBookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final old = _mockBookings[index];
      _mockBookings[index] = Booking(
        id: old.id,
        workerId: old.workerId,
        clientId: old.clientId,
        category: old.category,
        date: old.date,
        time: old.time,
        barangay: old.barangay,
        barangayCoordinates: old.barangayCoordinates,
        notes: old.notes,
        status: old.status,
        timeline: old.timeline,
        isRated: true,
        isClientRated: old.isClientRated,
      );
    }

    return AuthResult.success(message: 'Review submitted successfully!');
  }

  @override
  Future<AuthResult> submitClientRating({
    required String bookingId,
    required String clientId,
    required int rating,
    String? comment,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Update local mock state
    final index = _mockBookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final old = _mockBookings[index];
      _mockBookings[index] = Booking(
        id: old.id,
        workerId: old.workerId,
        clientId: old.clientId,
        category: old.category,
        date: old.date,
        time: old.time,
        barangay: old.barangay,
        barangayCoordinates: old.barangayCoordinates,
        notes: old.notes,
        status: old.status,
        timeline: old.timeline,
        isRated: old.isRated,
        isClientRated: true,
      );
    }

    return AuthResult.success(message: 'Rating submitted successfully!');
  }

  @override
  Future<AuthResult> respondToBooking({
    required String bookingId,
    required bool accept,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final index = _mockBookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final old = _mockBookings[index];
      _mockBookings[index] = Booking(
        id: old.id,
        workerId: old.workerId,
        clientId: old.clientId,
        category: old.category,
        date: old.date,
        time: old.time,
        barangay: old.barangay,
        barangayCoordinates: old.barangayCoordinates,
        notes: old.notes,
        status: accept ? BookingStatus.accepted : BookingStatus.cancelled,
        timeline: old.timeline,
        isRated: old.isRated,
        isClientRated: old.isClientRated,
      );
    }
    return AuthResult.success(message: accept ? 'Booking accepted!' : 'Booking declined.');
  }
}
