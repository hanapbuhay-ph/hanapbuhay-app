# hanapbuhayapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Android APK releases

The GitHub Actions workflow builds a signed APK when a `v*` tag is pushed and
attaches it to a GitHub Release. Run it manually from the Actions tab to build
an APK artifact without publishing a release.

### One-time GitHub setup

Create a dedicated Android signing key and store a secure backup somewhere
outside the repository. Keep this key for every future release; Android will
not install an APK over an existing installation if it was signed with a
different key.

```powershell
keytool -genkeypair -v -keystore "$HOME\hanapbuhay-upload-key.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias hanapbuhay
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$HOME\hanapbuhay-upload-key.jks")) | Set-Clipboard
```

Add these repository Actions secrets under **Settings > Secrets and variables
> Actions**:

- `ANDROID_KEYSTORE_BASE64`: clipboard contents from the command above.
- `ANDROID_KEYSTORE_PASSWORD`: password used when creating the key.
- `ANDROID_KEY_ALIAS`: `hanapbuhay` (or the alias you chose).
- `ANDROID_KEY_PASSWORD`: key password.
- `ABLY_PUSHER_KEY`: the Ably API key name (the text before `:` in the full
  Ably key). This is the public identifier only, not the secret/full API key.
- `FIREBASE_ANDROID_CONFIG_BASE64`: base64-encoded contents of the local
  `android/app/google-services.json`. Copy it with:

  ```powershell
  [Convert]::ToBase64String([IO.File]::ReadAllBytes('.\android\app\google-services.json')) | Set-Clipboard
  ```

Do not commit the keystore, `key.properties`, Firebase configuration, or the
full Ably API key.

### Publish a release

Update the app version in `pubspec.yaml`, commit and push the change, then tag
that commit and push the tag:

```powershell
git tag v1.0.1
git push origin v1.0.1
```

The release APK is attached to that GitHub Release. Users download and install
it manually. The APK keeps the same application ID and signing key between
releases, so it can update an installation made from a previous APK from this
workflow. An app installed with a different signing key (such as a local
debug build) must be uninstalled once before installing the first release APK.
