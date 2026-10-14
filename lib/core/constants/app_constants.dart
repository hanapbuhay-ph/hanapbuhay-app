class AppConstants {
  // apiBaseUrl:
  // - Emulator: 'http://10.0.2.2:8000/api'
  // - Physical device USB + adb reverse tcp:8000 tcp:8000: 'http://127.0.0.1:8000/api'
  // - Physical device WiFi (same WiFi as PC): 'http://192.168.1.XX:8000/api'
  static const String apiBaseUrl = 'http://127.0.0.1:8000/api';

  /// Base URL for the Laravel public `storage/` disk (no trailing slash).
  /// Storage-relative photo paths returned by the API are prepended with this.
  static const String storageBaseUrl = 'http://127.0.0.1:8000/storage';

  static const String appName = 'HanapBuhay';

  /// Route used by [ApiClient] when a 401 (session expiry) is detected.
  static const String loginRoute = '/login';

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

  // Soketi / Pusher config — must match .env PUSHER_* values
  static const String pusherKey = 'hanapbuhay-key';
  static const String pusherHost = '127.0.0.1';
  static const int pusherPort = 6001;
  static const String pusherCluster = 'mt1';

  static const int otpLength = 6;
  static const int otpExpiryMinutes = 10;

  /// Normalizes a profile-photo path/URL into a displayable image URL.
  ///
  /// - null/empty                    -> falls back to [defaultAvatar]
  /// - already a full URL (http/https) -> returned as-is (e.g. Google photos)
  /// - otherwise (storage-relative path) -> prepended with [storageBaseUrl]
  static String getPhotoUrl(String? path) {
    if (path == null || path.isEmpty) {
      return defaultAvatar;
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path; // already a full URL, use as-is
    }
    return '$storageBaseUrl/$path'; // relative path — prepend storage base URL
  }

  /// Normalizes a photo path when present, without inventing a fallback photo.
  static String? getOptionalPhotoUrl(String? path) {
    final normalizedPath = path?.trim();
    if (normalizedPath == null || normalizedPath.isEmpty) {
      return null;
    }
    return getPhotoUrl(normalizedPath);
  }
}
