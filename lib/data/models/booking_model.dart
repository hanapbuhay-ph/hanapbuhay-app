import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';

class Booking {
  final String id;
  final String workerId;
  final String clientId;
  final String? jobPostId;
  final String category;
  final DateTime date;
  final String time;
  final String barangay;
  final LatLng? barangayCoordinates;
  final String notes;
  final BookingStatus status;
  final List<BookingTimelineStep> timeline;
  final bool isRated;
  final bool isClientRated;
  final DateTime createdAt;

  // API-sourced fields
  final String? _apiBookingCode;
  final String? workerName;
  final String? workerPhotoUrl;
  final bool isClientTracking;
  final bool isWorkerTracking;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? cancellationReason;
  final int? serviceCategoryId;
  final int? workerUserId;
  final String? clientName;
  final String? clientPhotoUrl;
  final LatLng? clientBarangayCoordinates;
  final String? clientBarangay;

  Booking({
    required this.id,
    required this.workerId,
    required this.clientId,
    this.jobPostId,
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
    String? apiBookingCode,
    this.workerName,
    this.workerPhotoUrl,
    this.isClientTracking = false,
    this.isWorkerTracking = false,
    this.startedAt,
    this.completedAt,
    this.cancellationReason,
    this.serviceCategoryId,
    this.workerUserId,
    this.clientName,
    this.clientPhotoUrl,
    this.clientBarangayCoordinates,
    this.clientBarangay,
  })  : _apiBookingCode = apiBookingCode,
        createdAt = createdAt ?? DateTime.now();

  String get bookingCode {
    if (_apiBookingCode != null && _apiBookingCode!.isNotEmpty) {
      return _apiBookingCode!;
    }
    return formatBookingCode(id, createdAt);
  }

  static String formatBookingCode(String id, DateTime createdAt) {
    if (id.startsWith('HB-')) return id;
    final numericId = id.replaceAll(RegExp(r'[^0-9]'), '');
    final sequence = numericId.isEmpty ? '0' : numericId;
    return 'HB-${createdAt.year}-${sequence.padLeft(5, '0')}';
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString() ?? 'pending';
    BookingStatus status;
    switch (statusStr) {
      case 'pending':
        status = BookingStatus.pending;
        break;
      case 'accepted':
        status = BookingStatus.accepted;
        break;
      case 'active':
        status = BookingStatus.active;
        break;
      case 'completed':
        status = BookingStatus.completed;
        break;
      case 'cancelled':
        status = BookingStatus.cancelled;
        break;
      case 'declined':
        status = BookingStatus.declined;
        break;
      default:
        status = BookingStatus.pending;
    }

    final wj = json['worker'] is Map ? json['worker'] as Map<String, dynamic> : null;
    final wUserId = wj != null ? (wj['id'] ?? json['worker_id']) : json['worker_id'];
    final wName = wj?['name']?.toString();
    final wPhoto = wj?['profile_photo_url']?.toString() ??
        wj?['profile_photo_path']?.toString() ??
        AppConstants.defaultAvatar;

    final wbJ = wj?['barangay'] is Map ? wj!['barangay'] as Map<String, dynamic> : null;
    final wbName = wbJ?['name']?.toString() ?? (wj?['barangay']?.toString() ?? '');
    final wbLat = wbJ != null ? double.tryParse(wbJ['latitude']?.toString() ?? '') : null;
    final wbLng = wbJ != null ? double.tryParse(wbJ['longitude']?.toString() ?? '') : null;
    final wbCoord = (wbLat != null && wbLng != null) ? LatLng(wbLat, wbLng) : null;

    final cj = json['client'] is Map ? json['client'] as Map<String, dynamic> : null;
    final cName = cj?['name']?.toString();
    final cPhoto = cj?['profile_photo_url']?.toString() ??
        cj?['profile_photo_path']?.toString() ??
        AppConstants.defaultAvatar;

    final cbJ = cj?['barangay'] is Map ? cj!['barangay'] as Map<String, dynamic> : null;
    final cbName = cbJ?['name']?.toString();
    final cbLat = cbJ != null ? double.tryParse(cbJ['latitude']?.toString() ?? '') : null;
    final cbLng = cbJ != null ? double.tryParse(cbJ['longitude']?.toString() ?? '') : null;
    final cbCoord = (cbLat != null && cbLng != null) ? LatLng(cbLat, cbLng) : null;

    final scJson = json['service_category'];
    final scName = scJson is Map ? (scJson['name']?.toString() ?? '') : (scJson?.toString() ?? '');
    final scId = scJson is Map ? (scJson['id'] as num?)?.toInt() : null;

    final schedAt = json['scheduled_at'] != null
        ? DateTime.tryParse(json['scheduled_at'].toString()) ?? DateTime.now()
        : DateTime.now();
    final tm = AppFormatters.time(schedAt);

    final sAt = json['started_at'] != null ? DateTime.tryParse(json['started_at'].toString()) : null;
    final cAt = json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null;
    final crAt = json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now();
    final tl = _buildTimeline(status, crAt, sAt, cAt);

    return Booking(
      id: json['id']?.toString() ?? '',
      workerId: wUserId?.toString() ?? json['worker_id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      jobPostId: json['job_post_id']?.toString(),
      category: scName,
      date: schedAt,
      time: tm,
      barangay: wbName,
      barangayCoordinates: wbCoord,
      notes: json['notes']?.toString() ?? '',
      status: status,
      timeline: tl,
      createdAt: crAt,
      apiBookingCode: json['booking_code']?.toString(),
      workerName: wName,
      workerPhotoUrl: wPhoto,
      isClientTracking: json['is_client_tracking'] == true,
      isWorkerTracking: json['is_worker_tracking'] == true,
      startedAt: sAt,
      completedAt: cAt,
      cancellationReason: json['cancellation_reason']?.toString(),
      serviceCategoryId: scId,
      workerUserId: wUserId is num ? wUserId.toInt() : int.tryParse(wUserId?.toString() ?? ''),
      clientName: cName,
      clientPhotoUrl: cPhoto,
      clientBarangayCoordinates: cbCoord,
      clientBarangay: cbName,
    );
  }

  static List<BookingTimelineStep> _buildTimeline(
    BookingStatus status, DateTime createdAt, DateTime? startedAt, DateTime? completedAt,
  ) {
    final isA = status == BookingStatus.accepted || status == BookingStatus.active || status == BookingStatus.completed;
    final isAC = status == BookingStatus.active || status == BookingStatus.completed;
    return [
      BookingTimelineStep(label: 'Requested', timestamp: createdAt, isCompleted: true),
      BookingTimelineStep(label: 'Accepted', timestamp: isA ? (startedAt?.subtract(const Duration(hours: 1))) : null, isCompleted: isA),
      BookingTimelineStep(label: 'Active', timestamp: startedAt, isCompleted: isAC),
      BookingTimelineStep(label: 'Completed', timestamp: completedAt, isCompleted: status == BookingStatus.completed),
    ];
  }
}

class BookingTimelineStep {
  final String label;
  final DateTime? timestamp;
  final bool isCompleted;

  BookingTimelineStep({required this.label, this.timestamp, this.isCompleted = false});
}

enum BookingStatus {
  pending,
  upcoming,
  accepted,
  active,
  completed,
  cancelled,
  declined,
}
