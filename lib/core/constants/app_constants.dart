class AppConstants {
  static const String apiBaseUrl = 'https://hanapbuhay-api.onrender.com/api';

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

  // Ably Pusher Adapter key name; pass with --dart-define, never the full secret key.
  static const String pusherKey = String.fromEnvironment('ABLY_PUSHER_KEY');
  static const String pusherHost = 'main.pusher.ably.net';
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
