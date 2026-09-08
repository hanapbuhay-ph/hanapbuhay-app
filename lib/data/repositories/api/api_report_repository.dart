import '../../models/report_model.dart';
import '../../../core/api/api_client.dart';
import '../report_repository.dart';
import '../../models/auth_result_model.dart';

class ApiReportRepository implements ReportRepository {
  @override
  Future<List<Report>> getReports() async {
    // GET /api/reports
    final res = await ApiClient.get('/reports', requiresAuth: true);
    if (res['success'] != true) return [];
    final reportsData = res['data']?['reports'] as List<dynamic>? ?? [];

    final reports = <Report>[];
    for (final item in reportsData.whereType<Map<String, dynamic>>()) {
      // GET /api/reports list omits `description` and `admin_remarks`;
      // the Report Status UI needs them, so fetch each report's detail.
      final detail = await _getReportDetail(item['id']?.toString() ?? '');
      reports.add(detail ?? Report.fromJson(item));
    }
    return reports;
  }

  Future<Report?> _getReportDetail(String id) async {
    final res = await ApiClient.get('/reports/$id', requiresAuth: true);
    if (res['success'] != true) return null;
    final reportJson = res['data']?['report'];
    if (reportJson is Map<String, dynamic>) return Report.fromJson(reportJson);
    return null;
  }

  @override
  Future<AuthResult> submitReport({
    required String bookingId,
    required String workerId,
    required String reason,
    required String description,
    required List<String> photoPaths,
  }) async {
    // POST /api/reports (multipart/form-data)
    final res = await ApiClient.postMultipart(
      '/reports',
      fields: {
        'booking_id': int.tryParse(bookingId)?.toString() ?? bookingId,
        'reported_user_id': int.tryParse(workerId)?.toString() ?? workerId,
        'reason': reason,
        'description': description,
      },
      files: {'evidence_photos[]': photoPaths},
      requiresAuth: true,
    );
    if (res['success'] == true) {
      return AuthResult.success(
        message: res['message'] ?? 'Report submitted successfully.',
        data: res['data'] is Map ? res['data'] as Map<String, dynamic> : null,
      );
    }
    return AuthResult.failure(
      message: res['message'] ?? 'Failed to submit report.',
      errors: (res['errors'] is Map) ? res['errors'] as Map<String, dynamic> : null,
    );
  }

  @override
  Future<AuthResult> addReportNote({
    required String reportId,
    required String note,
  }) async {
    // NOTE: There is NO backend endpoint for clients to add follow-up notes
    // to a report (POST /api/reports/{id}/notes does not exist). Only the
    // admin resolve endpoint (PATCH /api/admin/reports/{id}/resolve) records
    // admin remarks. Kept unimplemented; see HANDOFF.md (B5 mismatch note).
    throw UnimplementedError(
      'addReportNote is not supported by the backend (no reports/{id}/notes endpoint).',
    );
  }
}
