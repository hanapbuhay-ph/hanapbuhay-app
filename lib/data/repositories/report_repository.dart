import '../models/report_model.dart';
import '../models/auth_result_model.dart';

abstract class ReportRepository {
  Future<List<Report>> getReports();

  Future<AuthResult> submitReport({
    required String bookingId,
    required String workerId,
    required String reason,
    required String description,
    required List<String> photoPaths,
  });

  Future<AuthResult> addReportNote({
    required String reportId,
    required String note,
  });
}
