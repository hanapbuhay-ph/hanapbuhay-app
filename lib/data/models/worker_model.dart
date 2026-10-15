import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import 'job_post_model.dart';
import 'trust_tier.dart';

enum WorkerAvailability { available, busy, offline }

enum VerificationStatus { notStarted, pending, verified, rejected }

class Worker {
  final String id;
  final String? userId;
  final String name;
  final String avatarUrl;
  final String specialty;
  final double rating;
  final int reviewCount;
  final String barangay;
  final LatLng? barangayCoordinates;
  final double hourlyRate;
  final bool isVerified;
  final VerificationStatus verificationStatus;
  final String? rejectionReason;
  final List<String> tags;
  final String distance; // Mocked or calculated

  // New fields for 1.3
  final String bio;
  final List<String> services;
  final List<String> serviceCategoryIds;
  final bool isAvailable;
  final bool isOnline;
  final WorkerAvailability availabilityStatus;
  final String responseTime;
  final List<String> portfolioImages;
  final List<String> portfolioPhotoIds;
  final List<WorkerReview> reviews;

  // New fields for 2.1
  final TrustTier? trustTier;
  final int completedJobsCount;
  final List<JobPost> jobPosts;

  Worker({
    required this.id,
    this.userId,
    required this.name,
    required this.avatarUrl,
    required this.specialty,
    required this.rating,
    this.reviewCount = 0,
    required this.barangay,
    this.barangayCoordinates,
    required this.hourlyRate,
    required this.isVerified,
    this.verificationStatus = VerificationStatus.notStarted,
    this.rejectionReason,
    required this.tags,
    required this.distance,
    this.bio = '',
    this.services = const [],
    this.serviceCategoryIds = const [],
    this.isAvailable = true,
    this.isOnline = false,
    this.availabilityStatus = WorkerAvailability.available,
    this.responseTime = '15 mins',
    this.portfolioImages = const [],
    this.portfolioPhotoIds = const [],
    this.reviews = const [],
    this.trustTier,
    this.completedJobsCount = 0,
    this.jobPosts = const [],
  });

