import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/repositories/worker_repository.dart';
import '../data/models/worker_model.dart';
import '../data/models/auth_result_model.dart';
import '../data/models/job_post_model.dart';
import '../data/models/trust_tier.dart';
import '../data/models/barangay_model.dart';
import '../core/utils/distance_utils.dart';

class WorkerProvider extends ChangeNotifier {
  final WorkerRepository _repository;

  WorkerProvider(this._repository);

  // Filter States
  String _quickFilter = 'All'; // 'All', 'Verified', 'Unverified'
  List<String> _selectedCategories = [];
  String? _selectedBarangay;
  List<RateType> _selectedRateTypes = [];
  bool _onlyAvailableNow = false;

  String get quickFilter => _quickFilter;
  List<String> get selectedCategories => _selectedCategories;
  String? get selectedBarangay => _selectedBarangay;
  List<RateType> get selectedRateTypes => _selectedRateTypes;
  bool get onlyAvailableNow => _onlyAvailableNow;

  int get activeAdvancedFilterCount {
    int count = 0;
    if (_selectedCategories.isNotEmpty) count++;
    if (_selectedBarangay != null) count++;
    if (_selectedRateTypes.isNotEmpty) count++;
    if (_onlyAvailableNow) count++;
    return count;
  }

  void setQuickFilter(String value) {
    _quickFilter = value;
    notifyListeners();
  }

  void setAdvancedFilters({
    List<String>? categories,
    String? barangay,
    List<RateType>? rateTypes,
    bool? onlyAvailable,
  }) {
    if (categories != null) _selectedCategories = categories;
    _selectedBarangay = barangay;
    if (rateTypes != null) _selectedRateTypes = rateTypes;
    if (onlyAvailable != null) _onlyAvailableNow = onlyAvailable;
    notifyListeners();
  }

  void resetFilters() {
    _quickFilter = 'All';
    _selectedCategories = [];
    _selectedBarangay = null;
    _selectedRateTypes = [];
    _onlyAvailableNow = false;
    notifyListeners();
  }

  Future<List<ServiceCategory>> getCategories() => _repository.getCategories();
  
  Future<List<JobPostListing>> getFilteredWorkers({String? userBarangayName}) async {
    final allWorkers = await _repository.getTopRatedWorkers();
    
    // 1. Haversine Distance computation if user location is available
    Barangay? userBarangay;
    if (userBarangayName != null) {
      userBarangay = Barangay.trinidadBarangays.firstWhere(
        (b) => b.name == userBarangayName,
        orElse: () => Barangay.trinidadBarangays[12], // Default to Poblacion
      );
    }

    // 2. Flatten Workers into JobPostListings (One card per post per worker)
    final List<JobPostListing> listings = [];
    for (var worker in allWorkers) {
      if (worker.jobPosts.isEmpty) {
        // Fallback for workers with no explicit job posts (show their legacy profile as a generic post)
        listings.add(JobPostListing(
          worker: worker,
          post: JobPost(
            id: 'legacy-${worker.id}',
            workerId: worker.id,
            category: worker.specialty,
            title: '${worker.specialty} Services',
            description: worker.bio,
            startingRate: worker.hourlyRate,
            rateType: RateType.perHour,
            isAvailable: worker.isAvailable,
          ),
        ));
      } else {
        for (var post in worker.jobPosts) {
          listings.add(JobPostListing(worker: worker, post: post));
        }
      }
    }

    // 3. Filter Pipeline
    final filtered = listings.where((listing) {
      final worker = listing.worker;
      final post = listing.post;

      // Quick Filter (Trust Tier)
      if (_quickFilter == 'Verified') {
        if (worker.trustTier != TrustTier.verified && worker.trustTier != TrustTier.trusted) return false;
      } else if (_quickFilter == 'Unverified') {
        if (worker.trustTier != null) return false;
      }

      // Advanced Filters
      if (_selectedCategories.isNotEmpty) {
        if (!_selectedCategories.any((cat) => post.category.contains(cat) || worker.specialty.contains(cat))) return false;
      }

      if (_selectedBarangay != null) {
        if (worker.barangay != _selectedBarangay) return false;
      }

      if (_selectedRateTypes.isNotEmpty) {
        if (!_selectedRateTypes.contains(post.rateType)) return false;
      }

      if (_onlyAvailableNow) {
        if (!post.isAvailable) return false;
      }

      return true;
    }).toList();

    // 4. Sort Pipeline: Distance -> Tier -> Rating
    filtered.sort((a, b) {
      // 1. Distance (nearest first)
      if (userBarangay != null) {
        final distA = DistanceUtils.calculateDistance(userBarangay.center, a.worker.barangayCoordinates ?? const LatLng(0,0));
        final distB = DistanceUtils.calculateDistance(userBarangay.center, b.worker.barangayCoordinates ?? const LatLng(0,0));
        final distComp = distA.compareTo(distB);
        if (distComp != 0) return distComp;
      }

      // 2. Trust Tier (Trusted -> Verified -> Unverified)
      final tierComp = b.worker.trustTier.sortPriority.compareTo(a.worker.trustTier.sortPriority);
      if (tierComp != 0) return tierComp;

      // 3. Rating (Higher first)
      return b.worker.rating.compareTo(a.worker.rating);
    });

    return filtered;
  }

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

  Future<AuthResult> createJobPost(JobPost post) async {
    final result = await _repository.createJobPost(post);
    notifyListeners();
    return result;
  }

  Future<AuthResult> updateJobPost(JobPost post) async {
    final result = await _repository.updateJobPost(post);
    notifyListeners();
    return result;
  }

  Future<AuthResult> deleteJobPost(String postId) async {
    final result = await _repository.deleteJobPost(postId);
    notifyListeners();
    return result;
  }

  Future<JobPostListing?> getJobPostDetail(String postId) =>
      _repository.getJobPostDetail(postId);

  Future<List<JobPostImage>> uploadPostImages(
      String postId, List<String> filePaths) async {
    final result = await _repository.uploadPostImages(postId, filePaths);
    notifyListeners();
    return result;
  }

  Future<AuthResult> deletePostImage(String postId, String imageId) async {
    final result = await _repository.deletePostImage(postId, imageId);
    notifyListeners();
    return result;
  }

  Future<AuthResult> reorderPostImages(
      String postId, List<String> imageIds) async {
    final result = await _repository.reorderPostImages(postId, imageIds);
    notifyListeners();
    return result;
  }
}
