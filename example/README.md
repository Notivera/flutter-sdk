# Demonstrates `notivera_flutter`.

The example auto-initializes with the native demo credentials on launch.

- **Home** — tap a canned notification to send it through `handlePushMessage` (Android offline demo path)
- **Offline** — subscribe a tag, view device ID (long-press to copy), and device OS

See the plugin [README](../README.md) for Android JitPack, FCM forwarding, iOS App Group, and notification extension setup.

If `flutter build ios` fails with `unable to override package 'notivera_flutter' because its identity 'flutter_sdk'`, check the plugin README section **Local iOS example builds**.
