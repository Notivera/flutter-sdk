import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:notivera_flutter/notivera_flutter.dart';

const String demoApiKey = 'f81a8fda-9e38-4206-9e1d-cfee53f31e38';
const String demoApiSecret =
    'BvQyFm4gro+lfmYASgNXMIDrpgA/MpmyDtq0AmqyfJsX93f3GD4Y0/2+26XVO9uC1s7Oz1x6kV8gw1FWnq7moWQ7fG/aZ1GDP4uFbUHnsvfemxZJw3ibbKinu6S5vMuk2oElo8eUeDkGoD9Zvrt+vyqzZqvfaA452dp8mCak0H4=';
const String demoTenantId = '52e31515-ceda-4cdf-a7bf-63e9c8103085';
const String demoAppVersion = '5.0.0';

const String _logTag = '[NotiveraDemo]';

/// Android-only MethodChannel to the example app's native FCM bridge.
const MethodChannel _androidFcmChannel = MethodChannel('com.notivera.demo/fcm');

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

Future<void> initializeNotiveraDemo() async {
  _log(
    'initializeNotiveraDemo() started (platform=${Platform.operatingSystem})',
  );
  _log(
    'Calling Notivera.initialize tenantId=$demoTenantId appVersion=$demoAppVersion',
  );
  await Notivera.instance.initialize(demoNotiveraConfig);
  _log('Notivera.initialize completed');

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

  _androidFcmChannel.setMethodCallHandler(_onAndroidFcmCall);

  _log('Signaling native FCM bridge ready');
  await _androidFcmChannel.invokeMethod<void>('ready');

  _log('Requesting FCM token via MethodChannel');
  final String? token = await _androidFcmChannel.invokeMethod<String>('getToken');
  if (token != null && token.isNotEmpty) {
    _log('FCM token received (${token.length} chars): $token');
    await Notivera.instance.setPushToken(token);
    _log('setPushToken() completed');
  } else {
    _log('FCM token is null/empty — setPushToken skipped');
  }

  _pushConfigured = true;
  _log('_configurePush() finished');
}

Future<void> _onAndroidFcmCall(MethodCall call) async {
  switch (call.method) {
    case 'onToken':
      final String token = call.arguments as String;
      _log('FCM token refreshed: $token');
      try {
        await Notivera.instance.setPushToken(token);
        _log('setPushToken() completed after refresh');
      } catch (error) {
        _log('setPushToken() after refresh failed: $error');
      }
    case 'onMessage':
      await forwardPushData(
        _stringMap(call.arguments),
        source: 'onMessage',
      );
    case 'onMessageOpened':
      await forwardPushData(
        _stringMap(call.arguments),
        source: 'onMessageOpened',
      );
    default:
      _log('Unknown FCM MethodChannel call: ${call.method}');
  }
}

Map<String, String> _stringMap(Object? arguments) {
  if (arguments is! Map) {
    return <String, String>{};
  }
  return arguments.map(
    (Object? key, Object? value) =>
        MapEntry(key.toString(), value?.toString() ?? ''),
  );
}

Future<void> forwardPushData(
  Map<String, String> data, {
  required String source,
}) async {
  _log('--- incoming push [$source] ---');
  _log('data keys=${data.keys.toList()}');
  _log('data payload=$data');

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
