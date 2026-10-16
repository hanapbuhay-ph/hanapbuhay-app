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
    expect(
      ApiClient.shouldRedirectToLogin(
        hasAuthToken: true,
        routeName: '/client-home',
      ),
      isTrue,
    );
  });

  test('401s without an auth token do not redirect guest auth flows', () {
    expect(
      ApiClient.shouldRedirectToLogin(
        hasAuthToken: false,
        routeName: '/verify-email?login=true',
      ),
      isFalse,
    );
  });
}
