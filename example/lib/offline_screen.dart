import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notivera_flutter/notivera_flutter.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  final TextEditingController _tag = TextEditingController();
  String _deviceId = 'Loading…';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  @override
  void dispose() {
    _tag.dispose();
    super.dispose();
  }

  String get _deviceOs {
    if (Platform.isIOS) {
      return 'iOS ${Platform.operatingSystemVersion}';
    }
    if (Platform.isAndroid) {
      return 'Android ${Platform.operatingSystemVersion}';
    }
    return Platform.operatingSystem;
  }

  Future<void> _loadDeviceId() async {
    try {
      final String? deviceId = await Notivera.instance.getDeviceId();
      if (!mounted) {
        return;
      }
      setState(() => _deviceId = deviceId ?? 'unknown');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _deviceId = 'unavailable');
    }
  }

  Future<void> _submitTag() async {
    final String tag = _tag.text.trim();
    debugPrint('[NotiveraDemo] TRIGGER: subscribeTag tag="$tag"');
    if (tag.isEmpty) {
      debugPrint('[NotiveraDemo] subscribeTag skipped: empty tag');
      _showMessage('Please enter a tag name!');
      return;
    }

    setState(() => _busy = true);
    try {
      final String result = await Notivera.instance.subscribeTag(tag);
      debugPrint(
        '[NotiveraDemo] subscribeTag success result="$result" tag="$tag"',
      );
      _tag.clear();
      _showMessage('Tag created successfully');
    } catch (error, stack) {
      if (error is PlatformException) {
        debugPrint(
          '[NotiveraDemo] subscribeTag failed tag="$tag" '
          'code=${error.code} message=${error.message} details=${error.details}',
        );
      } else {
        debugPrint('[NotiveraDemo] subscribeTag failed tag="$tag" error=$error');
      }
      debugPrint('[NotiveraDemo] $stack');
      _showMessage('Failed to create tag, please try again!');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _copyDeviceId() async {
    await Clipboard.setData(ClipboardData(text: _deviceId));
    _showMessage('Copied to Clipboard');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Tags', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _tag,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    hintText: 'Enter Tag here',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _submitTag,
                  child: const Text('SUBMIT'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('Device ID'),
            subtitle: Text(_deviceId),
            onLongPress: _copyDeviceId,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('Device OS'),
            subtitle: Text(_deviceOs),
          ),
        ),
      ],
    );
  }
}
