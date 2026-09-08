import '../models/worker_model.dart';
import '../models/auth_result_model.dart';
import '../models/job_post_model.dart';

/// Filter options for the worker feed (Client Home Screen)
class FeedFilters {
  final String? categoryId;
  final String? barangayId;
  final String? rateType; // hourly, daily, weekly, monthly, per_session, per_project
  final String? verification; // all, verified, unverified
  final String? availability; // all, available
  final int page;

  const FeedFilters({
    this.categoryId,
    this.barangayId,
    this.rateType,
    this.verification = 'all',
    this.availability = 'all',
    this.page = 1,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (categoryId != null) params['category_id'] = categoryId!;
    if (barangayId != null) params['barangay_id'] = barangayId!;
    if (rateType != null) params['rate_type'] = rateType!;
    if (verification != null && verification != 'all') params['verification'] = verification!;
    if (availability != null && availability != 'all') params['availability'] = availability!;
    params['page'] = page.toString();
    return params;
  }
}

/// Paginated feed response
class FeedResponse {
  final List<JobPostListing> posts;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const FeedResponse({
    required this.posts,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;
}

abstract class WorkerRepository {
  /// GET /api/feed — Client home feed with filters
  Future<FeedResponse> getFeed(FeedFilters filters);
  
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
