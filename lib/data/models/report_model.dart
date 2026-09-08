class Report {
  final String id;
  final String bookingId;
  final String workerId;
  final String reason;
  final String description;
  final List<String> photoPaths;
  final ReportStatus status;
  final String? adminRemarks;
  final List<ReportFollowUpNote> followUpNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Report({
    required this.id,
    required this.bookingId,
    required this.workerId,
    required this.reason,
    required this.description,
    this.photoPaths = const [],
    this.status = ReportStatus.pending,
    this.adminRemarks,
    this.followUpNotes = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      workerId: json['reported_user_id']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      photoPaths: (json['evidence_paths'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      status: _statusFromJson(json['status']?.toString()),
      adminRemarks: json['admin_remarks']?.toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  static ReportStatus _statusFromJson(String? status) {
    switch (status) {
      case 'under_review':
        return ReportStatus.underReview;
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }
}

class ReportFollowUpNote {
  final String text;
  final DateTime timestamp;

  ReportFollowUpNote({
    required this.text,
    required this.timestamp,
  });
}

enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed
}
