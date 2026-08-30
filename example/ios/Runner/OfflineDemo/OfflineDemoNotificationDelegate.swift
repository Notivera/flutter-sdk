import NotiveraSDK
import UIKit
import UserNotifications

/// Same offline tap routing as ios-sdk/App `AppUserNotificationDelegate`:
/// Notivera categories → SDK; offline categories → OfflineVideo / OfflineCarousel VCs.
final class OfflineDemoNotificationDelegate: NotiveraUserNotificationDelegate {
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if notification.request.isNotiveraRequest {
      super.userNotificationCenter(
        center,
        willPresent: notification,
        withCompletionHandler: completionHandler
      )
    } else {
      completionHandler([.banner, .list, .sound])
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if response.notification.request.isNotiveraRequest {
      super.userNotificationCenter(
        center,
        didReceive: response,
        handleTargetUrl: true,
        withCompletionHandler: completionHandler
      )
      return
    }

    loadOfflineNotifications(
      identifier: response.notification.request.content.categoryIdentifier
    )
    completionHandler()
  }

  /// Replay a cold-start tap after SDK + UI are ready (offline demo categories).
  static func handleLaunchTap(
    sdk: Notivera,
    categoryIdentifier: String,
    userInfo: [AnyHashable: Any]
  ) {
    // Notivera remote categories are owned by NotiveraFlutterPlugin.
    if categoryIdentifier == "NSDKNotification"
      || categoryIdentifier == "PushologiesCarouselNotification"
      || sdk.isNotiveraNotification(userInfo: userInfo)
    {
      return
    }

    let delegate = OfflineDemoNotificationDelegate(sdk: sdk)
    delegate.loadOfflineNotifications(identifier: categoryIdentifier)
  }

  fileprivate func loadOfflineNotifications(identifier: String) {
    guard let notificationIdentifier = NotificationIdentifier(rawValue: identifier) else {
      NSLog("[OfflineDemo] Unknown offline category %@", identifier)
      return
    }
    switch notificationIdentifier {
    case .videoWithButtonOne, .videoWithButtonTwo:
      loadVideoView(isVideoWithPoll: false, notificationIdentifier: notificationIdentifier)
    case .poll:
      loadVideoView(isVideoWithPoll: true, notificationIdentifier: notificationIdentifier)
    case .carousel:
      let navigationController = UINavigationController(
        rootViewController: OfflineCarouselViewController.loadFromStoryboard()
      )
      navigationController.modalPresentationStyle = .overFullScreen
      UIApplication.topViewController()?.present(
        navigationController,
        animated: true,
        completion: nil
      )
    }
  }

  private func loadVideoView(
    isVideoWithPoll: Bool,
    notificationIdentifier: NotificationIdentifier
  ) {
    let videoViewController = OfflineVideoViewController.loadFromStoryboard { coder in
      let viewModel = DefaultVideoViewModel(
        isVideoWithPoll: isVideoWithPoll,
        notificationIdentifier: notificationIdentifier
      )
      return OfflineVideoViewController(coder: coder, viewModel: viewModel)
    }
    let navigationController = UINavigationController(rootViewController: videoViewController)
    navigationController.modalPresentationStyle = .overFullScreen
    UIApplication.topViewController()?.present(
      navigationController,
      animated: true,
      completion: nil
    )
  }
}
