# 01_SETUP_GUIDE.md

## 1. Create the Flutter Project

```bash
flutter create --org com.hanapbuhay --platforms=android,ios hanapbuhay_app
cd hanapbuhay_app
```

Connect to the repo:

```bash
git remote add origin https://github.com/hanapbuhay-ph/hanapbuhay-app.git
git add .
git commit -m "chore: initial flutter project scaffold"
git push -u origin develop
```

(Create a `develop` branch if one doesn't exist yet — do not push directly to `main`.)

---

## 2. pubspec.yaml — Dependencies

Replace the `dependencies:` section with:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # HTTP & API
  http: ^1.1.0

  # Authentication
  google_sign_in: ^6.1.5

  # Secure storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0

  # Navigation
  go_router: ^12.0.0

  # State management
  provider: ^6.1.1

  # UI
  smooth_page_indicator: ^1.1.0
  shimmer: ^3.0.0
  cached_network_image: ^3.3.0

  # Maps (Section 2 — live tracking, not needed yet)
  google_maps_flutter: ^2.5.0

  # Real-time (Section 2 — live tracking, not needed yet)
  pusher_channels_flutter: ^2.0.0

  # Image picker (document upload)
  image_picker: ^1.0.4

  # Firebase (Phase 3 — deferred, not needed yet)
  firebase_core: ^2.17.0
  firebase_messaging: ^14.7.0

  cupertino_icons: ^1.0.6
```

Then run:

```bash
flutter pub get
```

> Note: `google_maps_flutter`, `pusher_channels_flutter`, and the `firebase_*` packages are only needed starting Section 2. It's fine to add them now (per the section's pubspec) so the project builds cleanly later, but don't wire them up until their section is unlocked.

---

## 3. Assets Setup

### Fonts

Download **Poppins** (headings) and **Inter** (body) from Google Fonts. Place the `.ttf` files here:

```
assets/fonts/Poppins-Regular.ttf
assets/fonts/Poppins-Medium.ttf
assets/fonts/Poppins-SemiBold.ttf
assets/fonts/Poppins-Bold.ttf
assets/fonts/Inter-Regular.ttf
assets/fonts/Inter-Medium.ttf
assets/fonts/Inter-SemiBold.ttf
```

Register them in `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true

  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-Regular.ttf
        - asset: assets/fonts/Poppins-Medium.ttf
          weight: 500
        - asset: assets/fonts/Poppins-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Poppins-Bold.ttf
          weight: 700
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600

  assets:
    - assets/images/
    - assets/icons/
```

### Images

```
assets/images/logo.png              # mascot logo, green gradient bg
assets/images/onboarding_1.png      # onboarding slide illustrations
assets/images/onboarding_2.png
assets/images/onboarding_3.png
assets/images/onboarding_4.png
```

Get these from the Stitch export / Figma — do not generate placeholders, ask the PM if any are missing.

---

## 4. Config Files (create these first, before any screens)

Create the following empty-but-structured files. These will be filled in fully in `03_DESIGN_SYSTEM.md`, but Gemini should scaffold them now so every screen prompt can reference them.

```
lib/core/theme/app_colors.dart
lib/core/theme/app_typography.dart
lib/core/theme/app_spacing.dart
lib/core/constants/app_constants.dart
```

`app_constants.dart` should include, at minimum:

```dart
class AppConstants {
  // Swap this single flag/base URL setup per environment.
  // Emulator: 10.0.2.2 | Physical device: PM's local IP | never 127.0.0.1 on device/emulator
  static const String apiBaseUrl = 'http://10.0.2.2:8000/api';

  static const String appName = 'HanapBuhay';

  static const int otpLength = 6;
  static const int otpExpiryMinutes = 10;
}
```

---

## 5. Mock-First Architecture Setup

This is the most important structural decision for this project — set it up before building any screen.

### Folder additions for this pattern

```
lib/data/
  models/            # plain Dart data classes (User, WorkerProfile, Booking, etc.)
  repositories/
    auth_repository.dart              # abstract interface
    mock/
      mock_auth_repository.dart       # fake implementation
    api/
      api_auth_repository.dart        # real HTTP implementation
lib/providers/
  auth_provider.dart   # ChangeNotifier that depends on AuthRepository (interface, not impl)
```

### Pattern

1. **Interface** — define the contract:
```dart
abstract class AuthRepository {
  Future<AuthResult> register(RegisterRequest request);
  Future<AuthResult> verifyOtp(String email, String otp);
  Future<AuthResult> login(String email, String password);
}
```

2. **Mock implementation** — returns fake data shaped exactly like the real API's `{success, message, data}` / `{success, message, errors}` envelope, with an artificial delay to simulate network latency:
```dart
class MockAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return AuthResult.success(data: {/* fake user + token */});
  }
  // ...
}
```

3. **Real implementation** — same interface, real `http` calls to `AppConstants.apiBaseUrl`.

4. **Wiring (single swap point)** — in `main.dart` or a dedicated `service_locator.dart`:
```dart
final authRepository = AuthRepository.useMock
    ? MockAuthRepository()
    : ApiAuthRepository();
```
Since `register` and `verify-otp` are already live on the backend, `ApiAuthRepository` can implement just those two for real and fall back to mock behavior (or throw `UnimplementedError`) for the rest — call this out clearly in the file's doc comment so it's obvious which methods are real.

Full folder tree in `02_FOLDER_STRUCTURE.md`.

---

## 6. Verify Setup

Before writing any screen, confirm the project builds and runs on an emulator with a blank Scaffold showing "HanapBuhay" in Poppins Bold, primary green (#2E9B2E) background. This confirms fonts, colors, and the project itself are wired correctly before any real screen work starts.

```bash
flutter run
```

---
