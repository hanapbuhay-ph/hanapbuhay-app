import 'package:flutter/material.dart';
import '../data/repositories/worker_repository.dart';
import '../data/models/worker_model.dart';
import '../data/models/auth_result_model.dart';

class WorkerProvider extends ChangeNotifier {
  final WorkerRepository _repository;

  WorkerProvider(this._repository);

  Future<List<ServiceCategory>> getCategories() => _repository.getCategories();
  Future<List<Worker>> getTopRatedWorkers() => _repository.getTopRatedWorkers();
  Future<List<Worker>> getRecentlyViewedWorkers() => _repository.getRecentlyViewedWorkers();
  Future<Worker?> getWorkerById(String id) => _repository.getWorkerById(id);
  
  Future<AuthResult> submitVerificationDocuments({
    required String workerId,
    required String govIdPath,
    required String brgyCertPath,
    required String selfiePath,
  }) async {
    final result = await _repository.submitVerificationDocuments(
      workerId: workerId,
      govIdPath: govIdPath,
      brgyCertPath: brgyCertPath,
      selfiePath: selfiePath,
    );
    notifyListeners();
    return result;
  }

  Future<AuthResult> updateWorkerProfile({
    required String workerId,
    required List<String> categories,
    required List<String> photoPaths,
    required String bio,
  }) async {
    final result = await _repository.updateProfile(
      workerId: workerId,
      categories: categories,
      photoPaths: photoPaths,
      bio: bio,
    );
    notifyListeners();
    return result;
  }
}
