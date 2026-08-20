import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notivera_flutter/notivera_flutter.dart';

class _DemoNotificationItem {
  const _DemoNotificationItem({
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;
}

const List<_DemoNotificationItem> _demoNotifications =
    <_DemoNotificationItem>[
      _DemoNotificationItem(
        title: 'Notification 1',
        assetPath: 'assets/kit_launch_notification.json',
      ),
      _DemoNotificationItem(
        title: 'Notification 2',
        assetPath: 'assets/video_goal_notification.json',
      ),
      _DemoNotificationItem(
        title: 'Notification 3',
        assetPath: 'assets/starting_lineup.json',
      ),
      _DemoNotificationItem(
        title: 'Carousel',
        assetPath: 'assets/carousel_notification.json',
      ),
    ];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _showDemoNotification(
    BuildContext context,
    _DemoNotificationItem item,
  ) async {
    debugPrint(
      '[NotiveraDemo] TRIGGER: Home demo tap title=${item.title} '
      'asset=${item.assetPath}',
    );
    try {
      final String jsonString = await rootBundle.loadString(item.assetPath);
      debugPrint(
        '[NotiveraDemo] Loaded demo JSON (${jsonString.length} chars) '
        'for ${item.title}',
      );
      final Map<String, String> payload = <String, String>{
        'root': jsonString,
        'PSDKDemoNotification': 'true',
      };
      debugPrint(
        '[NotiveraDemo] Calling handlePushMessage for offline demo '
        '(PSDKDemoNotification=true)',
      );
      await Notivera.instance.handlePushMessage(payload);
      debugPrint('[NotiveraDemo] Offline demo handlePushMessage completed');
    } catch (error) {
      debugPrint('[NotiveraDemo] Offline demo failed: $error');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to show ${item.title}: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Select an experience',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Notifications (4)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        for (final _DemoNotificationItem item in _demoNotifications)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(item.title),
              subtitle: const Text('Tap to view notification'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDemoNotification(context, item),
            ),
          ),
      ],
    );
  }
}
