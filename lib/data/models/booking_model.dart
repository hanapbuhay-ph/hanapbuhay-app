import 'package:google_maps_flutter/google_maps_flutter.dart';

class Booking {
  final String id;
  final String workerId;
  final String clientId;
  final String category;
  final DateTime date;
  final String time; // e.g. "10:00 AM"
  final String barangay;
  final LatLng? barangayCoordinates;
  final String notes;
  final BookingStatus status;
  final List<BookingTimelineStep> timeline;
  final bool isRated; // Client rated the worker
  final bool isClientRated; // Worker rated the client
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.workerId,
    required this.clientId,
    required this.category,
    required this.date,
    required this.time,
    required this.barangay,
    this.barangayCoordinates,
    required this.notes,
    required this.status,
    this.timeline = const [],
    this.isRated = false,
    this.isClientRated = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get bookingCode {
    return formatBookingCode(id, createdAt);
  }

  static String formatBookingCode(String id, DateTime createdAt) {
    if (id.startsWith('HB-')) return id; // Already formatted
    // Extract numbers from ID if possible (e.g. 'b1' -> '1')
    final numericId = id.replaceAll(RegExp(r'[^0-9]'), '');
    final sequence = numericId.isEmpty ? '0' : numericId;
    return 'HB-${createdAt.year}-${sequence.padLeft(5, '0')}';
  }
}

class BookingTimelineStep {
  final String label;
  final DateTime? timestamp;
  final bool isCompleted;

  BookingTimelineStep({
    required this.label,
    this.timestamp,
    this.isCompleted = false,
  });
}

enum BookingStatus {
  pending,
  upcoming,
  accepted,
  active,
  completed,
  cancelled
}
