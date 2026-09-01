import 'worker_model.dart';

enum RateType {
  perHour,
  perDay,
  perWeek,
  perMonth,
  perSession,
  perProject,
}

extension RateTypeExtension on RateType {
  String get label {
    switch (this) {
      case RateType.perHour: return 'Per Hour';
      case RateType.perDay: return 'Per Day';
      case RateType.perWeek: return 'Per Week';
      case RateType.perMonth: return 'Per Month';
      case RateType.perSession: return 'Per Session';
      case RateType.perProject: return 'Per Project';
    }
  }

  String get shortLabel {
    switch (this) {
      case RateType.perHour: return '/hr';
      case RateType.perDay: return '/day';
      case RateType.perWeek: return '/wk';
      case RateType.perMonth: return '/mo';
      case RateType.perSession: return '/session';
      case RateType.perProject: return '/project';
    }
  }
}

class JobPost {
  final String id;
  final String workerId;
  final String category;
  final String title;
  final String description;
  final double startingRate;
  final RateType rateType;
  final bool isAvailable;

  JobPost({
    required this.id,
    required this.workerId,
    required this.category,
    required this.title,
    required this.description,
    required this.startingRate,
    required this.rateType,
    this.isAvailable = true,
  });

  JobPost copyWith({
    String? title,
    String? description,
    double? startingRate,
    RateType? rateType,
    bool? isAvailable,
  }) {
    return JobPost(
      id: id,
      workerId: workerId,
      category: category,
      title: title ?? this.title,
      description: description ?? this.description,
      startingRate: startingRate ?? this.startingRate,
      rateType: rateType ?? this.rateType,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

/// A view model representing a specific job post listing in the feed.
class JobPostListing {
  final Worker worker;
  final JobPost post;

  JobPostListing({
    required this.worker,
    required this.post,
  });
}
