import 'package:flutter_test/flutter_test.dart';
import 'package:notivera_flutter/notivera_flutter.dart';
import 'package:notivera_flutter/src/notivera_platform.dart';

class _FakePlatform implements NotiveraPlatform {
  bool initialized = false;
  String? customerId = 'cust-1';
  final List<String> tags = <String>[];
  List<PersonalisationEntry> personalisations = <PersonalisationEntry>[
    const PersonalisationEntry(name: 'city', value: 'London'),
  ];
  Map<String, String>? lastPush;

  @override
  Future<void> initialize(NotiveraConfig config) async {
    initialized = true;
    customerId = config.customerId ?? customerId;
  }

  @override
  Future<String?> getDeviceId() async => 'device-1';

  @override
  Future<String?> getCustomerId() async => customerId;

  @override
  Future<void> setCustomerId(String customerId) async {
    this.customerId = customerId;
  }

  @override
  Future<String?> getSdkVersion() async => '5.0.0';

  @override
  Future<String> subscribeTag(String tag) async {
    tags.add(tag);
    return 'ok';
  }

  @override
  Future<String> unsubscribeTag(String tag) async {
    tags.remove(tag);
    return 'ok';
  }

  @override
  Future<String> updatePersonalisationVariables(
    List<PersonalisationEntry> entries,
  ) async {
    personalisations = entries;
    return 'ok';
  }

  @override
  Future<List<PersonalisationEntry>> getAllPersonalisations() async {
    return personalisations;
  }

  @override
  Future<String> showInAppNotification(String customIdentifier) async {
    return customIdentifier;
  }

  @override
  Future<void> closeNotificationView() async {}

  @override
  Future<void> requestAuthorisationPrompts() async {}

  @override
  Future<void> setPushToken(String token) async {}

  @override
  Future<bool> isNotiveraMessage(Map<String, String> data) async {
    return data.containsValue('NSDKNotification');
  }

  @override
  Future<void> handlePushMessage(Map<String, String> data) async {
    lastPush = data;
  }
}

void main() {
  test('initialize then subscribeTag', () async {
    final _FakePlatform fake = _FakePlatform();
    final Notivera sdk = Notivera(platform: fake, setUpFlutterApi: false);

    await sdk.initialize(
      const NotiveraConfig(
        apiKey: 'key',
        apiSecret: 'secret',
        appVersion: '1.0.0',
        tenantId: 'tenant',
      ),
    );
    final String result = await sdk.subscribeTag('news');

    expect(fake.initialized, isTrue);
    expect(result, 'ok');
    expect(fake.tags, <String>['news']);
  });

  test('identity helpers', () async {
    final _FakePlatform fake = _FakePlatform();
    final Notivera sdk = Notivera(platform: fake, setUpFlutterApi: false);

    expect(await sdk.getDeviceId(), 'device-1');
    await sdk.setCustomerId('user-9');
    expect(await sdk.getCustomerId(), 'user-9');
    expect(await sdk.getSdkVersion(), '5.0.0');
  });

  test('push message helpers', () async {
    final _FakePlatform fake = _FakePlatform();
    final Notivera sdk = Notivera(platform: fake, setUpFlutterApi: false);
    const Map<String, String> data = <String, String>{
      'type': 'NSDKNotification',
    };

    expect(await sdk.isNotiveraMessage(data), isTrue);
    await sdk.handlePushMessage(data);
    expect(fake.lastPush, data);
  });
}
