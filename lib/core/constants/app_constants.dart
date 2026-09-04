class AppConstants {
  // apiBaseUrl:
  // - Emulator: 'http://10.0.2.2:8000/api'
  // - Physical Device: Replace with your laptop's Local IP (e.g., 'http://192.168.1.XX:8000/api')
  //   Make sure your phone and laptop are on the same Wi-Fi.
  static const String apiBaseUrl = 'http://192.168.1.2:8000/api';

  static const String appName = 'HanapBuhay';

  static const String mockWorkerId = 'w1';
  static const String mockClientId = 'c1';
  static const String defaultBarangay = 'Poblacion';
  static const String municipalityName = 'Trinidad';
  static const String mockWorkerAvatar = 'https://i.pravatar.cc/150?u=w1';
  static const String mockClientAvatar = 'https://i.pravatar.cc/150?u=client';
  static const String mockClientProfileAvatar = 'https://i.pravatar.cc/150?u=client123';
  static const String defaultAvatar = 'https://i.pravatar.cc/150?u=client';

  static const List<String> workerCategories = [
    'Plumbing',
    'Electrical',
    'Tutoring',
    'Cleaning',
    'Laundry',
    'Gardening',
    'Carpentry',
    'General Repairs',
  ];

  static const int otpLength = 6;
  static const int otpExpiryMinutes = 10;
}
