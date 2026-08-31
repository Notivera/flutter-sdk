import Foundation
import NotiveraSDK
import UIKit
import UserNotifications

/// Example-only: buffers offline-demo category taps for cold start.
/// Real Notivera (NSDKNotification / carousel) taps are handled by
/// `NotiveraFlutterPlugin.captureNotificationResponse`.
enum PendingNotificationTap {
  private static var userInfo: [AnyHashable: Any]?
  private static var categoryIdentifier: String?

  private static let offlineCategories: Set<String> = [
    "VideoWithButtonOne",
    "VideoWithButtonTwo",
    "Poll",
    "CategoryExtension",
  ]

  static func capture(_ response: UNNotificationResponse) {
    let category = response.notification.request.content.categoryIdentifier
    guard offlineCategories.contains(category) else {
      return
    }
    userInfo = response.notification.request.content.userInfo
    categoryIdentifier = category
    NSLog("[PendingNotificationTap] Captured offline tap category=%@", category)
  }

  static func flush(using sdk: Notivera) {
    guard let categoryIdentifier else {
      return
    }
    let userInfo = self.userInfo ?? [:]
    self.userInfo = nil
    self.categoryIdentifier = nil

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      NSLog(
        "[PendingNotificationTap] Flushing offline tap category=%@",
        categoryIdentifier
      )
      OfflineDemoNotificationDelegate.handleLaunchTap(
        sdk: sdk,
        categoryIdentifier: categoryIdentifier,
        userInfo: userInfo
      )
    }
  }
}
