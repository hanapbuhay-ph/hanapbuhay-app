import '../../models/worker_model.dart';
import '../worker_repository.dart';
import '../../models/auth_result_model.dart';

class ApiWorkerRepository implements WorkerRepository {
  @override
  Future<List<ServiceCategory>> getCategories() {
    // TODO: Implement real API call: GET /api/categories
    throw UnimplementedError('Real API categories not implemented yet.');
  }

  @override
  Future<List<Worker>> getRecentlyViewedWorkers() {
    // TODO: Implement real API call: GET /api/workers/recent
    throw UnimplementedError();
  }

  @override
  Future<List<Worker>> getTopRatedWorkers() {
    // TODO: Implement real API call: GET /api/workers?sort=rating
    throw UnimplementedError();
  }

  @override
  Future<Worker?> getWorkerById(String id) {
    // TODO: Implement real API call: GET /api/workers/{id}
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> submitVerificationDocuments({
    required String workerId,
    required String govIdPath,
    required String brgyCertPath,
    required String selfiePath,
  }) async {
    // TODO: POST /api/workers/verify
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> updateProfile({
    required String workerId,
    required List<String> categories,
    required List<String> photoPaths,
    required String bio,
  }) async {
    // TODO: POST /api/workers/profile/update
    throw UnimplementedError();
  }
}
