import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/core/constants/app_constants.dart';
import 'package:hanapbuhayapp/data/models/booking_model.dart';
import 'package:hanapbuhayapp/data/models/worker_model.dart';

void main() {
  group('profile photo parsing', () {
    test(
      'booking client photo paths use stored photo rather than mock default',
      () {
        final booking = Booking.fromJson({
          'id': 17,
          'worker_id': 8,
          'client_id': 12,
          'client': {
            'id': 12,
            'name': 'Ana Cruz',
            'profile_photo_path': 'client-photos/ana.jpg',
          },
          'scheduled_at': '2026-10-14T10:00:00Z',
        });

        expect(
          booking.clientPhotoUrl,
          '${AppConstants.storageBaseUrl}/client-photos/ana.jpg',
        );
      },
    );

    test('booking with no client photo does not receive a mock URL', () {
      final booking = Booking.fromJson({
        'id': 17,
        'worker_id': 8,
        'client_id': 12,
        'client': {'id': 12, 'name': 'Ana Cruz'},
        'scheduled_at': '2026-10-14T10:00:00Z',
      });

      expect(booking.clientPhotoUrl, isNull);
    });

    test('reviewer Google photo URL is preserved', () {
      final review = WorkerReview.fromJson({
        'id': 3,
        'rated_by_user_id': 42,
        'rated_by_name': 'Ana Cruz',
        'reviewer_avatar_url': 'https://lh3.googleusercontent.com/ana-photo',
        'score': 5,
      });

      expect(review.reviewerId, '42');
      expect(
        review.reviewerAvatar,
        'https://lh3.googleusercontent.com/ana-photo',
      );
    });

    test('review without a photo does not receive a mock URL', () {
      final review = WorkerReview.fromJson({
        'id': 3,
        'rated_by_name': 'Ana Cruz',
        'score': 5,
      });

      expect(review.reviewerAvatar, isNull);
    });
  });
}
