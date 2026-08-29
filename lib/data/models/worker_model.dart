import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final String distance; // Mocked for now

  // New fields for 1.3
  final String bio;
  final List<String> services;
  final bool isAvailable;
  final WorkerAvailability availabilityStatus;
  final String responseTime;
  final List<String> portfolioImages;
  final List<WorkerReview> reviews;

  // New fields for 2.1
  final String trustTier;
  final int completedJobsCount;

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
    this.trustTier = 'Standard',
    this.completedJobsCount = 0,
  });
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
