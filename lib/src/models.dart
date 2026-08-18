/// Network constraint used when the Android SDK downloads campaign content.
/// Ignored on iOS.
enum ConnectionType { all, wifi, mobile, mobileRoaming, mobileNoRoaming }

/// Native SDK event delivered to Dart after [Notivera.initialize].
enum EventType { notificationTapped, videoClosed, inAppClosed, inAppCtaTapped }

/// Credentials and options forwarded to the native Notivera SDKs.
class NotiveraConfig {
  const NotiveraConfig({
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

  final String apiKey;
  final String apiSecret;
  final String appVersion;
  final String tenantId;
  final String? customerId;
  final int? inAppOpenDelayMs;

  /// Android-only. Enables native SDK debug logs.
  final bool? enableDebug;

  /// Android-only. Enables location tracking.
  final bool? trackLocation;

  /// Android-only. Enables geofence campaigns.
  final bool? enableGeofence;

  /// Android-only. Restricts content downloads to a connection type.
  final ConnectionType? downloadConnectionType;
}

/// A personalisation schema name/value pair.
class PersonalisationEntry {
  const PersonalisationEntry({required this.name, this.value});

  final String name;
  final String? value;
}

/// An event emitted by the native SDK.
class NotiveraPushEvent {
  const NotiveraPushEvent({
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

  final String id;
  final EventType? eventType;
  final String? title;
  final String? description;
  final String? replacements;
  final String? message;
  final String? clientMetadata;
  final String? type;
  final String? targetUrl;
}
