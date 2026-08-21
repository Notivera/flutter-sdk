import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notivera_flutter/notivera_flutter.dart';
import 'package:notivera_flutter_example/offline_ios_native_demo.dart';

class _AndroidDemoItem {
  const _AndroidDemoItem({
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;
}

const List<_AndroidDemoItem> _androidDemos = <_AndroidDemoItem>[
  _AndroidDemoItem(
    title: 'Notification 1',
    assetPath: 'assets/kit_launch_notification.json',
  ),
  _AndroidDemoItem(
    title: 'Notification 2',
    assetPath: 'assets/video_goal_notification.json',
  ),
  _AndroidDemoItem(
    title: 'Notification 3',
    assetPath: 'assets/starting_lineup.json',
  ),
  _AndroidDemoItem(
    title: 'Carousel',
    assetPath: 'assets/carousel_notification.json',
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _showAndroidDemo(
    BuildContext context,
    _AndroidDemoItem item,
  ) async {
    debugPrint(
      '[NotiveraDemo] TRIGGER: Android offline demo title=${item.title}',
    );
    try {
      final String jsonString = await rootBundle.loadString(item.assetPath);
      await Notivera.instance.handlePushMessage(<String, String>{
        'root': jsonString,
        'PSDKDemoNotification': 'true',
      });
    } catch (error) {
      debugPrint('[NotiveraDemo] Android offline demo failed: $error');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to show ${item.title}: $error')),
      );
    }
  }

  Future<void> _showIosDemo(
    BuildContext context,
    OfflineIosDemoItem item,
  ) async {
    debugPrint(
      '[NotiveraDemo] TRIGGER: iOS offline schedule '
      'category=${item.categoryIdentifier}',
    );
    try {
      await OfflineIosNativeDemo.schedule(item);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.title} posted — tap the notification to open',
          ),
        ),
      );
    } catch (error) {
      debugPrint('[NotiveraDemo] iOS offline schedule failed: $error');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule ${item.title}: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool ios = Platform.isIOS;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Select an experience',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          ios
              ? 'Notifications (4) — tap to schedule; open from the banner'
              : 'Notifications (4) — Android offline SDK demos',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        if (ios)
          for (final OfflineIosDemoItem item in OfflineIosNativeDemo.demos)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(
                  'Tap to post notification · ${item.categoryIdentifier}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showIosDemo(context, item),
              ),
            )
        else
          for (final _AndroidDemoItem item in _androidDemos)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(item.title),
                subtitle: const Text('Tap to view notification'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAndroidDemo(context, item),
              ),
            ),
      ],
    );
  }
}
