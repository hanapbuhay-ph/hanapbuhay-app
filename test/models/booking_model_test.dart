import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/core/constants/app_constants.dart';
import 'package:hanapbuhayapp/data/models/booking_model.dart';

void main() {
  group('Booking model', () {
    test('parses worker user and profile IDs separately', () {
      final booking = Booking.fromJson({
        'id': 12,
        'worker': {
          'id': 34,
          'name': 'Worker Name',
          'profile_photo_path': 'profiles/worker.jpg',
          'worker_profile': {'id': 56},
        },
        'service_category': {'id': 2, 'name': 'Cleaning'},
        'scheduled_at': '2026-10-15T09:00:00Z',
        'status': 'accepted',
      });

      expect(booking.workerId, '34');
      expect(booking.workerUserId, 34);
      expect(booking.workerProfileId, '56');
      expect(
        booking.workerPhotoUrl,
        '${AppConstants.storageBaseUrl}/profiles/worker.jpg',
      );
    });

    test(
      'reads explicit worker profile ID from formatted booking response',
      () {
        final booking = Booking.fromJson({
          'id': 12,
          'worker': {'id': 34, 'worker_profile_id': 56},
          'scheduled_at': '2026-10-15T09:00:00Z',
          'status': 'pending',
        });

        expect(booking.workerId, '34');
        expect(booking.workerProfileId, '56');
      },
    );
  });
}
