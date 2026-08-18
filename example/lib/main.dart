import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:notivera_flutter/notivera_flutter.dart';

const String _demoApiKey = 'f81a8fda-9e38-4206-9e1d-cfee53f31e38';
const String _demoApiSecret =
    'BvQyFm4gro+lfmYASgNXMIDrpgA/MpmyDtq0AmqyfJsX93f3GD4Y0/2+26XVO9uC1s7Oz1x6kV8gw1FWnq7moWQ7fG/aZ1GDP4uFbUHnsvfemxZJw3ibbKinu6S5vMuk2oElo8eUeDkGoD9Zvrt+vyqzZqvfaA452dp8mCak0H4=';
const String _demoTenantId = '52e31515-ceda-4cdf-a7bf-63e9c8103085';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _apiKey = TextEditingController(text: _demoApiKey);
  final TextEditingController _apiSecret = TextEditingController(
    text: _demoApiSecret,
  );
  final TextEditingController _tenantId = TextEditingController(
    text: _demoTenantId,
  );
  final TextEditingController _appVersion = TextEditingController(
    text: '5.0.0',
  );
  final TextEditingController _tag = TextEditingController(text: 'news');
  final List<String> _events = <String>[];
  String _status = 'Not initialized';
  bool _busy = false;
  bool _pushConfigured = false;

  @override
  void initState() {
    super.initState();
    Notivera.instance.events.listen((NotiveraPushEvent event) {
      setState(() {
        _events.insert(
          0,
          '${event.eventType?.name ?? 'event'} ${event.title ?? event.id}',
        );
      });
    });
  }

  @override
  void dispose() {
    _apiKey.dispose();
    _apiSecret.dispose();
    _tenantId.dispose();
    _appVersion.dispose();
    _tag.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _busy = true);
    try {
      await Notivera.instance.initialize(
        NotiveraConfig(
          apiKey: _apiKey.text.trim(),
          apiSecret: _apiSecret.text.trim(),
          appVersion: _appVersion.text.trim(),
          tenantId: _tenantId.text.trim(),
        ),
      );
      await _configurePush();
      await Notivera.instance.requestAuthorisationPrompts();
      final String? deviceId = await Notivera.instance.getDeviceId();
      setState(
        () => _status = 'Initialized. Device: ${deviceId ?? 'unknown'}',
      );
    } catch (error) {
      setState(() => _status = 'Initialize failed: $error');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _configurePush() async {
    if (_pushConfigured || !Platform.isAndroid) {
      _pushConfigured = true;
      return;
    }

    await Firebase.initializeApp();
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    final String? token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await Notivera.instance.setPushToken(token);
    }

    FirebaseMessaging.onMessage.listen(_forwardRemoteMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_forwardRemoteMessage);

    final RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      await _forwardRemoteMessage(initialMessage);
    }

    _pushConfigured = true;
  }

  Future<void> _forwardRemoteMessage(RemoteMessage message) async {
    final Map<String, String> data = message.data.map(
      (String key, Object? value) => MapEntry(key, value.toString()),
    );

    if (data.isEmpty) {
      return;
    }

    if (await Notivera.instance.isNotiveraMessage(data)) {
      await Notivera.instance.handlePushMessage(data);
    }
  }

  Future<void> _subscribe() async {
    setState(() => _busy = true);
    try {
      final String result = await Notivera.instance.subscribeTag(
        _tag.text.trim(),
      );
      setState(() => _status = 'Subscribed: $result');
    } catch (error) {
      setState(() => _status = 'Subscribe failed: $error');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Notivera')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextField(
              controller: _apiKey,
              decoration: const InputDecoration(labelText: 'API key'),
            ),
            TextField(
              controller: _apiSecret,
              decoration: const InputDecoration(labelText: 'API secret'),
              obscureText: true,
            ),
            TextField(
              controller: _tenantId,
              decoration: const InputDecoration(labelText: 'Tenant ID'),
            ),
            TextField(
              controller: _appVersion,
              decoration: const InputDecoration(labelText: 'App version'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _initialize,
              child: const Text('Initialize'),
            ),
            TextField(
              controller: _tag,
              decoration: const InputDecoration(labelText: 'Tag'),
            ),
            FilledButton(
              onPressed: _busy ? null : _subscribe,
              child: const Text('Subscribe tag'),
            ),
            const SizedBox(height: 16),
            Text(_status),
            const SizedBox(height: 16),
            const Text('Events'),
            for (final String event in _events.take(20)) Text(event),
          ],
        ),
      ),
    );
  }
}