  factory Worker.fromJson(
    Map<String, dynamic> json, {
    String? fallbackProfileId,
  }) {
    final rawProfileId =
        json['worker_profile_id'] ??
        json['id'] ??
        fallbackProfileId ??
        json['user_id'];
    final id = rawProfileId?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final rawAvatar =
        json['profile_photo_url']?.toString() ?? json['avatar_url']?.toString();
    final avatarUrl = AppConstants.getPhotoUrl(rawAvatar);

    // Trust tier
    TrustTier? parsedTrustTier;
    final rawTier = json['trust_tier']?.toString().toLowerCase();
    if (rawTier == 'trusted') {
      parsedTrustTier = TrustTier.trusted;
    } else if (rawTier == 'verified') {
      parsedTrustTier = TrustTier.verified;
    } else if (rawTier == 'flagged') {
      parsedTrustTier = TrustTier.flagged;
    } else if (rawTier == 'revoked') {
      parsedTrustTier = TrustTier.revoked;
    }

    // Barangay
    final barangayVal = json['barangay'];
    final barangay = barangayVal is Map
        ? (barangayVal['name'] ?? '')
        : (barangayVal?.toString() ?? '');

    // Distance
    final distanceLabel =
        json['distance_label']?.toString() ??
        (json['distance_km'] != null
            ? '~${json['distance_km']} km'
            : (json['distance']?.toString() ?? ''));

    // Rating & reviews
    final rating = (json['average_rating'] is num)
        ? (json['average_rating'] as num).toDouble()
        : double.tryParse(json['average_rating']?.toString() ?? '0') ??
              (json['rating'] is num
                  ? (json['rating'] as num).toDouble()
                  : 0.0);

    final reviewCount = (json['total_reviews'] is int)
        ? json['total_reviews'] as int
        : int.tryParse(json['total_reviews']?.toString() ?? '0') ??
              (json['review_count'] is int ? json['review_count'] as int : 0);

    // Verification status
    final rawVerif = json['verification_status']?.toString().toLowerCase();
    VerificationStatus verifStatus = VerificationStatus.notStarted;
    if (rawVerif == 'approved' || rawVerif == 'verified') {
      verifStatus = VerificationStatus.verified;
    } else if (rawVerif == 'pending') {
      verifStatus = VerificationStatus.pending;
    } else if (rawVerif == 'rejected') {
      verifStatus = VerificationStatus.rejected;
    }

    // Specialty / category
    final specialty =
        json['specialty']?.toString() ??
        json['category']?['name']?.toString() ??
        'Worker';

    // Job posts if present
    List<JobPost> posts = [];
    if (json['job_posts'] is List) {
      posts = (json['job_posts'] as List)
          .map(
            (p) => JobPost.fromJson(
              p as Map<String, dynamic>,
              defaultWorkerId: id,
            ),
          )
          .toList();
    }

    // Reviews if present (Worker Profile - GET /api/workers/{id})
    List<WorkerReview> reviews = [];
    if (json['reviews'] is List) {
      reviews = (json['reviews'] as List)
          .whereType<Map<String, dynamic>>()
          .map((r) => WorkerReview.fromJson(r))
          .toList();
    }

    final rawCategories = json['categories'] as List<dynamic>? ?? const [];
    final services = rawCategories
        .map(
          (category) => category is Map
              ? category['name']?.toString() ?? ''
              : category.toString(),
        )
        .where((name) => name.isNotEmpty)
        .toList();
    final serviceCategoryIds = rawCategories
        .whereType<Map>()
        .map((category) => category['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final rawPortfolioPhotos =
        json['portfolio_photos'] as List<dynamic>? ?? const [];
    final portfolioPhotos = rawPortfolioPhotos.whereType<Map>().toList();

    return Worker(
      id: id,
      userId: json['user_id']?.toString(),
      name: name,
      avatarUrl: avatarUrl,
      specialty: specialty,
      rating: rating,
      reviewCount: reviewCount,
      barangay: barangay,
      hourlyRate: (json['hourly_rate'] is num)
          ? (json['hourly_rate'] as num).toDouble()
          : double.tryParse(json['hourly_rate']?.toString() ?? '0') ?? 0.0,
      isVerified: verifStatus == VerificationStatus.verified,
      verificationStatus: verifStatus,
      tags: (json['tags'] is List) ? List<String>.from(json['tags']) : const [],
      distance: distanceLabel,
      bio: json['bio']?.toString() ?? '',
      services: services,
      serviceCategoryIds: serviceCategoryIds,
      portfolioImages: portfolioPhotos
          .map(
            (photo) => AppConstants.getPhotoUrl(
              photo['url']?.toString() ?? photo['file_path']?.toString(),
            ),
          )
          .toList(),
      portfolioPhotoIds: portfolioPhotos
          .map((photo) => photo['id']?.toString() ?? '')
          .toList(),
      isAvailable: json['availability_status'] != null
          ? json['availability_status'] == 'available'
          : json['is_available'] == true || json['is_available'] == 1,
      isOnline: json['is_online'] == true,
      availabilityStatus: _parseAvailabilityStatus(
        json['availability_status']?.toString(),
      ),
      trustTier: parsedTrustTier,
      completedJobsCount: json['completed_jobs'] is int
          ? json['completed_jobs'] as int
          : int.tryParse(json['completed_jobs']?.toString() ?? '0') ?? 0,
      jobPosts: posts,
      reviews: reviews,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'profile_photo_url': avatarUrl,
      'specialty': specialty,
      'average_rating': rating,
      'total_reviews': reviewCount,
      'barangay': barangay,
      'hourly_rate': hourlyRate,
      'verification_status': switch (verificationStatus) {
        VerificationStatus.notStarted => 'not_started',
        VerificationStatus.pending => 'pending',
        VerificationStatus.verified => 'verified',
        VerificationStatus.rejected => 'rejected',
      },
      'trust_tier': trustTier?.name,
      'completed_jobs': completedJobsCount,
      'tags': tags,
      'distance_label': distance,
      'bio': bio,
      'is_available': isAvailable,
      'availability_status': availabilityStatus.name,
    };
  }

  static WorkerAvailability _parseAvailabilityStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'busy':
        return WorkerAvailability.busy;
      case 'offline':
        return WorkerAvailability.offline;
      default:
        return WorkerAvailability.available;
    }
  }
}

class WorkerReview {
  final String id;
  final String? bookingId;
  final String? reviewerId;
  final String reviewerName;
  final String? reviewerAvatar;
  final double rating;
  final String comment;
  final DateTime date;

  WorkerReview({
    required this.id,
    this.bookingId,
    this.reviewerId,
    required this.reviewerName,
    required this.reviewerAvatar,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory WorkerReview.fromJson(Map<String, dynamic> json) {
    return WorkerReview(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString(),
      reviewerId: json['rated_by_user_id']?.toString(),
      reviewerName: json['rated_by_name']?.toString() ?? '',
      reviewerAvatar: AppConstants.getOptionalPhotoUrl(
        json['reviewer_avatar_url']?.toString() ??
            json['avatar_url']?.toString(),
      ),
      rating: (json['score'] is num)
          ? (json['score'] as num).toDouble()
          : double.tryParse(json['score']?.toString() ?? '0') ?? 0.0,
      comment: json['comment']?.toString() ?? '',
      date:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
