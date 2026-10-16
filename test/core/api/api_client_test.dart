import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/core/api/api_client.dart';

void main() {
  test('401s do not redirect away from the login OTP challenge', () {
    expect(
      ApiClient.isAuthenticationRoute(
        '/verify-email?email=client%40example.com&login=true',
      ),
      isTrue,
    );
  });

  test('401s still redirect away from authenticated app screens', () {
    expect(ApiClient.isAuthenticationRoute('/client-home'), isFalse);
  });
}
