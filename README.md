# notivera_flutter

Flutter plugin for the [Notivera](https://notivera.com/) native Android and iOS SDKs.

Requires **Flutter 3.44.0+** (Swift Package Manager is the default for iOS plugins).

```yaml
dependencies:
  notivera_flutter: ^5.0.1
```

```sh
flutter pub add notivera_flutter
```

## Dart usage

```dart
import 'package:flutter/foundation.dart';
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
      // Android-only: names of resources under your app res/ (not Flutter assets).
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

The public API lives in `Notivera`.

### Platform push difference

| Platform | Token | Incoming push payload |
|----------|--------|------------------------|
| **Android** | Host obtains FCM token → Dart `setPushToken` | Host forwards FCM data in Dart → `isNotiveraMessage` / `handlePushMessage` |
| **iOS** | APNs forwarded by the plugin (no `setPushToken`) | **Not** forwarded in Flutter. The host **Notification Service Extension** gates Notivera via `request.isNotiveraRequest` and `NotiveraServiceExtension` (see §5) |

---

## Android setup

### 1. JitPack

The plugin depends on `com.github.Notivera:android-sdk:x.x.x`. Add JitPack:

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

If you still use `allprojects { repositories { } }` in `android/build.gradle.kts`, add the same JitPack `maven` entry there.

### 2. Firebase Cloud Messaging (required for push)

FCM is **not** bundled. Use FlutterFire (`firebase_core` + `firebase_messaging`) or your own FCM pipeline, then pass the token and data messages to Notivera.

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:notivera_flutter/notivera_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await Notivera.instance.initialize(/* your NotiveraConfig */);
  await _forwardRemoteMessage(message);
}

Future<void> configureAndroidPush() async {
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  final token = await messaging.getToken();
  if (token != null && token.isNotEmpty) {
    await Notivera.instance.setPushToken(token);
  }

  messaging.onTokenRefresh.listen((refreshed) {
    Notivera.instance.setPushToken(refreshed);
  });

  FirebaseMessaging.onMessage.listen(_forwardRemoteMessage);
  FirebaseMessaging.onMessageOpenedApp.listen(_forwardRemoteMessage);

  final initial = await messaging.getInitialMessage();
  if (initial != null) {
    await _forwardRemoteMessage(initial);
  }
}

Future<void> _forwardRemoteMessage(RemoteMessage message) async {
  final data = message.data.map(
    (key, value) => MapEntry(key, value.toString()),
  );
  if (data.isEmpty) return;

  if (await Notivera.instance.isNotiveraMessage(data)) {
    await Notivera.instance.handlePushMessage(data);
  }
}
```

Also:

- Call `configureAndroidPush()` **after** `Notivera.instance.initialize(...)` (except the background handler, which must re-initialize in its isolate).
- Register `FirebaseMessaging.onBackgroundMessage` **before** `runApp`, and only on Android.
- Add `google-services.json` and the Google Services Gradle plugin as usual for Firebase.
- Request `POST_NOTIFICATIONS` on Android 13+.

### 3. Optional notification chrome

`NotiveraConfig.pushTheme` takes **Android resource names** from your app `res/` (e.g. `ic_launcher_foreground`). Ignored on iOS.

### 4. Release / R8

Disable R8 full mode. Full mode can break Notivera’s Koin DI (e.g. `NoBeanDefFoundException` for `SDKViewModel`):

```properties
# android/gradle.properties
android.enableR8.fullMode=false
```

The plugin also ships `consumer-rules.pro` (`-keep class com.notivera.**`) when minify is enabled.

---

## iOS setup

Depends on [NotiveraSDK](https://github.com/Notivera/ios-spm-notivera) via Swift Package Manager (`from: 5.0.0`).

Minimum iOS version: **14.0**.

You do **not** call `setPushToken`, `isNotiveraMessage`, or `handlePushMessage` on iOS from Dart. APNs registration is buffered and flushed by the plugin around `initialize()`. Incoming Notivera payloads are handled in the **Notification Service Extension** (`request.isNotiveraRequest` → `NotiveraServiceExtension`), not in Flutter.

### 1. App Group (required)

Without an App Group the native SDK will `fatalError`. In Runner `Info.plist`:

```xml
<key>NotiveraAppGroup</key>
<string>group.com.yourcompany.yourapp</string>
```

Add the same App Group to Runner entitlements (`com.apple.security.application-groups`).

### 2. Capabilities and Info.plist

Enable **Push Notifications** and **Background Modes → Remote notifications**.

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used for geofenced campaigns.</string>
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

### 3. AppDelegate — cold-start notification taps (required)

When the user opens a push while the app is **terminated**, iOS can deliver
`userNotificationCenter(_:didReceive:)` before Dart `initialize()`. Capture that
tap in `AppDelegate` so the plugin can replay it after init (video / carousel / poll).

```swift
import Flutter
import notivera_flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Ensure this AppDelegate receives notification center callbacks early.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

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
}
```

`initialize()` flushes a buffered Notivera tap once the SDK is ready. If you install a custom `UNUserNotificationCenter` delegate after init, you can also call:

```swift
NotiveraFlutterPlugin.flushPendingNotificationResponse(delaySeconds: 0.5)
```

when the UI can present.

### 4. Pre-init lifecycle (automatic)

UIKit may deliver APNs registration, remote-notification, or background URL-session callbacks before Dart `initialize()`. The plugin buffers them and flushes in order after the native SDK is created. Non-Notivera remote payloads are not claimed. Look for `[NotiveraFlutterPlugin]` buffer/flush lines in the Xcode console when debugging registration.

### 5. Notification extensions (required)

Notivera rich push (video, carousel, interactive content described on [notivera.com](https://notivera.com/)) needs **both** extension targets in the **host** Xcode app. They are **not** shipped inside this Flutter plugin or the [NotiveraSDK](https://github.com/Notivera/ios-spm-notivera) binary — you add them in your Runner project (same as the native iOS SDK).

For portal credentials, campaign tooling, and partner API access, use **Developer Tools** on [notivera.com](https://notivera.com/) (**API Docs** / **Login**).

After you add `notivera_flutter` and build the iOS app **at least once**, Flutter’s SPM integration resolves [NotiveraSDK](https://github.com/Notivera/ios-spm-notivera) for the plugin/Runner automatically — you normally do **not** need to add that package URL again by hand.

You **still must** wire each extension target yourself:

1. **Link NotiveraSDK to the Service Extension and Content Extension**  
   In Xcode: select the extension target → **General** → **Frameworks and Libraries** → **+** → choose **NotiveraSDK** (from the already-resolved package).  
   Without this, `import NotiveraSDK` / `NotiveraServiceExtension` / `NotiveraCarouselNotificationContentViewController` will not build in the extension.
2. Use the **same App Group** as the Runner (`NotiveraAppGroup` in each extension `Info.plist` + App Groups entitlement on Runner **and** both extensions).
3. Embed the extension products in the Runner target (Xcode → Runner → General → Frameworks, Libraries, and Embedded Content / Embed App Extensions).

#### Notification Service Extension (required)

Downloads and prepares Notivera notification content before display (media / mutable content).

1. In Xcode: **File → New → Target… → Notification Service Extension**
2. Replace the generated class with a subclass of `NotiveraServiceExtension`. This is the iOS equivalent of Android’s Dart `isNotiveraMessage` / `handlePushMessage` — do **not** call those Flutter APIs for APNs:

```swift
import NotiveraSDK
import UserNotifications

class NotificationServiceExtension: NotiveraServiceExtension {
  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    if request.isNotiveraRequest {
      super.didReceive(request, withContentHandler: contentHandler)
    } else {
      contentHandler(request.content)
    }
  }
}
```

3. In the extension `Info.plist`:

```xml
<key>NSExtension</key>
<dict>
  <key>NSExtensionPointIdentifier</key>
  <string>com.apple.usernotifications.service</string>
  <key>NSExtensionPrincipalClass</key>
  <string>$(PRODUCT_MODULE_NAME).NotificationServiceExtension</string>
  <key>UNNotificationExtensionCategory</key>
  <array>
    <string>NSDKNotification</string>
    <string>PushologiesCarouselNotification</string>
  </array>
</dict>
<key>NotiveraAppGroup</key>
<string>group.com.yourcompany.yourapp</string>
```

Use the exact App Group string as the Runner. Do not leave a leading/trailing space on category names.

#### Notification Content Extension (required for carousel)

Renders the expandable carousel UI on the lock screen / notification shade.

1. In Xcode: **File → New → Target… → Notification Content Extension**
2. In the extension storyboard (`MainInterface` or equivalent), set the view controller’s **Custom Class** to:

   - Class: `NotiveraCarouselNotificationContentViewController`
   - Module: `NotiveraSDK`

   (You can leave a stub `UIViewController` Swift file unused; the storyboard must load the SDK class.)

3. In the extension `Info.plist`:

```xml
<key>NSExtension</key>
<dict>
  <key>NSExtensionAttributes</key>
  <dict>
    <key>UNNotificationExtensionCategory</key>
    <array>
      <string>PushologiesCarouselNotification</string>
    </array>
    <key>UNNotificationExtensionDefaultContentHidden</key>
    <string>NO</string>
    <key>UNNotificationExtensionInitialContentSizeRatio</key>
    <real>1</real>
    <key>UNNotificationExtensionUserInteractionEnabled</key>
    <true/>
  </dict>
  <key>NSExtensionMainStoryboard</key>
  <string>MainInterface</string>
  <key>NSExtensionPointIdentifier</key>
  <string>com.apple.usernotifications.content-extension</string>
</dict>
<key>NotiveraAppGroup</key>
<string>group.com.yourcompany.yourapp</string>
```

#### Categories summary

| Category | Used by |
|----------|---------|
| `NSDKNotification` | Service extension (standard / video-style Notivera pushes) |
| `PushologiesCarouselNotification` | Service + content extensions (carousel) |

Without these targets and App Group sharing, rich video/carousel presentation from the [Notivera](https://notivera.com/) platform will not work correctly on iOS.

---

## API overview

| Method | Purpose |
|--------|---------|
| `initialize(NotiveraConfig)` | Create / bind the native SDK |
| `requestAuthorisationPrompts()` | System permission prompts |
| `subscribeTag` / `unsubscribeTag` | Tag subscription |
| `setPushToken` | **Android only** — FCM token (not used on iOS) |
| `isNotiveraMessage` / `handlePushMessage` | **Android only** — forward FCM data from Dart. On **iOS**, do this in `NotiveraServiceExtension` with `request.isNotiveraRequest` (not Flutter) |
| `setCustomerId` / `getCustomerId` / `getDeviceId` | Identity |
| `updatePersonalisationVariables` / `getAllPersonalisations` | Personalisation |
| `showInAppNotification` / `closeNotificationView` | In-app |
| `events` | Stream of `NotiveraPushEvent` |

---

Plugin maintainers: see [MAINTAINERS.md](MAINTAINERS.md).
