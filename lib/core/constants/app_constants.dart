class AppConstants {
  // apiBaseUrl:
  // - Emulator: 'http://10.0.2.2:8000/api'
  // - Physical Device: Replace with your laptop's Local IP (e.g., 'http://192.168.1.XX:8000/api')
  //   Make sure your phone and laptop are on the same Wi-Fi.
  static const String apiBaseUrl = 'http://192.168.1.2:8000/api';

  static const String appName = 'HanapBuhay';

  static const int otpLength = 6;
  static const int otpExpiryMinutes = 10;
}
