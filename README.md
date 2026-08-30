# notivera_flutter

Flutter plugin for the [Notivera](https://notivera.com/) native Android and iOS SDKs.

Host apps add this like any other Dart package:

```yaml
dependencies:
  notivera_flutter: ^0.0.1
```

Requires **Flutter 3.44.0+** (Swift Package Manager is the default for iOS).

## Install

```sh
flutter pub add notivera_flutter
```

## Dart usage

```dart
import 'package:notivera_flutter/notivera_flutter.dart';

Future<void> startNotivera() async {
  Notivera.instance.events.listen((NotiveraPushEvent event) {
    debugPrint('Notivera event: ${event.eventType} ${event.title}');
  });

  await Notivera.instance.initialize(
    const NotiveraConfig(
      apiKey: 'YOUR_API_KEY',
      apiSecret: 'YOUR_API_SECRET',
      appVersion: '1.0.0',
      tenantId: 'YOUR_TENANT_ID',
      // Android-only: host app res/drawable|mipmap|color names (not Flutter assets).
      pushTheme: NotiveraPushTheme(
        smallIcon: 'ic_launcher_foreground',
        largeIcon: 'ic_launcher_round',
        color: 'ic_launcher_background',
      ),
    ),
  );

  await Notivera.instance.requestAuthorisationPrompts();
  await Notivera.instance.subscribeTag('news');
}
```

The public API lives in `Notivera`. Pigeon-generated types are internal.

## Android host-app setup

1. Add JitPack so Gradle can resolve the native SDK:

```kotlin
// settings.gradle.kts
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}
```

If your project still uses `allprojects { repositories { } }` in `android/build.gradle.kts`, add the same `maven { url = uri("https://jitpack.io") }` there.

2. Native dependency pulled by this plugin: `com.github.Notivera:android-sdk:5.0.0`.

3. Firebase Cloud Messaging is **not** bundled. After you obtain an FCM token and data message:

```dart
await Notivera.instance.setPushToken(fcmToken);

if (await Notivera.instance.isNotiveraMessage(data)) {
  await Notivera.instance.handlePushMessage(data);
}
```

4. Optional Android notification chrome via [NotiveraConfig.pushTheme] — pass **resource names** from your app `res/` (e.g. `ic_launcher_foreground`, `ic_launcher_round`, `ic_launcher_background`). Ignored on iOS (use the Runner `AppIcon` asset instead).

5. Request `POST_NOTIFICATIONS` on Android 13+ in your app if you show notifications.

## iOS host-app setup

This plugin depends on the [NotiveraSDK](https://github.com/Notivera/ios-spm-notivera) Swift package (`from: 5.0.0`). Flutter 3.44 downloads it through Swift Package Manager.

Minimum iOS version: **14.0**.

### App Group (required)

The native iOS SDK `fatalError`s without an App Group. In the Runner `Info.plist`:

```xml
<key>NotiveraAppGroup</key>
<string>group.com.yourcompany.yourapp</string>
```

Add the same App Group to the Runner entitlements (`com.apple.security.application-groups`).

### Push and location

Enable Push Notifications and Background Modes → Remote notifications.

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used for geofenced campaigns.</string>
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

APNs device tokens are forwarded by the plugin. You do not need to call `setPushToken` on iOS.

### Cold-start notification taps (required for killed → open)

When the user opens a push while the app is **terminated**, iOS delivers
`userNotificationCenter(_:didReceive:)` before Dart `initialize()`. Capture that
tap in your `AppDelegate` and let the plugin replay it after init:

```swift
import notivera_flutter

override func userNotificationCenter(
  _ center: UNUserNotificationCenter,
  didReceive response: UNNotificationResponse,
  withCompletionHandler completionHandler: @escaping () -> Void
) {
  NotiveraFlutterPlugin.captureNotificationResponse(response)
  super.userNotificationCenter(
    center,
    didReceive: response,
    withCompletionHandler: completionHandler
  )
}
```

`initialize()` flushes a buffered Notivera tap (video / carousel / poll) once the
SDK is ready. Hosts that install a custom `UNUserNotificationCenter` delegate
after init can also call
`NotiveraFlutterPlugin.flushPendingNotificationResponse(delaySeconds:)` when the
UI can present.

### Pre-init lifecycle callbacks

UIKit may deliver APNs registration, remote-notification, or background URL-session callbacks before Dart calls `Notivera.instance.initialize()`. The iOS plugin buffers those events while the native SDK is not yet created, then flushes them in order as soon as `initialize` sets up the SDK:

1. Latest APNs device token (or registration failure if no token was received)
2. Queued Notivera remote notifications (completion handlers still run exactly once)
3. Queued background URL-session completion handlers

Non-Notivera remote payloads are not claimed (same `isNotiveraNotification` gate as after init). Watch the Xcode console for `[NotiveraFlutterPlugin]` lines that say `buffering until initialize` or `Pre-init flush complete` when diagnosing token/type registration issues.

### Notification extensions (optional, host app only)

Notification Service Extension and Notification Content Extension are **not** part of this plugin. Add those Xcode targets in the host app if you need rich/carousel notifications, as described in the [NotiveraSDK SPM README](https://github.com/Notivera/ios-spm-notivera):

- Service extension subclass `NotiveraServiceExtension`
- Content extension class `NotiveraCarouselNotificationContentViewController`
- Same App Group as the Runner

## Regenerating Pigeon

```sh
dart run pigeon --input pigeons/messages.dart
```

Generated files are committed so consumers do not need the `pigeon` tool.

## Local iOS example builds

Swift Package Manager identifies a **git checkout** by the folder name. This repository is often cloned as `flutter_sdk`, but the Dart package is `notivera_flutter`. Building `example/` for iOS from a `flutter_sdk` folder fails with an identity mismatch.

Workaround for local iOS: clone or symlink the repo as `notivera_flutter`:

```sh
git clone https://github.com/Notivera/flutter_sdk notivera_flutter
cd notivera_flutter/example
flutter run
```

Apps that depend on `notivera_flutter` from pub.dev are not affected.

