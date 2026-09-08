import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../models/worker_model.dart';
import '../worker_repository.dart';
import '../../models/auth_result_model.dart';
import '../../models/job_post_model.dart';

class ApiWorkerRepository implements WorkerRepository {
  String _queryString(Map<String, String> params) {
    return params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
  }

  @override
  Future<FeedResponse> getFeed(FeedFilters filters) async {
    // GET /api/feed
    final query = _queryString(filters.toQueryParams());
    final res = await ApiClient.get('/feed?$query', requiresAuth: true);

    if (res['success'] != true) {
      // Return empty response on error (screen will show empty state)
      print('[ApiWorkerRepository] getFeed error: ${res['message']}');
      return const FeedResponse(
        posts: [],
        currentPage: 1,
        perPage: 15,
        total: 0,
        lastPage: 1,
      );
    }

    final postsData = res['data']?['posts'] as List<dynamic>? ?? [];
    final pagination = res['data']?['pagination'] as Map<String, dynamic>? ?? {};

    final posts = postsData
        .map((item) => JobPostListing.fromJson(item as Map<String, dynamic>))
        .toList();

    return FeedResponse(
      posts: posts,
      currentPage: pagination['current_page'] ?? 1,
      perPage: pagination['per_page'] ?? 15,
      total: pagination['total'] ?? 0,
      lastPage: pagination['last_page'] ?? 1,
    );
  }

  @override
  Future<List<ServiceCategory>> getCategories() async {
    // GET /api/service-categories
    final res = await ApiClient.get('/service-categories');
    if (res['success'] != true) return [];
    final list = res['data'] as List<dynamic>? ?? [];
    return list.map((cat) => ServiceCategory(
      id: cat['id'].toString(),
      label: cat['name']?.toString() ?? '',
      icon: cat['icon'] == 'electrical'
          ? Icons.electrical_services
          : Icons.work_outline,
    )).toList();
  }

  @override
  Future<CategoryWorkerResponse> getCategoryWorkers(
    String categoryId, {
    CategoryWorkerFilters filters = const CategoryWorkerFilters(),
  }) async {
    // GET /api/categories/{categoryId}/workers
    final query = _queryString(filters.toQueryParams());
    final res = await ApiClient.get(
      '/categories/$categoryId/workers?$query',
      requiresAuth: true,
    );

    if (res['success'] == true) {
      final dataBlock = res['data'] as Map<String, dynamic>? ?? {};
      final category = dataBlock['category'] as Map<String, dynamic>? ?? {};
      final rawWorkers = dataBlock['workers'] as List<dynamic>? ?? [];

      // Backend returns workers[] (each with a single nested `job_post`)
      // rather than JobPostListing pairs, so map them here.
      final listings = rawWorkers.map((raw) {
        final workerJson = raw as Map<String, dynamic>;
        final worker = Worker.fromJson(workerJson);
        final postJson = workerJson['job_post'] as Map<String, dynamic>? ?? {};
        final post = JobPost.fromJson(postJson, defaultWorkerId: worker.id);
        return JobPostListing(worker: worker, post: post);
      }).toList();

      return CategoryWorkerResponse(
        categoryId: category['id']?.toString() ?? categoryId,
        categoryName: category['name']?.toString() ?? '',
        listings: listings,
        total: dataBlock['total'] is int
            ? dataBlock['total'] as int
            : int.tryParse(dataBlock['total']?.toString() ?? '0') ?? listings.length,
      );
    }
    return CategoryWorkerResponse(categoryId: categoryId);
  }

  @override
  Future<List<Worker>> getRecentlyViewedWorkers() {
    // GET /api/workers/recent
    throw UnimplementedError();
  }

  @override
  Future<List<Worker>> getTopRatedWorkers() {
    // GET /api/workers?sort=rating
    throw UnimplementedError();
  }

  @override
  Future<Worker?> getWorkerById(String id) async {
    final res = await ApiClient.get('/workers/$id', requiresAuth: true);
    if (res['success'] != true) return null;
    final workerData = res['data'];
    if (workerData != null) return Worker.fromJson(workerData);
    return null;
  }

