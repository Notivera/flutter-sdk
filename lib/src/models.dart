/// Network constraint used when the Android SDK downloads campaign content.
/// Ignored on iOS.
enum ConnectionType { all, wifi, mobile, mobileRoaming, mobileNoRoaming }

/// Native SDK event delivered to Dart after [Notivera.initialize].
enum EventType { notificationTapped, videoClosed, inAppClosed, inAppCtaTapped }

/// Android-only notification icons/color for [NotiveraConfig.pushTheme].
///
/// Pass **Android resource names** from the host app `res/` (drawable, mipmap,
/// or color) — not Flutter asset paths and not `R.drawable` ints.
///
/// Example:
/// ```dart
/// NotiveraPushTheme(
///   smallIcon: 'ic_launcher',
///   largeIcon: 'ic_launcher',
///   color: 'notification_accent',
/// )
/// ```
///
/// Ignored on iOS (no equivalent on the native iOS SDK init).
class NotiveraPushTheme {
  const NotiveraPushTheme({
    this.smallIcon,
    this.largeIcon,
    this.color,
  });

  /// Android drawable or mipmap name used as the status-bar / small icon.
  final String? smallIcon;

  /// Android drawable or mipmap name used as the large notification icon.
  final String? largeIcon;

  /// Android color resource name used as the notification accent.
  final String? color;
}

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
    this.pushTheme,
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

  /// Android-only. Notification small/large icons and accent color.
  ///
  /// See [NotiveraPushTheme]. Has no effect on iOS.
  final NotiveraPushTheme? pushTheme;
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
