import 'dart:async';

import 'messages.g.dart' as pigeon;
import 'models.dart';
import 'notivera_platform.dart';

/// Dart API for the native Notivera Android and iOS SDKs.
class Notivera {
  /// Creates a Notivera client.
  ///
  /// [platform] and [setUpFlutterApi] are for tests. Host apps should use
  /// the default constructor or [Notivera.instance].
  Notivera({NotiveraPlatform? platform, bool setUpFlutterApi = true})
    : _platform = platform ?? PigeonNotiveraPlatform() {
    if (setUpFlutterApi) {
      pigeon.NotiveraFlutterApi.setUp(_NotiveraFlutterApiHandler(_events));
    }
  }

  /// Shared client used by host apps.
  static final Notivera instance = Notivera();

  final NotiveraPlatform _platform;
  final StreamController<NotiveraPushEvent> _events =
      StreamController<NotiveraPushEvent>.broadcast();

  /// Native SDK events such as notification taps and in-app CTA presses.
  Stream<NotiveraPushEvent> get events => _events.stream;

  /// Initializes the native SDK.
  ///
  /// [NotiveraConfig.pushTheme] is **Android-only** (resource names for icons /
  /// accent color). It is stripped before the iOS channel call and ignored by
  /// the iOS plugin.
  Future<void> initialize(NotiveraConfig config) {
    return _platform.initialize(config);
  }

  Future<String?> getDeviceId() => _platform.getDeviceId();

  Future<String?> getCustomerId() => _platform.getCustomerId();

  Future<void> setCustomerId(String customerId) {
    return _platform.setCustomerId(customerId);
  }

  Future<String?> getSdkVersion() => _platform.getSdkVersion();

  Future<String> subscribeTag(String tag) => _platform.subscribeTag(tag);

  Future<String> unsubscribeTag(String tag) => _platform.unsubscribeTag(tag);

  Future<String> updatePersonalisationVariables(
    List<PersonalisationEntry> entries,
  ) {
    return _platform.updatePersonalisationVariables(entries);
  }

  Future<List<PersonalisationEntry>> getAllPersonalisations() {
    return _platform.getAllPersonalisations();
  }

  Future<String> showInAppNotification(String customIdentifier) {
    return _platform.showInAppNotification(customIdentifier);
  }

  Future<void> closeNotificationView() => _platform.closeNotificationView();

  Future<void> requestAuthorisationPrompts() {
    return _platform.requestAuthorisationPrompts();
  }

  /// Forwards an FCM token to the Android SDK. No-op on iOS (APNs is handled
  /// by the plugin application delegate).
  Future<void> setPushToken(String token) => _platform.setPushToken(token);

  Future<bool> isNotiveraMessage(Map<String, String> data) {
    return _platform.isNotiveraMessage(data);
  }

  Future<void> handlePushMessage(Map<String, String> data) {
    return _platform.handlePushMessage(data);
  }
}

class _NotiveraFlutterApiHandler implements pigeon.NotiveraFlutterApi {
  _NotiveraFlutterApiHandler(this._events);

  final StreamController<NotiveraPushEvent> _events;

  @override
  void onPushEvent(pigeon.PushEvent event) {
    _events.add(
      NotiveraPushEvent(
        id: event.id,
        eventType: event.eventType?.toPublic(),
        title: event.title,
        description: event.description,
        replacements: event.replacements,
        message: event.message,
        clientMetadata: event.clientMetadata,
        type: event.type,
        targetUrl: event.targetUrl,
      ),
    );
  }
}

extension on pigeon.EventType {
  EventType toPublic() {
    switch (this) {
      case pigeon.EventType.notificationTapped:
        return EventType.notificationTapped;
      case pigeon.EventType.videoClosed:
        return EventType.videoClosed;
      case pigeon.EventType.inAppClosed:
        return EventType.inAppClosed;
      case pigeon.EventType.inAppCtaTapped:
        return EventType.inAppCtaTapped;
    }
  }
}
