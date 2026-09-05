import '../models/worker_model.dart';
import '../models/auth_result_model.dart';
import '../models/job_post_model.dart';

abstract class WorkerRepository {
  Future<List<Worker>> getTopRatedWorkers();
  Future<List<Worker>> getRecentlyViewedWorkers();
  Future<List<ServiceCategory>> getCategories();
  Future<Worker?> getWorkerById(String id);
  Future<JobPostListing?> getJobPostDetail(String postId);
  Future<AuthResult> submitVerificationDocuments({
    required String workerId,
    required String govIdPath,
    required String brgyCertPath,
    required String selfiePath,
  });
  Future<AuthResult> updateProfile({
    required String workerId,
    required List<String> categories,
    required List<String> photoPaths,
    required String bio,
  });
  Future<AuthResult> createJobPost(JobPost post);
  Future<AuthResult> updateJobPost(JobPost post);
  Future<AuthResult> deleteJobPost(String postId);
  Future<List<JobPostImage>> uploadPostImages(String postId, List<String> filePaths);
  Future<AuthResult> deletePostImage(String postId, String imageId);
  Future<AuthResult> reorderPostImages(String postId, List<String> imageIds);
}
