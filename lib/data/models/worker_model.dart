import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import 'job_post_model.dart';
import 'trust_tier.dart';

enum WorkerAvailability {
  available,
  busy,
  offline
}

enum VerificationStatus {
  notStarted,
  pending,
  verified,
  rejected
}

class Worker {
  final String id;
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
  final bool isAvailable;
  final WorkerAvailability availabilityStatus;
  final String responseTime;
  final List<String> portfolioImages;
  final List<WorkerReview> reviews;

  // New fields for 2.1
  final TrustTier? trustTier;
  final int completedJobsCount;
  final List<JobPost> jobPosts;

  Worker({
    required this.id,
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
    this.isAvailable = true,
    this.availabilityStatus = WorkerAvailability.available,
    this.responseTime = '15 mins',
    this.portfolioImages = const [],
    this.reviews = const [],
    this.trustTier,
    this.completedJobsCount = 0,
    this.jobPosts = const [],
  });

  factory Worker.fromJson(Map<String, dynamic> json, {String? fallbackProfileId}) {
    final rawProfileId = json['worker_profile_id'] ??
        json['id'] ??
        fallbackProfileId ??
        json['user_id'];
    final id = rawProfileId?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final avatarUrl = json['profile_photo_url']?.toString() ??
        json['avatar_url']?.toString() ??
        AppConstants.defaultAvatar;

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
    final distanceLabel = json['distance_label']?.toString() ??
        (json['distance_km'] != null
            ? '~${json['distance_km']} km'
            : (json['distance']?.toString() ?? ''));

    // Rating & reviews
    final rating = (json['average_rating'] is num)
        ? (json['average_rating'] as num).toDouble()
        : double.tryParse(json['average_rating']?.toString() ?? '0') ??
            (json['rating'] is num ? (json['rating'] as num).toDouble() : 0.0);

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
    final specialty = json['specialty']?.toString() ??
        json['category']?['name']?.toString() ??
        'Worker';

    // Job posts if present
    List<JobPost> posts = [];
    if (json['job_posts'] is List) {
      posts = (json['job_posts'] as List)
          .map((p) => JobPost.fromJson(p as Map<String, dynamic>, defaultWorkerId: id))
          .toList();
    }

    return Worker(
      id: id,
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
      isAvailable: json['is_available'] == true ||
          json['availability_status'] == 'available',
      trustTier: parsedTrustTier,
      completedJobsCount: json['completed_jobs'] is int
          ? json['completed_jobs'] as int
          : int.tryParse(json['completed_jobs']?.toString() ?? '0') ?? 0,
      jobPosts: posts,
    );
  }
}

class WorkerReview {
  final String id;
  final String reviewerName;
  final String reviewerAvatar;
  final double rating;
  final String comment;
  final DateTime date;

  WorkerReview({
    required this.id,
    required this.reviewerName,
    required this.reviewerAvatar,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class ServiceCategory {
  final String id;
  final String label;
  final IconData icon;

  ServiceCategory({
    required this.id,
    required this.label,
    required this.icon,
  });
}
