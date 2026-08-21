import 'dart:io';

import 'package:flutter/services.dart';

/// Talks to native `OfflineDemoPlugin` (UIKit/AVKit), matching ios-sdk offline demos.
class OfflineIosNativeDemo {
  OfflineIosNativeDemo._();

  static const MethodChannel _channel = MethodChannel('com.notivera.demo/offline');

  static const List<OfflineIosDemoItem> demos = <OfflineIosDemoItem>[
    OfflineIosDemoItem(
      title: 'Notification 1',
      categoryIdentifier: 'VideoWithButtonOne',
    ),
    OfflineIosDemoItem(
      title: 'Notification 2',
      categoryIdentifier: 'VideoWithButtonTwo',
    ),
    OfflineIosDemoItem(
      title: 'Notification 3',
      categoryIdentifier: 'Poll',
    ),
    OfflineIosDemoItem(
      title: 'Carousel',
      categoryIdentifier: 'CategoryExtension',
    ),
  ];

  static Future<void> installDelegate() async {
    if (!Platform.isIOS) {
      return;
    }
    await _channel.invokeMethod<void>('installDelegate');
  }

  static Future<void> schedule(OfflineIosDemoItem item) async {
    await _channel.invokeMethod<void>('schedule', <String, String>{
      'category': item.categoryIdentifier,
    });
  }
}

class OfflineIosDemoItem {
  const OfflineIosDemoItem({
    required this.title,
    required this.categoryIdentifier,
  });

  final String title;
  final String categoryIdentifier;
}
