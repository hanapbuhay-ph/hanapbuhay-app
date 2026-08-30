import 'package:flutter/material.dart';
import '../data/repositories/report_repository.dart';
import '../data/models/report_model.dart';
import '../data/models/auth_result_model.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository;

  ReportProvider(this._repository);

  Future<List<Report>> getReports() => _repository.getReports();
  
  Future<AuthResult> submitReport({
    required String bookingId,
    required String workerId,
    required String reason,
    required String description,
    required List<String> photoPaths,
  }) async {
    final result = await _repository.submitReport(
      bookingId: bookingId,
      workerId: workerId,
      reason: reason,
      description: description,
      photoPaths: photoPaths,
    );
    notifyListeners();
    return result;
  }

  Future<AuthResult> addReportNote({
    required String reportId,
    required String note,
  }) async {
    final result = await _repository.addReportNote(reportId: reportId, note: note);
    notifyListeners();
    return result;
  }
}
