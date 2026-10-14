import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/core/utils/philippine_mobile_number.dart';

void main() {
  group('Philippine mobile number validation', () {
    test('accepts valid national format only', () {
      expect(validatePhilippineMobileNumber('09171234567'), isNull);
      expect(validatePhilippineMobileNumber('0917 123 4567'), isNull);
      expect(validatePhilippineMobileNumber('0917123456'), isNotNull);
      expect(validatePhilippineMobileNumber('0281234567'), isNotNull);
      expect(validatePhilippineMobileNumber('+14155552671'), isNotNull);
      expect(validatePhilippineMobileNumber('09letters123456789'), isNotNull);
    });

    test('normalizes international Philippine format', () {
      expect(
        normalizePhilippineMobileNumber('+63 917 123 4567'),
        '09171234567',
      );
    });
  });
}
