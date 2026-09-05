import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/data/models/job_post_model.dart';
import 'package:hanapbuhayapp/data/models/trust_tier.dart';

void main() {
  group('JobPostImage Tests', () {
    test('parses from JSON correctly', () {
      final json = {
        'id': 21,
        'image_url': 'https://example.com/image.jpg',
        'thumbnail_url': 'https://example.com/thumb.jpg',
        'display_order': 0,
      };

      final image = JobPostImage.fromJson(json);

      expect(image.id, '21');
      expect(image.imageUrl, 'https://example.com/image.jpg');
      expect(image.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(image.displayOrder, 0);
    });

    test('serializes to JSON correctly', () {
      const image = JobPostImage(
        id: '21',
        imageUrl: 'https://example.com/image.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        displayOrder: 2,
      );

      final json = image.toJson();

      expect(json['id'], '21');
      expect(json['image_url'], 'https://example.com/image.jpg');
      expect(json['thumbnail_url'], 'https://example.com/thumb.jpg');
      expect(json['display_order'], 2);
    });
  });

  group('JobPost Model Tests', () {
    test('sorts images by display_order automatically', () {
      final post = JobPost(
        id: 'p1',
        workerId: 'w1',
        category: 'Plumbing',
        title: 'Leak Repair',
        description: 'Fixing pipes',
        startingRate: 350.0,
        rateType: RateType.perSession,
        images: const [
          JobPostImage(id: '3', imageUrl: 'img3.jpg', displayOrder: 2),
          JobPostImage(id: '1', imageUrl: 'img1.jpg', displayOrder: 0),
          JobPostImage(id: '2', imageUrl: 'img2.jpg', displayOrder: 1),
        ],
      );

      expect(post.images.map((i) => i.id).toList(), ['1', '2', '3']);
      expect(post.previewImageUrl, 'img1.jpg');
      expect(post.imageUrls, ['img1.jpg', 'img2.jpg', 'img3.jpg']);
    });

    test('parses from backend GET /api/posts/{postId} format', () {
      final json = {
        'id': 5,
        'worker_profile_id': 3,
        'title': 'Expert Aircon Cleaning & Repair',
        'description': 'Complete service description...',
        'rate_amount': 300.0,
        'rate_type': 'per_session',
        'is_available': true,
        'is_active': true,
        'category': {
          'id': 1,
          'name': 'Electrical Works',
          'icon': 'electrical',
        },
        'images': [
          {
            'id': 22,
            'image_url': 'https://example.com/full2.jpg',
            'thumbnail_url': 'https://example.com/thumb2.jpg',
            'display_order': 1,
          },
          {
            'id': 21,
            'image_url': 'https://example.com/full1.jpg',
            'thumbnail_url': 'https://example.com/thumb1.jpg',
            'display_order': 0,
          },
        ],
      };

      final post = JobPost.fromJson(json);

      expect(post.id, '5');
      expect(post.workerId, '3');
      expect(post.category, 'Electrical Works');
      expect(post.title, 'Expert Aircon Cleaning & Repair');
      expect(post.startingRate, 300.0);
      expect(post.rateType, RateType.perSession);
      expect(post.isAvailable, true);
      expect(post.isActive, true);
      expect(post.images.length, 2);
      expect(post.images.first.id, '21');
      expect(post.thumbnailUrl, 'https://example.com/thumb1.jpg');
      expect(post.previewImageUrl, 'https://example.com/full1.jpg');
    });

    test('parses feed listing from GET /api/feed format', () {
      final json = {
        'job_post_id': 5,
        'worker_profile_id': 3,
        'worker': {
          'user_id': 8,
          'name': 'Pedro Alonzo',
          'profile_photo_url': 'https://example.com/pedro.jpg',
          'barangay': 'Poblacion',
          'barangay_id': 17,
          'distance_km': 1.2,
          'distance_label': '~1.2 km',
          'average_rating': 4.80,
          'total_reviews': 23,
          'trust_tier': 'verified',
          'verification_status': 'approved',
        },
        'category': {
          'id': 1,
          'name': 'Electrical Works',
          'icon': 'electrical',
        },
        'title': 'Expert Electrical Installation & Repair',
        'description': 'Licensed electrician with 5 years experience',
        'rate_amount': 300.00,
        'rate_type': 'daily',
        'is_available': true,
        'images': [
          {
            'id': 21,
            'thumbnail_url': 'https://example.com/thumb.jpg',
            'image_url': 'https://example.com/full.jpg',
            'display_order': 0,
          },
        ],
        'posted_at': '2026-08-20T10:00:00Z',
      };

      final listing = JobPostListing.fromJson(json);

      expect(listing.worker.id, '3');
      expect(listing.worker.name, 'Pedro Alonzo');
      expect(listing.worker.trustTier, TrustTier.verified);
      expect(listing.post.id, '5');
      expect(listing.post.rateType, RateType.perDay);
      expect(listing.post.thumbnailUrl, 'https://example.com/thumb.jpg');
    });
  });

  group('RateType Extension Tests', () {
    test('converts api values properly', () {
      expect(RateTypeExtension.fromApiValue('hourly'), RateType.perHour);
      expect(RateTypeExtension.fromApiValue('daily'), RateType.perDay);
      expect(RateTypeExtension.fromApiValue('weekly'), RateType.perWeek);
      expect(RateTypeExtension.fromApiValue('monthly'), RateType.perMonth);
      expect(RateTypeExtension.fromApiValue('per_session'), RateType.perSession);
      expect(RateTypeExtension.fromApiValue('per_project'), RateType.perProject);
    });

    test('exports apiValue string properly', () {
      expect(RateType.perHour.apiValue, 'hourly');
      expect(RateType.perDay.apiValue, 'daily');
      expect(RateType.perSession.apiValue, 'per_session');
    });
  });
}

