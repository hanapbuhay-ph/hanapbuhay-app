class Report {
  final String id;
  final String bookingId;
  final String workerId;
  final String? reporterName;
  final String? reporterPhotoUrl;
  final String? reporterPhotoPath;
  final String? reportedUserName;
  final String? reportedUserPhotoUrl;
  final String reason;
  final String reasonLabel;
  final String description;
  final List<String> photoPaths;
  final ReportStatus status;
  final String? adminRemarks;
  final String? resolutionAction;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final List<ReportFollowUpNote> followUpNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Report({
    required this.id,
    required this.bookingId,
    required this.workerId,
    this.reporterName,
    this.reporterPhotoUrl,
    this.reporterPhotoPath,
    this.reportedUserName,
    this.reportedUserPhotoUrl,
    required this.reason,
    String? reasonLabel,
    required this.description,
    this.photoPaths = const [],
    this.status = ReportStatus.pending,
    this.adminRemarks,
    this.resolutionAction,
    this.resolvedBy,
    this.resolvedAt,
    this.followUpNotes = const [],
    required this.createdAt,
    this.updatedAt,
  }) : reasonLabel = reasonLabel ?? reason;

  factory Report.fromJson(Map<String, dynamic> json) {
    final reporter = json['reporter'] is Map ? json['reporter'] as Map : null;
    final reportedUser = json['reported_user'] is Map ? json['reported_user'] as Map : null;
    return Report(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      workerId: json['reported_user_id']?.toString() ?? '',
      reporterName: reporter?['name']?.toString() ?? (json['reporter'] is String ? json['reporter'].toString() : null),
      reporterPhotoUrl: reporter?['profile_photo_url']?.toString(),
      reporterPhotoPath: reporter?['profile_photo_path']?.toString(),
      reportedUserName: reportedUser?['name']?.toString() ?? (json['reported_user'] is String ? json['reported_user'].toString() : null),
      reportedUserPhotoUrl: reportedUser?['profile_photo_url']?.toString(),
      reason: json['reason']?.toString() ?? '',
      reasonLabel: json['reason_label']?.toString() ?? json['reason']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      photoPaths: (json['evidence_paths'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      status: _statusFromJson(json['status']?.toString()),
      adminRemarks: json['admin_remarks']?.toString(),
      resolutionAction: json['resolution_action']?.toString(),
      resolvedBy: json['resolved_by']?.toString(),
      resolvedAt: json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at'].toString()) : null,
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
