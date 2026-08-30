import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    OfflineDemoPlugin.register(messenger: engineBridge.applicationRegistrar.messenger())
  }

  // Diagnostic only — print APNs result; no Notivera forward yet.
  // override func application(
  //   _ application: UIApplication,
  //   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  // ) {
  //   let hex = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
  //   NSLog(
  //     "[AppDelegate] APNs device token received (%d bytes): %@",
  //     deviceToken.count,
  //     hex
  //   )
  //   super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  // }

  // override func application(
  //   _ application: UIApplication,
  //   didFailToRegisterForRemoteNotificationsWithError error: Error
  // ) {
  //   NSLog(
  //     "[AppDelegate] APNs registration failed: %@",
  //     error.localizedDescription
  //   )
  //   super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  // }
}
