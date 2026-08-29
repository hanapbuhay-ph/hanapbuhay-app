import '../../models/report_model.dart';
import '../report_repository.dart';
import '../../models/auth_result_model.dart';

class MockReportRepository implements ReportRepository {
  final List<Report> _mockReports = [
    Report(
      id: 'r1',
      bookingId: 'b1',
      workerId: 'w1',
      reason: 'Unsatisfactory work',
      description: 'The plumber arrived late and did not fully fix the leaking pipe under the sink. It started dripping again after a few hours.',
      status: ReportStatus.underReview,
      adminRemarks: 'Our team has reviewed your report and contacted the worker for clarification. We are currently verifying the service log.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      followUpNotes: [],
    ),
    Report(
      id: 'r2',
      bookingId: 'b2',
      workerId: 'w2',
      reason: 'No-show',
      description: 'The cleaner was scheduled to arrive at 10:00 AM but never showed up and is not answering calls.',
      status: ReportStatus.resolved,
      adminRemarks: 'We apologize for the inconvenience. The worker experienced a medical emergency and has been notified of the missed appointment on their record. Please contact the worker directly to reschedule if needed.',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      updatedAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
  ];

  @override
  Future<List<Report>> getReports() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockReports;
  }

  @override
  Future<AuthResult> submitReport({
    required String bookingId,
    required String workerId,
    required String reason,
    required String description,
    required List<String> photoPaths,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    final newReport = Report(
      id: 'r${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      workerId: workerId,
      reason: reason,
      description: description,
      photoPaths: photoPaths,
      status: ReportStatus.pending,
      createdAt: DateTime.now(),
    );
    _mockReports.insert(0, newReport);
    return AuthResult.success(message: 'Report submitted successfully. We will review it shortly.');
  }

  @override
  Future<AuthResult> addReportNote({
    required String reportId,
    required String note,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final index = _mockReports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final old = _mockReports[index];
      final newNote = ReportFollowUpNote(text: note, timestamp: DateTime.now());
      _mockReports[index] = Report(
        id: old.id,
        bookingId: old.bookingId,
        workerId: old.workerId,
        reason: old.reason,
        description: old.description,
        photoPaths: old.photoPaths,
        status: old.status,
        adminRemarks: old.adminRemarks,
        followUpNotes: [...old.followUpNotes, newNote],
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
    }
    return AuthResult.success(message: 'Note added successfully.');
  }
}
