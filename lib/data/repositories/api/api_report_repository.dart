import '../../models/report_model.dart';
import '../report_repository.dart';
import '../../models/auth_result_model.dart';

class ApiReportRepository implements ReportRepository {
  @override
  Future<List<Report>> getReports() async {
    // TODO: GET /api/reports
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> submitReport({
    required String bookingId,
    required String workerId,
    required String reason,
    required String description,
    required List<String> photoPaths,
  }) async {
    // TODO: Implement real API call: POST /api/reports
    throw UnimplementedError('Real API report submission not implemented yet.');
  }

  @override
  Future<AuthResult> addReportNote({
    required String reportId,
    required String note,
  }) async {
    // TODO: POST /api/reports/{id}/notes
    throw UnimplementedError();
  }
}
