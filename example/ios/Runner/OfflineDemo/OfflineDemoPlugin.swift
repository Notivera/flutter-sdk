import Flutter
import NotiveraSDK
import UIKit
import UserNotifications

/// Example-only bridge: schedules native offline demos and installs a notification
/// delegate that presents native AVKit / UIKit experiences on notification tap
/// (same categories as ios-sdk/App offline demos).
enum OfflineDemoPlugin {
  static let channelName = "com.notivera.demo/offline"
  private static weak var sdk: Notivera?

  static func register(messenger: FlutterBinaryMessenger) {
    NotificationCenter.default.addObserver(
      forName: Notification.Name("NotiveraFlutterPluginDidInitialize"),
      object: nil,
      queue: .main
    ) { notification in
      sdk = notification.object as? Notivera
      NSLog("[OfflineDemo] Captured Notivera SDK from plugin init notification")
    }

    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "installDelegate":
        installDelegate()
        result(nil)
      case "schedule":
        guard
          let args = call.arguments as? [String: Any],
          let category = args["category"] as? String
        else {
          result(
            FlutterError(code: "bad-args", message: "Expected category", details: nil)
          )
          return
        }
        do {
          try OfflineDemoScheduler.schedule(categoryIdentifier: category)
          result(nil)
        } catch {
          result(
            FlutterError(
              code: "schedule-failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func installDelegate() {
    guard let sdk else {
      NSLog("[OfflineDemo] installDelegate skipped — Notivera SDK not ready yet")
      return
    }
    registerOfflineCategories()
    sdk.setNotiveraUserNotificationDelegate(
      delegate: OfflineDemoNotificationDelegate(sdk: sdk)
    )
    NSLog("[OfflineDemo] OfflineDemoNotificationDelegate installed")
  }

  private static func registerOfflineCategories() {
    let center = UNUserNotificationCenter.current()
    center.getNotificationCategories { existing in
      var categories = existing
      let carousel = UNNotificationCategory(
        identifier: "CategoryExtension",
        actions: [
          UNNotificationAction(identifier: "next", title: "→", options: []),
          UNNotificationAction(identifier: "previous", title: "←", options: []),
        ],
        intentIdentifiers: [],
        options: []
      )
      categories.insert(carousel)
      for id in ["VideoWithButtonOne", "VideoWithButtonTwo", "Poll"] {
        categories.insert(
          UNNotificationCategory(
            identifier: id,
            actions: [],
            intentIdentifiers: [],
            options: []
          )
        )
      }
      center.setNotificationCategories(categories)
    }
  }
}
