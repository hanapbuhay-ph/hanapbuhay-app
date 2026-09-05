import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../services/secure_storage_service.dart';
import '../../models/worker_model.dart';
import '../worker_repository.dart';
import '../../models/auth_result_model.dart';
import '../../models/job_post_model.dart';

class ApiWorkerRepository implements WorkerRepository {
  final String baseUrl = AppConstants.apiBaseUrl;
  final SecureStorageService _storage = SecureStorageService();

  @override
  Future<List<ServiceCategory>> getCategories() async {
    // GET /api/service-categories
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/service-categories'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List<dynamic>? ?? [];
        return list.map((cat) => ServiceCategory(
          id: cat['id'].toString(),
          label: cat['name']?.toString() ?? '',
          icon: cat['icon'] == 'electrical'
              ? Icons.electrical_services
              : Icons.work_outline,
        )).toList();
      }
    } catch (_) {}
    return [];
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
    try {
      final token = await _storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/workers/$id'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final workerData = data['data'];
        if (workerData != null) {
          return Worker.fromJson(workerData);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<JobPostListing?> getJobPostDetail(String postId) async {
    try {
      final token = await _storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final postData = data['data']?['job_post'] ?? data['data'];
        if (postData != null) {
          return JobPostListing.fromJson(postData);
        }
      } else if (response.statusCode == 404) {
        return null;
      }
    } catch (e) {
      return null;
    }
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
    try {
      final token = await _storage.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/worker/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'service_category_id': int.tryParse(post.category) ?? 1,
          'title': post.title,
          'description': post.description,
          'rate_amount': post.startingRate,
          'rate_type': post.rateType.apiValue,
          'is_available': post.isAvailable,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.success(
          message: data['message'] ?? 'Job post created.',
          data: data['data'],
        );
      } else {
        return AuthResult.failure(
          message: data['message'] ?? 'Failed to create job post.',
          errors: data['errors'],
        );
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  @override
  Future<AuthResult> updateJobPost(JobPost post) async {
    try {
      final token = await _storage.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/worker/posts/${post.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': post.title,
          'description': post.description,
          'rate_amount': post.startingRate,
          'rate_type': post.rateType.apiValue,
          'is_available': post.isAvailable,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return AuthResult.success(
          message: data['message'] ?? 'Job post updated.',
          data: data['data'],
        );
      } else {
        return AuthResult.failure(
          message: data['message'] ?? 'Failed to update job post.',
          errors: data['errors'],
        );
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  @override
  Future<AuthResult> deleteJobPost(String postId) async {
    try {
      final token = await _storage.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/worker/posts/$postId'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return AuthResult.success(message: data['message'] ?? 'Job post deactivated.');
      } else {
        return AuthResult.failure(message: data['message'] ?? 'Failed to deactivate job post.');
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  @override
  Future<List<JobPostImage>> uploadPostImages(String postId, List<String> filePaths) async {
    try {
      final token = await _storage.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/worker/posts/$postId/images'),
      );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      for (final path in filePaths) {
        request.files.add(await http.MultipartFile.fromPath('images[]', path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawImages = data['data']?['images'] as List<dynamic>? ?? [];
        return rawImages
            .map((img) => JobPostImage.fromJson(img as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to upload images');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResult> deletePostImage(String postId, String imageId) async {
    try {
      final token = await _storage.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/worker/posts/$postId/images/$imageId'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return AuthResult.success(message: data['message'] ?? 'Image deleted.');
      } else {
        return AuthResult.failure(message: data['message'] ?? 'Failed to delete image.');
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }

  @override
  Future<AuthResult> reorderPostImages(String postId, List<String> imageIds) async {
    try {
      final token = await _storage.getToken();
      final intOrStrIds = imageIds.map((id) => int.tryParse(id) ?? id).toList();
      final response = await http.put(
        Uri.parse('$baseUrl/worker/posts/$postId/images/order'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'image_ids': intOrStrIds}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return AuthResult.success(message: data['message'] ?? 'Images reordered.');
      } else {
        return AuthResult.failure(message: data['message'] ?? 'Failed to reorder images.');
      }
    } catch (e) {
      return AuthResult.failure(message: 'Network error: $e');
    }
  }
}
