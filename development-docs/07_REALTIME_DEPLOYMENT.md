# Hosted Realtime Tracking

The Android app uses the Pusher Channels Flutter SDK with Ably's Pusher
Protocol Adapter for private booking-location channels.

The app requires the Ably API key name (the part before `:` in the full API
key). It is not the secret portion, but keep the full key only in the API
service's `ABLY_KEY` environment variable. Never bundle the full key in a
mobile app.

Run or build Android with the key name supplied at compile time. In
PowerShell, enter only the key name shown before the colon in Ably (for example,
`appId.keyId`), not the full key:

```powershell
$ablyKeyName = Read-Host "Ably key name (the part before the colon)"
flutter run --dart-define="ABLY_PUSHER_KEY=$ablyKeyName"
flutter build apk --release --dart-define="ABLY_PUSHER_KEY=$ablyKeyName"
```

The Pusher plugin is kept as a local package under
`packages/pusher_channels_flutter`. Its Android implementation accepts a
custom WebSocket host so it can connect over TLS to
`main.pusher.ably.net`; upstream plugin versions do not currently expose that
Android option.

The API authorizes private channels at `/broadcasting/auth`. Ensure the Ably
app has Pusher protocol support enabled and the `private:` namespace created
with the Require identification rule disabled.
