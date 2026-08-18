import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartPackageName: 'notivera_flutter',
    kotlinOut:
        'android/src/main/kotlin/com/notivera/notivera_flutter/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.notivera.notivera_flutter'),
    swiftOut: 'ios/notivera_flutter/Sources/notivera_flutter/Messages.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
enum ConnectionType { all, wifi, mobile, mobileRoaming, mobileNoRoaming }

enum EventType { notificationTapped, videoClosed, inAppClosed, inAppCtaTapped }

class NotiveraConfig {
  NotiveraConfig({
    required this.apiKey,
    required this.apiSecret,
    required this.appVersion,
    required this.tenantId,
    this.customerId,
    this.inAppOpenDelayMs,
    this.enableDebug,
    this.trackLocation,
    this.enableGeofence,
    this.downloadConnectionType,
  });

  String apiKey;
  String apiSecret;
  String appVersion;
  String tenantId;
  String? customerId;
  int? inAppOpenDelayMs;
  bool? enableDebug;
  bool? trackLocation;
  bool? enableGeofence;
  ConnectionType? downloadConnectionType;
}

class PersonalisationEntry {
  PersonalisationEntry({required this.name, this.value});

  String name;
  String? value;
}

class PushEvent {
  PushEvent({
    required this.id,
    this.eventType,
    this.title,
    this.description,
    this.replacements,
    this.message,
    this.clientMetadata,
    this.type,
    this.targetUrl,
  });

  String id;
  EventType? eventType;
  String? title;
  String? description;
  String? replacements;
  String? message;
  String? clientMetadata;
  String? type;
  String? targetUrl;
}

@HostApi()
abstract class NotiveraHostApi {
  void initialize(NotiveraConfig config);

  String? getDeviceId();

  String? getCustomerId();

  void setCustomerId(String customerId);

  String? getSdkVersion();

  @async
  String subscribeTag(String tag);

  @async
  String unsubscribeTag(String tag);

  @async
  String updatePersonalisationVariables(List<PersonalisationEntry> entries);

  List<PersonalisationEntry> getAllPersonalisations();

  @async
  String showInAppNotification(String customIdentifier);

  void closeNotificationView();

  @async
  void requestAuthorisationPrompts();

  void setPushToken(String token);

  bool isNotiveraMessage(Map<String, String> data);

  void handlePushMessage(Map<String, String> data);
}

@FlutterApi()
abstract class NotiveraFlutterApi {
  void onPushEvent(PushEvent event);
}
