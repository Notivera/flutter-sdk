import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:notivera_flutter/notivera_flutter.dart';

const String demoApiKey = 'f81a8fda-9e38-4206-9e1d-cfee53f31e38';
const String demoApiSecret =
    'BvQyFm4gro+lfmYASgNXMIDrpgA/MpmyDtq0AmqyfJsX93f3GD4Y0/2+26XVO9uC1s7Oz1x6kV8gw1FWnq7moWQ7fG/aZ1GDP4uFbUHnsvfemxZJw3ibbKinu6S5vMuk2oElo8eUeDkGoD9Zvrt+vyqzZqvfaA452dp8mCak0H4=';
const String demoTenantId = '52e31515-ceda-4cdf-a7bf-63e9c8103085';
const String demoAppVersion = '5.0.1';

const String _logTag = '[NotiveraDemo]';

const NotiveraConfig demoNotiveraConfig = NotiveraConfig(
  apiKey: demoApiKey,
  apiSecret: demoApiSecret,
  appVersion: demoAppVersion,
  tenantId: demoTenantId,
  enableDebug: true,
  trackLocation: true,
  enableGeofence: true,
  downloadConnectionType: ConnectionType.wifi,
  inAppOpenDelayMs: 5000,
  // Android-only: adaptive launcher resources under res/mipmap + values.
  // Ignored on iOS (home-screen icon is AppIcon in Assets.xcassets).
  pushTheme: NotiveraPushTheme(
    smallIcon: 'ic_launcher_foreground',
    largeIcon: 'ic_launcher_round',
    color: 'ic_launcher_background',
  ),
);

bool _pushConfigured = false;

void _log(String message) {
  debugPrint('$_logTag $message');
}

/// Must be a top-level function and registered before [runApp].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _log('TRIGGER: onBackgroundMessage (background/terminated isolate)');
  try {
    await Firebase.initializeApp();
    // Background isolate gets a fresh plugin binding; native SDK may already
    // be alive in-process, but the Flutter bridge still needs initialize().
    await Notivera.instance.initialize(demoNotiveraConfig);
    await forwardRemoteMessage(message, source: 'onBackgroundMessage');
  } catch (error, stack) {
    _log('onBackgroundMessage failed: $error');
    _log('$stack');
  }
}

Future<void> initializeNotiveraDemo() async {
  _log(
    'initializeNotiveraDemo() started (platform=${Platform.operatingSystem})',
  );
  if (Platform.isIOS) {
    // APNs token / remote-notification / background URL-session callbacks may
    // arrive before this Dart initialize() returns. The iOS plugin buffers them
    // and flushes after native SDK init — watch Xcode for:
    // [NotiveraFlutterPlugin] ... buffering until initialize
    // [NotiveraFlutterPlugin] Pre-init flush complete token=… remote=…
    _log(
      'iOS: pre-init APNs/lifecycle callbacks are buffered natively; '
      'check Xcode console for [NotiveraFlutterPlugin] buffer/flush lines',
    );
  }
  _log(
    'Calling Notivera.initialize tenantId=$demoTenantId appVersion=$demoAppVersion',
  );
  await Notivera.instance.initialize(demoNotiveraConfig);
  _log('Notivera.initialize completed');
  if (Platform.isIOS) {
    _log(
      'iOS: native flush (if any) runs inside initialize; '
      'APNs is handled by the plugin — setPushToken is not used',
    );
  }

  await _configurePush();

  _log('Calling requestAuthorisationPrompts()');
  await Notivera.instance.requestAuthorisationPrompts();
  _log('requestAuthorisationPrompts() completed');

  final String? deviceId = await Notivera.instance.getDeviceId();
  _log('Device ID after init: ${deviceId ?? 'null'}');
  _log('initializeNotiveraDemo() finished');
}

Future<void> _configurePush() async {
  _log('_configurePush() entered (alreadyConfigured=$_pushConfigured)');
  if (_pushConfigured || !Platform.isAndroid) {
    _log(
      '_configurePush() skipped '
      '(alreadyConfigured=$_pushConfigured isAndroid=${Platform.isAndroid})',
    );
    _pushConfigured = true;
    return;
  }

  _log('Firebase.initializeApp()');
  await Firebase.initializeApp();
  _log('Firebase initialized');

  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  _log('Requesting notification permission');
  final NotificationSettings settings = await messaging.requestPermission();
  _log(
    'Permission result: authorizationStatus=${settings.authorizationStatus} '
    'alert=${settings.alert} badge=${settings.badge} sound=${settings.sound}',
  );

  final String? token = await messaging.getToken();
  if (token != null && token.isNotEmpty) {
    _log('FCM token received (${token.length} chars): $token');
    await Notivera.instance.setPushToken(token);
    _log('setPushToken() completed');
  } else {
    _log('FCM token is null/empty — setPushToken skipped');
  }

  messaging.onTokenRefresh.listen((String refreshedToken) {
    _log('FCM token refreshed: $refreshedToken');
    Notivera.instance
        .setPushToken(refreshedToken)
        .then((_) {
          _log('setPushToken() completed after refresh');
        })
        .catchError((Object error) {
          _log('setPushToken() after refresh failed: $error');
        });
  });

  _log('Registering FirebaseMessaging.onMessage listener');
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _log('TRIGGER: onMessage (foreground)');
    forwardRemoteMessage(message, source: 'onMessage');
  });

  _log('Registering FirebaseMessaging.onMessageOpenedApp listener');
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _log(
      'TRIGGER: onMessageOpenedApp (notification tap, background→foreground)',
    );
    forwardRemoteMessage(message, source: 'onMessageOpenedApp');
  });

  final RemoteMessage? initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    _log(
      'TRIGGER: getInitialMessage (app launched from terminated by notification)',
    );
    await forwardRemoteMessage(initialMessage, source: 'getInitialMessage');
  } else {
    _log('getInitialMessage() returned null (no launch-from-notification)');
  }

  _pushConfigured = true;
  _log('_configurePush() finished');
}

Future<void> forwardRemoteMessage(
  RemoteMessage message, {
  required String source,
}) async {
  _log('--- incoming push [$source] ---');
  _log('messageId=${message.messageId}');
  _log('from=${message.from}');
  _log('sentTime=${message.sentTime}');
  _log('collapseKey=${message.collapseKey}');
  _log('messageType=${message.messageType}');
  _log('category=${message.category}');
  _log('threadId=${message.threadId}');
  _log('ttl=${message.ttl}');
  _log('data keys=${message.data.keys.toList()}');
  _log('data payload=${message.data}');

  final RemoteNotification? notification = message.notification;
  if (notification != null) {
    _log(
      'notification.title=${notification.title} '
      'notification.body=${notification.body}',
    );
  } else {
    _log('notification block: null (data-only message)');
  }

  final Map<String, String> data = message.data.map(
    (String key, Object? value) => MapEntry(key, value.toString()),
  );

  if (data.isEmpty) {
    _log('Forward skipped: data map is empty');
    _log('--- end push [$source] ---');
    return;
  }

  final bool isNotivera = await Notivera.instance.isNotiveraMessage(data);
  _log('isNotiveraMessage=$isNotivera');

  if (isNotivera) {
    _log('Calling handlePushMessage() with data=$data');
    await Notivera.instance.handlePushMessage(data);
    _log('handlePushMessage() completed');
  } else {
    _log('Not a Notivera message — leaving for host/default handling');
  }
  _log('--- end push [$source] ---');
}
