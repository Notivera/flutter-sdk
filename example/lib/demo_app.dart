import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notivera_flutter/notivera_flutter.dart';
import 'package:notivera_flutter_example/home_screen.dart';
import 'package:notivera_flutter_example/notivera_bootstrap.dart';
import 'package:notivera_flutter_example/offline_screen.dart';

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  int _index = 0;
  String _status = 'Initializing…';
  StreamSubscription<NotiveraPushEvent>? _events;

  @override
  void initState() {
    super.initState();
    _events = Notivera.instance.events.listen((NotiveraPushEvent event) {
      debugPrint(
        '[NotiveraDemo] TRIGGER: Notivera.events '
        'type=${event.eventType?.name} id=${event.id} '
        'title=${event.title} message=${event.message} '
        'targetUrl=${event.targetUrl} clientMetadata=${event.clientMetadata}',
      );
      if (!mounted) {
        return;
      }
      final String message =
          '${event.eventType?.name ?? 'event'} ${event.title ?? event.id}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });
    _initialize();
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    debugPrint('[NotiveraDemo] DemoApp._initialize() started');
    try {
      await initializeNotiveraDemo();
      if (!mounted) {
        return;
      }
      debugPrint('[NotiveraDemo] DemoApp ready');
      setState(() => _status = 'Ready');
    } catch (error, stack) {
      debugPrint('[NotiveraDemo] DemoApp initialize failed: $error');
      debugPrint('[NotiveraDemo] $stack');
      if (!mounted) {
        return;
      }
      setState(() => _status = 'Initialize failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notivera')),
      body: Column(
        children: <Widget>[
          if (_status != 'Ready')
            MaterialBanner(
              content: Text(_status),
              actions: const <Widget>[SizedBox.shrink()],
            ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const <Widget>[HomeScreen(), OfflineScreen()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int index) {
          setState(() => _index = index);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: 'Offline',
          ),
        ],
      ),
    );
  }
}
