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
  Future<List<JobPost>> getWorkerPosts({bool includeInactive = false}) async {
    // GET /api/worker/posts
    // Response: { success, data: { posts: [ { id, category:{id,name}, title, description,
    //   rate_amount, rate_type, rate_display, is_available, is_active, images[], created_at } ] } }
    final query = includeInactive ? '?include_inactive=true' : '';
    final res = await ApiClient.get('/worker/posts$query', requiresAuth: true);
    if (res['success'] != true) {
      print('[ApiWorkerRepository] getWorkerPosts error: ${res['message']}');
      return [];
    }
    final rawPosts = res['data']?['posts'] as List<dynamic>? ?? [];
    return rawPosts
        .whereType<Map<String, dynamic>>()
        .map((item) => JobPost.fromJson(item))
        .toList();
  }

  @override
  Future<AuthResult> updateAvailability(String availabilityStatus) async {
    // POST /api/worker/profile — only send availability_status
    // Valid values: available | busy | offline
    final res = await ApiClient.post(
      '/worker/profile',
      body: {'availability_status': availabilityStatus},
      requiresAuth: true,
    );
    if (res['success'] == true) {
      return AuthResult.success(
        message: res['message'] ?? 'Availability updated.',
        data: res['data'],
      );
    }
    return AuthResult.failure(
      message: res['message'] ?? 'Failed to update availability.',
      errors: (res['errors'] is Map) ? res['errors'] as Map<String, dynamic> : null,
    );
  }

  @override
  Future<AuthResult> submitVerificationDocuments({
    required String govIdPath,
    required String brgyCertPath,
    required String selfiePath,
    String? skillCertPath,
  }) async {
    // POST /api/worker/verification/submit — multipart/form-data
    // Required: government_id, barangay_certificate, selfie_with_id (images, max 5MB each)
    // Optional: skill_certificate
    // Returns 422 if already pending or approved.
    // Backend returns data.verification_status = "pending" on success.
    final files = <String, List<String>>{
      'government_id': [govIdPath],
      'barangay_certificate': [brgyCertPath],
      'selfie_with_id': [selfiePath],
      if (skillCertPath != null) 'skill_certificate': [skillCertPath],
    };
    final res = await ApiClient.postMultipart(
      '/worker/verification/submit',
      fields: const {},
      files: files,
      requiresAuth: true,
    );
    if (res['success'] == true) {
      return AuthResult.success(
        message: res['message'] ?? 'Documents submitted for review.',
        data: res['data'],
      );
    }
    return AuthResult.failure(
      message: res['message'] ?? 'Failed to submit documents.',
      errors: (res['errors'] is Map) ? res['errors'] as Map<String, dynamic> : null,
    );
  }

  @override
  Future<Map<String, dynamic>?> getVerificationStatus() async {
    // GET /api/worker/verification/status
    // Response: { success, data: { verification_status, trust_tier, remarks, documents[] } }
    // NOTE: real backend uses "remarks" key, NOT "verification_remarks" as docs claim
    final res = await ApiClient.get('/worker/verification/status', requiresAuth: true);
    if (res['success'] != true) return null;
    return res['data'] as Map<String, dynamic>?;
  }

  @override
  Future<List<Worker>> getRecentlyViewedWorkers() {
    // No backend endpoint exists for recently-viewed workers.
    // Return empty list so callers degrade gracefully.
    return Future.value([]);
  }

  @override
  Future<List<Worker>> getTopRatedWorkers() async {
    // GET /api/workers — returns all approved workers sorted by rating on
    // the backend. The worker search screen then applies local filtering.
    final res = await ApiClient.get('/workers', requiresAuth: true);
    if (res['success'] != true) {
      print('[ApiWorkerRepository] getTopRatedWorkers error: ${res['message']}');
      return [];
    }
    final rawWorkers = res['data']?['workers'] as List<dynamic>? ?? [];
    return rawWorkers
        .whereType<Map<String, dynamic>>()
        .map((item) => Worker.fromJson(item))
        .toList();
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
  @override
  Future<AuthResult> updateProfile({
    required String workerId,
    required List<String> categories,
    required List<String> photoPaths,
    required String bio,
  }) async {
    // POST /api/worker/profile — multipart/form-data
    // Accepted fields: bio (string max:1000), availability_status (available|busy|offline),
    //   category_ids[] (integer array), portfolio_photos[] (image files)
    // NOTE: portfolio_photos[] is accepted by validation but SILENTLY DROPPED by the backend
    //   service (WorkerService.php) — no worker_portfolio_photos table exists yet.
    //   We send bio + category_ids only. Photos are ignored by the backend.
    //
    // Category names → IDs: The categories list contains label strings from the local
    // AppConstants.workerCategories list. We must match them to ServiceCategory IDs.
    // Since getCategories() is already wired, we re-use the categories from the API to
    // perform the mapping client-side.
    //
    // The workerId param is ignored — this is a worker-authenticated endpoint.

    // Build multipart fields: bio + category_ids[]
    final fields = <String, String>{};
    if (bio.trim().isNotEmpty) {
      fields['bio'] = bio.trim();
    }

    // Map category labels → integer IDs via GET /api/service-categories
    // Note: categories list contains label strings (e.g. "Plumbing Services").
    // We fetch the categories to get their IDs.
    final catRes = await ApiClient.get('/service-categories');
    final catList = catRes['data'] as List<dynamic>? ?? [];
    final categoryIds = <int>[];
    for (final cat in catList) {
      final name = cat['name']?.toString() ?? '';
      if (categories.any((c) => c.toLowerCase() == name.toLowerCase())) {
        final id = cat['id'];
        if (id is int) categoryIds.add(id);
      }
    }
    for (int i = 0; i < categoryIds.length; i++) {
      fields['category_ids[$i]'] = categoryIds[i].toString();
    }

    // Post multipart — portfolio_photos intentionally omitted (silently dropped by backend)
    final res = await ApiClient.postMultipart(
      '/worker/profile',
      fields: fields,
      files: const {},
      requiresAuth: true,
    );
    if (res['success'] == true) {
      return AuthResult.success(
        message: res['message'] ?? 'Profile updated.',
        data: res['data'],
      );
    }
    return AuthResult.failure(
      message: res['message'] ?? 'Failed to update profile.',
      errors: (res['errors'] is Map) ? res['errors'] as Map<String, dynamic> : null,
    );
  }

  @override
  Future<AuthResult> createJobPost(JobPost post) async {
    // POST /api/worker/posts — JSON body
    // service_category_id must be an integer (the category's numeric ID).
    // Bug-fix: previously sent int.tryParse(post.category) which always returned 1
    // since post.category holds a label string. Now uses post.serviceCategoryId directly.
    final res = await ApiClient.post(
      '/worker/posts',
      body: {
        'service_category_id': post.serviceCategoryId ?? 1,
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
    // PUT /api/worker/posts/{postId}
    // All fields optional. is_active accepted (undocumented in docs but real — used for reactivation).
    final res = await ApiClient.put(
      '/worker/posts/${post.id}',
      body: {
        'title': post.title,
        'description': post.description,
        'rate_amount': post.startingRate,
        'rate_type': post.rateType.apiValue,
        'is_available': post.isAvailable,
        'is_active': post.isActive, // needed to reactivate a soft-deleted post
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
