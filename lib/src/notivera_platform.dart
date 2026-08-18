import 'messages.g.dart' as pigeon;
import 'models.dart';

abstract class NotiveraPlatform {
  Future<void> initialize(NotiveraConfig config);

  Future<String?> getDeviceId();

  Future<String?> getCustomerId();

  Future<void> setCustomerId(String customerId);

  Future<String?> getSdkVersion();

  Future<String> subscribeTag(String tag);

  Future<String> unsubscribeTag(String tag);

  Future<String> updatePersonalisationVariables(
    List<PersonalisationEntry> entries,
  );

  Future<List<PersonalisationEntry>> getAllPersonalisations();

  Future<String> showInAppNotification(String customIdentifier);

  Future<void> closeNotificationView();

  Future<void> requestAuthorisationPrompts();

  Future<void> setPushToken(String token);

  Future<bool> isNotiveraMessage(Map<String, String> data);

  Future<void> handlePushMessage(Map<String, String> data);
}

class PigeonNotiveraPlatform implements NotiveraPlatform {
  PigeonNotiveraPlatform({pigeon.NotiveraHostApi? api})
    : _api = api ?? pigeon.NotiveraHostApi();

  final pigeon.NotiveraHostApi _api;

  @override
  Future<void> initialize(NotiveraConfig config) {
    return _api.initialize(config.toPigeon());
  }

  @override
  Future<String?> getDeviceId() => _api.getDeviceId();

  @override
  Future<String?> getCustomerId() => _api.getCustomerId();

  @override
  Future<void> setCustomerId(String customerId) {
    return _api.setCustomerId(customerId);
  }

  @override
  Future<String?> getSdkVersion() => _api.getSdkVersion();

  @override
  Future<String> subscribeTag(String tag) => _api.subscribeTag(tag);

  @override
  Future<String> unsubscribeTag(String tag) => _api.unsubscribeTag(tag);

  @override
  Future<String> updatePersonalisationVariables(
    List<PersonalisationEntry> entries,
  ) {
    return _api.updatePersonalisationVariables(
      entries.map((PersonalisationEntry e) => e.toPigeon()).toList(),
    );
  }

  @override
  Future<List<PersonalisationEntry>> getAllPersonalisations() async {
    final List<pigeon.PersonalisationEntry> entries = await _api
        .getAllPersonalisations();
    return entries
        .map(
          (pigeon.PersonalisationEntry e) =>
              PersonalisationEntry(name: e.name, value: e.value),
        )
        .toList();
  }

  @override
  Future<String> showInAppNotification(String customIdentifier) {
    return _api.showInAppNotification(customIdentifier);
  }

  @override
  Future<void> closeNotificationView() => _api.closeNotificationView();

  @override
  Future<void> requestAuthorisationPrompts() {
    return _api.requestAuthorisationPrompts();
  }

  @override
  Future<void> setPushToken(String token) => _api.setPushToken(token);

  @override
  Future<bool> isNotiveraMessage(Map<String, String> data) {
    return _api.isNotiveraMessage(data);
  }

  @override
  Future<void> handlePushMessage(Map<String, String> data) {
    return _api.handlePushMessage(data);
  }
}

extension on NotiveraConfig {
  pigeon.NotiveraConfig toPigeon() {
    return pigeon.NotiveraConfig(
      apiKey: apiKey,
      apiSecret: apiSecret,
      appVersion: appVersion,
      tenantId: tenantId,
      customerId: customerId,
      inAppOpenDelayMs: inAppOpenDelayMs,
      enableDebug: enableDebug,
      trackLocation: trackLocation,
      enableGeofence: enableGeofence,
      downloadConnectionType: downloadConnectionType?.toPigeon(),
    );
  }
}

extension on ConnectionType {
  pigeon.ConnectionType toPigeon() {
    switch (this) {
      case ConnectionType.all:
        return pigeon.ConnectionType.all;
      case ConnectionType.wifi:
        return pigeon.ConnectionType.wifi;
      case ConnectionType.mobile:
        return pigeon.ConnectionType.mobile;
      case ConnectionType.mobileRoaming:
        return pigeon.ConnectionType.mobileRoaming;
      case ConnectionType.mobileNoRoaming:
        return pigeon.ConnectionType.mobileNoRoaming;
    }
  }
}

extension on PersonalisationEntry {
  pigeon.PersonalisationEntry toPigeon() {
    return pigeon.PersonalisationEntry(name: name, value: value);
  }
}
