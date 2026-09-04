import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/worker_model.dart';
import '../worker_repository.dart';
import '../../models/auth_result_model.dart';
import '../../models/job_post_model.dart';
import '../../models/trust_tier.dart';
import '../../../core/constants/app_constants.dart';

class MockWorkerRepository implements WorkerRepository {
  final List<JobPost> _mockJobPosts = [
    JobPost(
      id: 'jp1',
      workerId: AppConstants.mockWorkerId,
      category: 'Plumbing',
      title: 'Expert Pipe & Leak Repair',
      description: 'Quick fixing for all household plumbing issues.',
      startingRate: 350,
      rateType: RateType.perSession,
    ),
    JobPost(
      id: 'jp2',
      workerId: AppConstants.mockWorkerId,
      category: 'Cleaning',
      title: 'Deep House Cleaning',
      description: 'Professional cleaning for your home.',
      startingRate: 150,
      rateType: RateType.perHour,
    ),
  ];

  late final List<Worker> _workers = [
    Worker(
      id: AppConstants.mockWorkerId,
      name: 'Ricardo Dalisay',
      avatarUrl: AppConstants.mockWorkerAvatar,
      specialty: 'Master Plumber',
      rating: 4.9,
      reviewCount: 120,
      barangay: AppConstants.defaultBarangay,
      barangayCoordinates: const LatLng(9.9575, 124.3517),
      hourlyRate: 500,
      isVerified: false,
      verificationStatus: VerificationStatus.notStarted,
      tags: ['Pipe Repair', 'Installation'],
      distance: '1.2 km',
      bio: 'With over 8 years of experience in residential plumbing and general maintenance, I specialize in quick, reliable pipe repairs and complete fixture installations. I take pride in leaving every workspace cleaner than I found it.',
      services: ['Pipe Repair', 'Installation', 'Leak Detection', 'Drain Cleaning', 'Water Heater Repair'],
      isAvailable: true,
      responseTime: '15 mins',
      portfolioImages: [
        'https://picsum.photos/seed/job1/400/300',
        'https://picsum.photos/seed/job2/400/300',
        'https://picsum.photos/seed/job3/400/300',
      ],
      reviews: [
        WorkerReview(
          id: 'r1',
          reviewerName: 'Maria Clara',
          reviewerAvatar: 'https://i.pravatar.cc/150?u=maria',
          rating: 5.0,
          comment: 'Excellent service! Fixed our leak in no time. Very professional.',
          date: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
      jobPosts: _mockJobPosts,
      trustTier: null, // Unverified
    ),
    Worker(
      id: 'w2',
      name: 'Maria Santos',
      avatarUrl: 'https://i.pravatar.cc/150?u=w2',
      specialty: 'Licensed Electrician',
      rating: 4.8,
      reviewCount: 85,
      barangay: 'San Isidro',
      barangayCoordinates: const LatLng(9.9312, 124.3121),
      hourlyRate: 600,
      isVerified: true,
      verificationStatus: VerificationStatus.verified,
      tags: ['Wiring', 'Troubleshooting'],
      distance: '2.5 km',
      bio: 'Expert electrician for home and commercial projects. Safe and certified.',
      services: ['Wiring', 'Troubleshooting', 'Panel Upgrades'],
      trustTier: TrustTier.verified,
      isAvailable: true,
    ),
    Worker(
      id: 'w3',
      name: 'Jose Rizal',
      avatarUrl: 'https://i.pravatar.cc/150?u=w3',
      specialty: 'Math Tutor',
      rating: 5.0,
      reviewCount: 42,
      barangay: 'Soledad',
      barangayCoordinates: const LatLng(9.9612, 124.3012),
      hourlyRate: 400,
      tags: ['Algebra', 'Calculus'],
      distance: '3.0 km',
      bio: 'Helping students excel in mathematics for over 5 years.',
      services: ['Algebra', 'Calculus', 'Geometry'],
      isVerified: true,
      verificationStatus: VerificationStatus.verified,
      trustTier: TrustTier.trusted,
      isAvailable: true,
    ),
    Worker(
      id: 'w4',
      name: 'Juana Change',
      avatarUrl: 'https://i.pravatar.cc/150?u=w4',
      specialty: 'Home Cleaner',
      rating: 4.5,
      reviewCount: 56,
      barangay: 'Abachanan',
      barangayCoordinates: const LatLng(9.9145, 124.3411),
      hourlyRate: 300,
      tags: ['Deep Cleaning', 'Organization'],
      distance: '5.5 km',
      bio: 'Passionate about creating clean and organized living spaces.',
      services: ['Deep Cleaning', 'Organization', 'Post-Construction Cleaning'],
      isVerified: true,
      verificationStatus: VerificationStatus.verified,
      trustTier: TrustTier.verified,
      isAvailable: false,
    ),
    Worker(
      id: 'w5',
      name: 'Simulated Rejected',
      avatarUrl: 'https://i.pravatar.cc/150?u=w5',
      specialty: 'Handyman',
      rating: 4.0,
      reviewCount: 5,
      barangay: AppConstants.defaultBarangay,
      barangayCoordinates: const LatLng(9.9575, 124.3517),
      hourlyRate: 200,
      isVerified: false,
      verificationStatus: VerificationStatus.rejected,
      rejectionReason: 'The uploaded ID was blurry and unreadable. Please ensure the document is clearly visible and well-lit.',
      tags: ['Repairs'],
      distance: '0.5 km',
      trustTier: null,
      isAvailable: true,
    ),
    Worker(
      id: 'w6',
      name: 'Flagged Worker',
      avatarUrl: 'https://i.pravatar.cc/150?u=w6',
      specialty: 'Painter',
      rating: 3.5,
      reviewCount: 10,
      barangay: AppConstants.defaultBarangay,
      hourlyRate: 300,
      isVerified: true,
      verificationStatus: VerificationStatus.verified,
      tags: ['Painting'],
      distance: '1.0 km',
      trustTier: TrustTier.flagged,
    ),
    Worker(
      id: 'w7',
      name: 'Revoked Worker',
      avatarUrl: 'https://i.pravatar.cc/150?u=w7',
      specialty: 'Mason',
      rating: 2.0,
      reviewCount: 2,
      barangay: AppConstants.defaultBarangay,
      hourlyRate: 450,
      isVerified: true,
      verificationStatus: VerificationStatus.verified,
      tags: ['Masonry'],
      distance: '1.5 km',
      trustTier: TrustTier.revoked,
    ),
  ];

  List<Worker> _getFilteredAndSortedWorkers() {
    return _workers
        .where((w) => w.trustTier != TrustTier.flagged && w.trustTier != TrustTier.revoked)
        .toList()
      ..sort((a, b) => b.trustTier.sortPriority.compareTo(a.trustTier.sortPriority));
  }

  @override
  Future<List<ServiceCategory>> getCategories() async {
    return [
      ServiceCategory(id: '1', label: 'Electrical', icon: Icons.electrical_services),
      ServiceCategory(id: '2', label: 'Plumbing', icon: Icons.plumbing),
      ServiceCategory(id: '3', label: 'Tutoring', icon: Icons.school),
      ServiceCategory(id: '4', label: 'Cleaning', icon: Icons.cleaning_services),
      ServiceCategory(id: '5', label: 'Laundry', icon: Icons.local_laundry_service),
      ServiceCategory(id: '6', label: 'Gardening', icon: Icons.yard),
    ];
  }

  @override
  Future<List<Worker>> getTopRatedWorkers() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _getFilteredAndSortedWorkers();
  }

  @override
  Future<List<Worker>> getRecentlyViewedWorkers() async {
    final list = _getFilteredAndSortedWorkers();
    return list.isNotEmpty ? [list.first] : [];
  }

  @override
  Future<Worker?> getWorkerById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      return _workers.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<AuthResult> submitVerificationDocuments({
    required String workerId,
    required String govIdPath,
    required String brgyCertPath,
    required String selfiePath,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    final index = _workers.indexWhere((w) => w.id == workerId);
    if (index != -1) {
      final old = _workers[index];
      _workers[index] = Worker(
        id: old.id,
        name: old.name,
        avatarUrl: old.avatarUrl,
        specialty: old.specialty,
        rating: old.rating,
        reviewCount: old.reviewCount,
        barangay: old.barangay,
        barangayCoordinates: old.barangayCoordinates,
        hourlyRate: old.hourlyRate,
        isVerified: false,
        verificationStatus: VerificationStatus.pending,
        tags: old.tags,
        distance: old.distance,
        bio: old.bio,
        services: old.services,
        isAvailable: old.isAvailable,
        availabilityStatus: old.availabilityStatus,
        responseTime: old.responseTime,
        portfolioImages: old.portfolioImages,
        reviews: old.reviews,
        trustTier: old.trustTier,
        completedJobsCount: old.completedJobsCount,
        jobPosts: old.jobPosts,
      );
    }
    return AuthResult.success(message: 'Verification submitted.');
  }

  @override
  Future<AuthResult> updateProfile({
    required String workerId,
    required List<String> categories,
    required List<String> photoPaths,
    required String bio,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final index = _workers.indexWhere((w) => w.id == workerId);
    if (index != -1) {
      final old = _workers[index];
      _workers[index] = Worker(
        id: old.id,
        name: old.name,
        avatarUrl: old.avatarUrl,
        specialty: old.specialty,
        rating: old.rating,
        reviewCount: old.reviewCount,
        barangay: old.barangay,
        barangayCoordinates: old.barangayCoordinates,
        hourlyRate: old.hourlyRate,
        isVerified: old.isVerified,
        verificationStatus: old.verificationStatus,
        tags: categories, // Using categories as tags/specialties for now
        distance: old.distance,
        bio: bio,
        services: categories,
        isAvailable: old.isAvailable,
        availabilityStatus: old.availabilityStatus,
        responseTime: old.responseTime,
        portfolioImages: photoPaths,
        reviews: old.reviews,
        trustTier: old.trustTier,
        completedJobsCount: old.completedJobsCount,
        jobPosts: old.jobPosts,
      );
    }
    return AuthResult.success(message: 'Profile updated successfully!');
  }

  @override
  Future<AuthResult> createJobPost(JobPost post) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockJobPosts.add(post);
    return AuthResult.success(message: 'Job post created successfully!');
  }

  @override
  Future<AuthResult> updateJobPost(JobPost post) async {
    await Future.delayed(const Duration(seconds: 1));
    final index = _mockJobPosts.indexWhere((jp) => jp.id == post.id);
    if (index != -1) {
      _mockJobPosts[index] = post;
    }
    return AuthResult.success(message: 'Job post updated successfully!');
  }

  @override
  Future<AuthResult> deleteJobPost(String postId) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockJobPosts.removeWhere((jp) => jp.id == postId);
    return AuthResult.success(message: 'Job post deleted successfully!');
  }
}