  @override
  Future<JobPostListing?> getJobPostDetail(String postId) async {
    final res = await ApiClient.get('/posts/$postId', requiresAuth: true);
    if (res['success'] != true) return null;
    final postData = res['data']?['job_post'] ?? res['data'];
    if (postData != null) return JobPostListing.fromJson(postData);
    return null;
  }

  @override
  Future<AuthResult> submitVerificationDocuments({
    required String workerId,
    required String govIdPath,
    required String brgyCertPath,
    required String selfiePath,
  }) async {
    // POST /api/worker/verification/submit
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> updateProfile({
    required String workerId,
    required List<String> categories,
    required List<String> photoPaths,
    required String bio,
  }) async {
    // POST /api/worker/profile
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> createJobPost(JobPost post) async {
    final res = await ApiClient.post(
      '/worker/posts',
      body: {
        'service_category_id': int.tryParse(post.category) ?? 1,
        'title': post.title,
        'description': post.description,
        'rate_amount': post.startingRate,
        'rate_type': post.rateType.apiValue,
        'is_available': post.isAvailable,
      },
      requiresAuth: true,
    );
    if (res['success'] == true) {
      return AuthResult.success(
        message: res['message'] ?? 'Job post created.',
        data: res['data'],
      );
    }
    return AuthResult.failure(
      message: res['message'] ?? 'Failed to create job post.',
      errors: (res['errors'] is Map) ? res['errors'] as Map<String, dynamic> : null,
    );
  }

  @override
  Future<AuthResult> updateJobPost(JobPost post) async {
    final res = await ApiClient.put(
      '/worker/posts/${post.id}',
      body: {
        'title': post.title,
        'description': post.description,
        'rate_amount': post.startingRate,
        'rate_type': post.rateType.apiValue,
        'is_available': post.isAvailable,
      },
      requiresAuth: true,
    );
    if (res['success'] == true) {
      return AuthResult.success(
        message: res['message'] ?? 'Job post updated.',
        data: res['data'],
      );
    }
    return AuthResult.failure(
      message: res['message'] ?? 'Failed to update job post.',
      errors: (res['errors'] is Map) ? res['errors'] as Map<String, dynamic> : null,
    );
  }

  @override
  Future<AuthResult> deleteJobPost(String postId) async {
    final res = await ApiClient.delete('/worker/posts/$postId', requiresAuth: true);
    if (res['success'] == true) {
      return AuthResult.success(message: res['message'] ?? 'Job post deactivated.');
    }
    return AuthResult.failure(message: res['message'] ?? 'Failed to deactivate job post.');
  }

  @override
  Future<List<JobPostImage>> uploadPostImages(String postId, List<String> filePaths) async {
    final res = await ApiClient.postMultipart(
      '/worker/posts/$postId/images',
      fields: const {},
      files: {'images[]': filePaths},
      requiresAuth: true,
    );
    if (res['success'] == true) {
      final rawImages = res['data']?['images'] as List<dynamic>? ?? [];
      return rawImages
          .map((img) => JobPostImage.fromJson(img as Map<String, dynamic>))
          .toList();
    }
    throw Exception(res['message'] ?? 'Failed to upload images');
  }

  @override
  Future<AuthResult> deletePostImage(String postId, String imageId) async {
    final res = await ApiClient.delete(
      '/worker/posts/$postId/images/$imageId',
      requiresAuth: true,
    );
    if (res['success'] == true) {
      return AuthResult.success(message: res['message'] ?? 'Image deleted.');
    }
    return AuthResult.failure(message: res['message'] ?? 'Failed to delete image.');
  }

  @override
  Future<AuthResult> reorderPostImages(String postId, List<String> imageIds) async {
    final intOrStrIds = imageIds.map((id) => int.tryParse(id) ?? id).toList();
    final res = await ApiClient.put(
      '/worker/posts/$postId/images/order',
      body: {'image_ids': intOrStrIds},
      requiresAuth: true,
    );
    if (res['success'] == true) {
      return AuthResult.success(message: res['message'] ?? 'Images reordered.');
    }
    return AuthResult.failure(message: res['message'] ?? 'Failed to reorder images.');
  }
}
