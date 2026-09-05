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
      case RateType.perHour:
        return 'Per Hour';
      case RateType.perDay:
        return 'Per Day';
      case RateType.perWeek:
        return 'Per Week';
      case RateType.perMonth:
        return 'Per Month';
      case RateType.perSession:
        return 'Per Session';
      case RateType.perProject:
        return 'Per Project';
    }
  }

  String get shortLabel {
    switch (this) {
      case RateType.perHour:
        return '/hr';
      case RateType.perDay:
        return '/day';
      case RateType.perWeek:
        return '/wk';
      case RateType.perMonth:
        return '/mo';
      case RateType.perSession:
        return '/session';
      case RateType.perProject:
        return '/project';
    }
  }

  String get apiValue {
    switch (this) {
      case RateType.perHour:
        return 'hourly';
      case RateType.perDay:
        return 'daily';
      case RateType.perWeek:
        return 'weekly';
      case RateType.perMonth:
        return 'monthly';
      case RateType.perSession:
        return 'per_session';
      case RateType.perProject:
        return 'per_project';
    }
  }

  static RateType fromApiValue(String? value) {
    if (value == null) return RateType.perHour;
    final lower = value.toLowerCase().replaceAll('-', '_');
    switch (lower) {
      case 'hourly':
      case 'perhour':
      case 'per_hour':
        return RateType.perHour;
      case 'daily':
      case 'perday':
      case 'per_day':
        return RateType.perDay;
      case 'weekly':
      case 'perweek':
      case 'per_week':
        return RateType.perWeek;
      case 'monthly':
      case 'permonth':
      case 'per_month':
        return RateType.perMonth;
      case 'per_session':
      case 'persession':
        return RateType.perSession;
      case 'per_project':
      case 'perproject':
        return RateType.perProject;
      default:
        return RateType.perHour;
    }
  }
}

class JobPostImage {
  final String id;
  final String imageUrl;
  final String? thumbnailUrl;
  final int displayOrder;

  const JobPostImage({
    required this.id,
    required this.imageUrl,
    this.thumbnailUrl,
    this.displayOrder = 0,
  });

  factory JobPostImage.fromJson(Map<String, dynamic> json) {
    return JobPostImage(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image_url'] ?? json['url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      displayOrder: json['display_order'] is int
          ? json['display_order'] as int
          : int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'display_order': displayOrder,
    };
  }

  JobPostImage copyWith({
    String? id,
    String? imageUrl,
    String? thumbnailUrl,
    int? displayOrder,
  }) {
    return JobPostImage(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      displayOrder: displayOrder ?? this.displayOrder,
    );
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
  final bool isActive;
  final List<JobPostImage> images;

  JobPost({
    required this.id,
    required this.workerId,
    required this.category,
    required this.title,
    required this.description,
    required this.startingRate,
    required this.rateType,
    this.isAvailable = true,
    this.isActive = true,
    List<JobPostImage>? images,
    List<String>? imageUrls,
  }) : images = _resolveImages(images, imageUrls);

  static List<JobPostImage> _resolveImages(
    List<JobPostImage>? images,
    List<String>? imageUrls,
  ) {
    if (images != null && images.isNotEmpty) {
      final sorted = List<JobPostImage>.from(images);
      sorted.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return sorted;
    }
    if (imageUrls != null && imageUrls.isNotEmpty) {
      return imageUrls
          .asMap()
          .entries
          .map((e) => JobPostImage(
                id: 'local_${e.key}',
                imageUrl: e.value,
                thumbnailUrl: e.value,
                displayOrder: e.key,
              ))
          .toList();
    }
    return const [];
  }

  List<String> get imageUrls => images.map((img) => img.imageUrl).toList();

  String? get previewImageUrl =>
      images.isNotEmpty ? images.first.imageUrl : null;

  String? get thumbnailUrl =>
      images.isNotEmpty ? (images.first.thumbnailUrl ?? images.first.imageUrl) : null;

  JobPost copyWith({
    String? id,
    String? workerId,
    String? category,
    String? title,
    String? description,
    double? startingRate,
    RateType? rateType,
    bool? isAvailable,
    bool? isActive,
    List<JobPostImage>? images,
    List<String>? imageUrls,
  }) {
    return JobPost(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      startingRate: startingRate ?? this.startingRate,
      rateType: rateType ?? this.rateType,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      images: images ?? (imageUrls != null ? null : this.images),
      imageUrls: imageUrls,
    );
  }

  factory JobPost.fromJson(Map<String, dynamic> json, {String? defaultWorkerId}) {
    final rawImages = json['images'] as List<dynamic>? ?? [];
    final parsedImages = rawImages
        .map((item) => JobPostImage.fromJson(item as Map<String, dynamic>))
        .toList();

    final categoryVal = json['category'];
    final categoryName = categoryVal is Map
        ? (categoryVal['name'] ?? '')
        : (json['category_name'] ?? categoryVal ?? '');

    return JobPost(
      id: (json['id'] ?? json['job_post_id'])?.toString() ?? '',
      workerId: (json['worker_profile_id'] ?? json['worker_id'] ?? defaultWorkerId)?.toString() ?? '',
      category: categoryName.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startingRate: (json['rate_amount'] is num)
          ? (json['rate_amount'] as num).toDouble()
          : double.tryParse(json['rate_amount']?.toString() ?? '0') ?? 0.0,
      rateType: RateTypeExtension.fromApiValue(json['rate_type']?.toString()),
      isAvailable: json['is_available'] == true || json['is_available'] == 1,
      isActive: json['is_active'] != false && json['is_active'] != 0,
      images: parsedImages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'category': category,
      'title': title,
      'description': description,
      'rate_amount': startingRate,
      'rate_type': rateType.apiValue,
      'is_available': isAvailable,
      'is_active': isActive,
      'images': images.map((img) => img.toJson()).toList(),
    };
  }
}

/// A view model representing a specific job post listing in the feed or detail screen.
class JobPostListing {
  final Worker worker;
  final JobPost post;

  JobPostListing({
    required this.worker,
    required this.post,
  });

  factory JobPostListing.fromJson(Map<String, dynamic> json) {
    final workerData = json['worker'] as Map<String, dynamic>? ?? {};
    final worker = Worker.fromJson(
      workerData,
      fallbackProfileId: json['worker_profile_id']?.toString(),
    );
    final post = JobPost.fromJson(json, defaultWorkerId: worker.id);
    return JobPostListing(worker: worker, post: post);
  }
}
