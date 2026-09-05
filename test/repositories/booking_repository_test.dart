import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/data/repositories/mock/mock_booking_repository.dart';

void main() {
  late MockBookingRepository repository;

  setUp(() {
    repository = MockBookingRepository();
  });

  group('BookingRepository Tests', () {
    test('createBooking records jobPostId when provided', () async {
      final result = await repository.createBooking(
        workerId: 'w1',
        category: 'Plumbing',
        date: DateTime.now().add(const Duration(days: 2)),
        time: '10:00 AM',
        notes: 'Fix faucet',
        barangay: 'Poblacion',
        jobPostId: 'jp1',
      );

      expect(result.success, true);

      final bookings = await repository.getBookings();
      final latest = bookings.last;
      expect(latest.jobPostId, 'jp1');
      expect(latest.workerId, 'w1');
    });

    test('createBooking remains compatible without jobPostId', () async {
      final result = await repository.createBooking(
        workerId: 'w2',
        category: 'Electrical',
        date: DateTime.now().add(const Duration(days: 3)),
        time: '2:00 PM',
        notes: 'Check wiring',
        barangay: 'Poblacion',
      );

      expect(result.success, true);

      final bookings = await repository.getBookings();
      final latest = bookings.last;
      expect(latest.jobPostId, isNull);
    });
  });
}

