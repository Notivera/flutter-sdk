# Maintainer guide

Internal notes for developing and shipping `notivera_flutter`. Integrators should use [README.md](README.md).

## Repository layout

| Path | Role |
|------|------|
| `lib/` | Public Dart API (`Notivera`, config, events) |
| `pigeons/messages.dart` | Pigeon contract |
| `android/` | Android plugin + `consumer-rules.pro` |
| `ios/notivera_flutter/` | iOS plugin (SPM) |
| `example/` | Demo app (FlutterFire on Android; APNs + optional local demos on iOS) |

## Regenerating Pigeon

```sh
dart run pigeon --input pigeons/messages.dart
```

Generated files are committed so consumers do not need the `pigeon` tool.

## Local iOS example builds

Swift Package Manager identifies a **git checkout** by the folder name. This repository is often cloned as `flutter_sdk`, but the Dart package is `notivera_flutter`. Building `example/` for iOS from a `flutter_sdk` folder fails with an identity mismatch.

Workaround: clone or symlink the repo as `notivera_flutter`:

```sh
git clone https://github.com/Notivera/flutter_sdk notivera_flutter
cd notivera_flutter/example
flutter run
```

Apps that depend on `notivera_flutter` from pub.dev are not affected.

## Example demo credentials

Demo API key / secret / tenant live in a **gitignored** file:

```sh
cd example/lib
cp notivera_demo_secrets.dart.example notivera_demo_secrets.dart
# edit notivera_demo_secrets.dart
```

Do not commit `notivera_demo_secrets.dart`.

## Example Android

- Uses FlutterFire (`firebase_core` / `firebase_messaging`) for FCM → `setPushToken` / `handlePushMessage`.
- Requires `google-services.json` and JitPack (see consumer README).
- `android.enableR8.fullMode=false` is set in `example/android/gradle.properties`.

## Example iOS

- APNs is handled by the plugin; do not call `setPushToken` on iOS.
- `AppDelegate` must call `NotiveraFlutterPlugin.captureNotificationResponse` on tap (required for cold start) — documented for consumers in README.
- Notification Service / Content extensions under `example/ios/` are **required** host-app samples for rich push (see consumer README §5).

### Offline demos (example only — not for client docs)

`example/ios/Runner/OfflineDemo/` schedules local notifications and presents video/carousel UI without a live campaign. That path is **demo-only**:

- `OfflineDemoPlugin`, `PendingNotificationTap`, offline storyboards
- `AppDelegate` also calls `PendingNotificationTap.capture` for offline categories

Do **not** document OfflineDemo in the consumer README. Clients should only wire `NotiveraFlutterPlugin.captureNotificationResponse` (and NSE/NCE if they need rich presentation).

## Android native SDK pin

Plugin Gradle dependency in `android/build.gradle.kts`:

```kotlin
implementation("com.github.Notivera:android-sdk:5.0.1")
```

Bump this when releasing against a new android-sdk version. Host apps need JitPack. Also update the version mentioned in [README.md](README.md) if it documents the pin.

## iOS native SDK pin

Plugin SPM dependency in `ios/notivera_flutter/Package.swift`:

```swift
.package(url: "https://github.com/Notivera/ios-spm-notivera", from: "5.0.0"),
```

Bump the `from:` version when releasing against a new [NotiveraSDK](https://github.com/Notivera/ios-spm-notivera) / ios-spm-notivera tag. Flutter resolves this through Swift Package Manager for the plugin and host apps. After bumping:

1. Update the version mentioned in [README.md](README.md) if it documents the pin.
2. In `example/ios`, refresh resolved packages (Xcode → File → Packages → Update to Latest Package Versions, or delete `Package.resolved` and rebuild) so the example picks up the new SDK.

## Release checklist (plugin)

1. Bump `pubspec.yaml` / `example/pubspec.yaml` versions as needed.
2. Bump native pins if needed: Android in `android/build.gradle.kts`, iOS `from:` in `ios/notivera_flutter/Package.swift`.
3. Regenerate Pigeon if the API changed; commit generated files.
4. Verify example Android (FCM token + data message) and iOS (APNs + cold-start tap).
5. Confirm consumer README covers Android FCM, iOS AppDelegate capture, App Group, and R8 full mode off.
6. Publish / tag according to your release process.
