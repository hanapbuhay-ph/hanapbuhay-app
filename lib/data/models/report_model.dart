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
