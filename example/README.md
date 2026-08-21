# Demonstrates `notivera_flutter`.

The example auto-initializes with the native demo credentials on launch.

- **Home** — offline demos: Android uses SDK `PSDKDemoNotification`; iOS schedules a native local notification (tap banner → native AVKit/UIKit experience), matching `ios-sdk/App`
- **Offline** — subscribe a tag, view device ID (long-press to copy), and device OS

## iOS (`com.notivera.app`)

Configured to mirror the native Notivera iOS app:

- Bundle ID `com.notivera.app`, App Group `group.com.notivera.app`
- Push (`aps-environment`) + Background Modes → Remote notifications
- `NotiveraServiceExtension` (`com.notivera.app.PushNotificationServiceExtension`)
- `NotiveraContentExtension` (`com.notivera.app.Carousel`) for carousel category `PushologiesCarouselNotification`

In Xcode, enable App Groups + Push for the host and both extension App IDs on your team (`DEVELOPMENT_TEAM` in the project). APNs keys for `com.notivera.app` must be registered with the Notivera tenant.

See the plugin [README](../README.md) for Android JitPack, FCM forwarding, iOS App Group, and notification extension setup.

If `flutter build ios` fails with `unable to override package 'notivera_flutter' because its identity 'flutter_sdk'`, check the plugin README section **Local iOS example builds**.
