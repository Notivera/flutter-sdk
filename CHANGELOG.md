## 5.0.1

* Flutter plugin wrapping Notivera Android SDK 5.x and iOS NotiveraSDK (SPM) via Pigeon.
* Android: FCM is host-owned (`setPushToken` / `handlePushMessage`); consumer ProGuard rules; document `android.enableR8.fullMode=false`.
* iOS: APNs buffering and flush around `initialize`; cold-start tap capture via `NotiveraFlutterPlugin.captureNotificationResponse`; process-lifetime native SDK retention.
* Consumer README for integrators; maintainer notes in `MAINTAINERS.md`.