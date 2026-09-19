import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/service_category_icons.dart';
import '../../models/worker_model.dart';
import '../worker_repository.dart';
import '../../models/auth_result_model.dart';
import '../../models/job_post_model.dart';

class ApiWorkerRepository implements WorkerRepository {
  String _queryString(Map<String, String> p) => p.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');

  @override
  Future<FeedResponse> getFeed(FeedFilters f) async {
    final res = await ApiClient.get('/feed?${_queryString(f.toQueryParams())}', requiresAuth: true);
    if (res['success'] != true) return const FeedResponse(posts: [], currentPage: 1, perPage: 15, total: 0, lastPage: 1);
    final p = (res['data']?['posts'] as List<dynamic>? ?? []).map((i) => JobPostListing.fromJson(i)).toList();
    final pag = res['data']?['pagination'] as Map<String, dynamic>? ?? {};
    return FeedResponse(posts: p, currentPage: pag['current_page'] ?? 1, perPage: pag['per_page'] ?? 15, total: pag['total'] ?? 0, lastPage: pag['last_page'] ?? 1);
  }

  @override
  Future<CategoryWorkerResponse> getCategoryWorkers(String c, {CategoryWorkerFilters filters = const CategoryWorkerFilters()}) async {
    final res = await ApiClient.get('/categories/$c/workers?${_queryString(filters.toQueryParams())}', requiresAuth: true);
    if (res['success'] == true) {
        final d = res['data'] as Map<String, dynamic>? ?? {};
        final list = (d['workers'] as List<dynamic>? ?? []).map((r) => JobPostListing(worker: Worker.fromJson(r), post: JobPost.fromJson(r['job_post'] ?? {}, defaultWorkerId: r['worker_profile_id']?.toString()))).toList();
        return CategoryWorkerResponse(categoryId: c, listings: list);
    }
    return CategoryWorkerResponse(categoryId: c);
  }

  @override
  Future<List<JobPost>> getWorkerPosts({bool includeInactive = false}) async {
    final res = await ApiClient.get('/worker/posts?include_inactive=${includeInactive ? 1 : 0}', requiresAuth: true);
    return res['success'] == true ? (res['data']?['posts'] as List<dynamic>? ?? []).map((p) => JobPost.fromJson(p)).toList() : [];
  }

  @override
  Future<AuthResult> submitVerificationDocuments({required String govIdPath, required String brgyCertPath, required String selfiePath, String? skillCertPath}) async {
    final Map<String, List<String>> f = {
        'government_id': [govIdPath],
        'barangay_certificate': [brgyCertPath],
        'selfie_with_id': [selfiePath],
        if (skillCertPath != null) 'skill_certificate': [skillCertPath]
    };
    final res = await ApiClient.postMultipart('/worker/verification/submit', fields: {}, files: f, requiresAuth: true);
    return res['success'] == true
      ? AuthResult.success(message: res['message'])
      : AuthResult.failure(
        message: res['message'] ?? 'Failed',
        errors: res['errors'] is Map
          ? (res['errors'] as Map).map((key, value) => MapEntry(key.toString(), value))
          : null,
        );
  }

  @override
  Future<Map<String, dynamic>?> getVerificationStatus() async {
    final res = await ApiClient.get('/worker/verification/status', requiresAuth: true);
    if (res['success'] != true) {
      throw Exception(res['message']?.toString() ?? 'Unable to load verification status.');
    }
    return res['data'] as Map<String, dynamic>?;
  }

  @override
  Future<AuthResult> updateAvailability(String s) async {
    final res = await ApiClient.post('/worker/profile', body: {'availability_status': s}, requiresAuth: true);
    return res['success'] == true ? AuthResult.success(message: res['message']) : AuthResult.failure(message: res['message']);
  }

  @override
  Future<List<Worker>> getTopRatedWorkers() async {
    final res = await ApiClient.get('/workers/top-rated', requiresAuth: true);
    return res['success'] == true ? (res['data'] as List<dynamic>? ?? []).map((w) => Worker.fromJson(w)).toList() : [];
  }

  @override
  Future<List<Worker>> getRecentlyViewedWorkers() async => [];

  @override
  Future<List<ServiceCategory>> getCategories() async {
    final res = await ApiClient.get('/service-categories');
    return res['success'] == true
        ? (res['data'] as List<dynamic>? ?? [])
            .map((c) => ServiceCategory(
              id: c['id'].toString(),
              label: c['name'] ?? '',
              icon: ServiceCategoryIcons.fromKey(
                c['icon']?.toString() ?? c['name']?.toString(),
              ),
            ))
            .toList()
        : [];
  }

  @override
  Future<Worker?> getWorkerById(String id) async {
    final res = await ApiClient.get('/workers/$id', requiresAuth: true);
    return res['success'] == true ? Worker.fromJson(res['data']?['worker'] ?? res['data']) : null;
  }


  @override
  Future<JobPostListing?> getJobPostDetail(String postId) async {
    final res = await ApiClient.get('/posts/$postId', requiresAuth: true);
    if (res['success'] != true) return null;
    final d = res['data']?['job_post'] ?? res['data'];
    return d != null ? JobPostListing.fromJson(d) : null;
  }

  @override
  Future<AuthResult> updateProfile({required String workerId, required List<String> categories, required List<String> photoPaths, required String bio}) async {
    final res = await ApiClient.put('/worker/profile/$workerId', body: {'categories': categories, 'bio': bio, 'photos': photoPaths}, requiresAuth: true);
    return res['success'] == true ? AuthResult.success(message: res['message']) : AuthResult.failure(message: res['message']);
  }

  @override
  Future<AuthResult> createJobPost(JobPost p) async {
    final res = await ApiClient.post('/worker/posts', body: p.toJson(), requiresAuth: true);
    return res['success'] == true ? AuthResult.success(message: res['message'], data: res['data']) : AuthResult.failure(message: res['message']);
  }

  @override
  Future<AuthResult> updateJobPost(JobPost p) async {
    final res = await ApiClient.put('/worker/posts/${p.id}', body: p.toJson(), requiresAuth: true);
    return res['success'] == true ? AuthResult.success(message: res['message'], data: res['data']) : AuthResult.failure(message: res['message']);
  }

  @override
  Future<AuthResult> deleteJobPost(String id) async {
    final res = await ApiClient.delete('/worker/posts/$id', requiresAuth: true);
    return res['success'] == true ? AuthResult.success(message: res['message']) : AuthResult.failure(message: res['message']);
  }

  @override
  Future<List<JobPostImage>> uploadPostImages(String id, List<String> p) async {
    final res = await ApiClient.postMultipart('/worker/posts/$id/images', fields: {}, files: {'images[]': p}, requiresAuth: true);
    return res['success'] == true ? (res['data']?['images'] as List<dynamic>? ?? []).map((i) => JobPostImage.fromJson(i)).toList() : [];
  }

  @override
  Future<AuthResult> deletePostImage(String p, String i) async {
    final res = await ApiClient.delete('/worker/posts/$p/images/$i', requiresAuth: true);
    return res['success'] == true ? AuthResult.success(message: res['message']) : AuthResult.failure(message: res['message']);
  }

  @override
  Future<AuthResult> reorderPostImages(String p, List<String> i) async {
    final res = await ApiClient.put('/worker/posts/$p/images/order', body: {'image_ids': i}, requiresAuth: true);
    return res['success'] == true ? AuthResult.success(message: res['message']) : AuthResult.failure(message: res['message']);
  }
}
