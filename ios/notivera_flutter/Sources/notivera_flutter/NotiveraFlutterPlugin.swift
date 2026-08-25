import Flutter
import NotiveraSDK
import UIKit

public class NotiveraFlutterPlugin: NSObject, FlutterPlugin, NotiveraHostApi {
  private var sdk: Notivera?
  private var flutterApi: NotiveraFlutterApi?
  private var eventObservers: [Any] = []

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NotiveraFlutterPlugin()
    instance.flutterApi = NotiveraFlutterApi(binaryMessenger: registrar.messenger())
    NotiveraHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    registrar.addApplicationDelegate(instance)
  }

  public func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) -> Bool {
    NSLog(
      "[NotiveraFlutterPlugin] APNs device token received (%d bytes)",
      deviceToken.count
    )
    sdk?.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
    return true
  }

  public func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) -> Bool {
    NSLog(
      "[NotiveraFlutterPlugin] APNs registration failed: %@",
      error.localizedDescription
    )
    sdk?.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error,
      completion: nil
    )
    return true
  }

  public func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) -> Bool {
    guard let sdk, sdk.isNotiveraNotification(userInfo: userInfo) else {
      return false
    }
    sdk.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
    return true
  }

  public func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) -> Bool {
    guard let sdk else {
      return false
    }
    sdk.application(
      application,
      handleEventsForBackgroundURLSession: identifier,
      completionHandler: completionHandler
    )
    return true
  }

  func initialize(config: NotiveraConfig) throws {
    // config.pushTheme is Android-only (resource names → NotiveraPushTheme).
    // The iOS SDK has no theme parameter on init; icons come from the app bundle.
    let instance = Notivera(
      apiKey: config.apiKey,
      apiSecret: config.apiSecret,
      inAppOpenDelay: Int(config.inAppOpenDelayMs ?? 0),
      tenantID: config.tenantId
    )
    instance.customerID = config.customerId
    sdk = instance
    // Re-assert after Flutter/Firebase plugins may have claimed the center.
    instance.setNotiveraUserNotificationDelegate(
      delegate: NotiveraUserNotificationDelegate(sdk: instance)
    )
    startObservingEvents()
    NotificationCenter.default.post(
      name: Notification.Name("NotiveraFlutterPluginDidInitialize"),
      object: instance
    )
  }

  func getDeviceId() throws -> String? {
    try requireSDK().deviceID?.uuidString
  }

  func getCustomerId() throws -> String? {
    try requireSDK().customerID
  }

  func setCustomerId(customerId: String) throws {
    let sdk = try requireSDK()
    sdk.customerID = customerId
  }

  func getSdkVersion() throws -> String? {
    try requireSDK().sdkVersion
  }

  func subscribeTag(
    tag: String,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    do {
      let sdk = try requireSDK()
      sdk.subscribeTag(tag: tag)
      completion(.success("ok"))
    } catch {
      completion(.failure(error))
    }
  }

  func unsubscribeTag(
    tag: String,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    do {
      let sdk = try requireSDK()
      sdk.unsubscribeTag(tag: tag)
      completion(.success("ok"))
    } catch {
      completion(.failure(error))
    }
  }

  func updatePersonalisationVariables(
    entries: [PersonalisationEntry],
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    do {
      let sdk = try requireSDK()
      let schemas = entries.map {
        NotiveraPersonalisationSchema(name: $0.name, value: $0.value ?? "")
      }
      try sdk.updatePersonalisationVariables(schema: schemas)
      completion(.success("ok"))
    } catch {
      completion(
        .failure(
          PigeonError(code: "sdk-error", message: error.localizedDescription, details: nil)
        )
      )
    }
  }

  func getAllPersonalisations() throws -> [PersonalisationEntry] {
    try requireSDK().getAllPersonalisations()?.compactMap { schema in
      guard let name = schema.name else { return nil }
      return PersonalisationEntry(name: name, value: schema.value)
    } ?? []
  }

  func showInAppNotification(
    customIdentifier: String,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    do {
      let sdk = try requireSDK()
      sdk.showInAppNotification(with: customIdentifier)
      completion(.success("ok"))
    } catch {
      completion(.failure(error))
    }
  }

  func closeNotificationView() throws {
    try requireSDK().closeNotificationView()
  }

  func requestAuthorisationPrompts(
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    Task { @MainActor in
      do {
        let sdk = try self.requireSDK()
        await sdk.showAuthorisationPrompts()
        // Authorization / Firebase can replace the notification center delegate.
        sdk.setNotiveraUserNotificationDelegate(
          delegate: NotiveraUserNotificationDelegate(sdk: sdk)
        )
        NotificationCenter.default.post(
          name: Notification.Name("NotiveraFlutterPluginDidInitialize"),
          object: sdk
        )
        completion(.success(()))
      } catch {
        completion(.failure(error))
      }
    }
  }

  func setPushToken(token: String) throws {
    _ = token
  }

  func isNotiveraMessage(data: [String: String]) throws -> Bool {
    try requireSDK().isNotiveraNotification(userInfo: data)
  }

  func handlePushMessage(data: [String: String]) throws {
    let sdk = try requireSDK()
    if data["PSDKDemoNotification"] != nil {
      throw PigeonError(
        code: "unsupported-on-ios",
        message:
          "Offline demo payloads (PSDKDemoNotification) are Android-only. "
          + "iOS offline demos use local UNNotifications in the native app, not the SDK push pipeline.",
        details: data
      )
    }
    let userInfo = Dictionary<AnyHashable, Any>(
      uniqueKeysWithValues: data.map { ($0.key, $0.value as Any) }
    )
    guard sdk.isNotiveraNotification(userInfo: userInfo) else {
      throw PigeonError(
        code: "not-notivera-message",
        message:
          "Payload is not a Notivera iOS notification. Expected aps.category "
          + "NSDKNotification or PushologiesCarouselNotification.",
        details: data
      )
    }
    sdk.application(
      UIApplication.shared,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: { _ in }
    )
  }

  private func requireSDK() throws -> Notivera {
    guard let sdk else {
      throw PigeonError(
        code: "not-initialized",
        message: "Call initialize() before using the Notivera SDK.",
        details: nil
      )
    }
    return sdk
  }

  private func startObservingEvents() {
    eventObservers.forEach { NotificationCenter.default.removeObserver($0) }
    eventObservers.removeAll()

    let subscriptions: [(String, EventType)] = [
      (Notivera.eventNotificationTapped, .notificationTapped),
      (Notivera.videoCloseButtonTapped, .videoClosed),
      (Notivera.inAppClosedButtonTapped, .inAppClosed),
      (Notivera.inAppCtaTapped, .inAppCtaTapped),
    ]

    for (name, eventType) in subscriptions {
      let observer = NotificationCenter.default.addObserver(
        forName: NSNotification.Name(name),
        object: nil,
        queue: .main
      ) { [weak self] notification in
        self?.emit(eventType: eventType, notification: notification)
      }
      eventObservers.append(observer)
    }
  }

  private func emit(eventType: EventType, notification: Foundation.Notification) {
    var id = UUID().uuidString
    var title: String?
    var message: String?
    var clientMetadata: String?
    var type: String?
    var targetUrl: String?

    if let payload = notification.userInfo?["payload"] as? String,
      let data = payload.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    {
      id = json["notificationId"] as? String ?? id
      title = json["title"] as? String
      message = json["message"] as? String
      clientMetadata = json["clientMetadata"] as? String
      if let rawType = json["type"] {
        type = String(describing: rawType)
      }
      targetUrl = json["targetUrl"] as? String
    } else if let userInfo = notification.object as? [AnyHashable: Any] {
      clientMetadata = stringify(userInfo)
      if let aps = userInfo["aps"] as? [AnyHashable: Any] {
        if let alert = aps["alert"] as? [AnyHashable: Any] {
          title = alert["title"] as? String
          message = alert["body"] as? String
        } else if let alert = aps["alert"] as? String {
          message = alert
        }
      }
    }

    let event = PushEvent(
      id: id,
      eventType: eventType,
      title: title,
      description: nil,
      replacements: nil,
      message: message,
      clientMetadata: clientMetadata,
      type: type,
      targetUrl: targetUrl
    )
    flutterApi?.onPushEvent(event: event) { _ in }
  }

  private func stringify(_ value: Any) -> String? {
    guard JSONSerialization.isValidJSONObject(value),
      let data = try? JSONSerialization.data(withJSONObject: value),
      let string = String(data: data, encoding: .utf8)
    else {
      return String(describing: value)
    }
    return string
  }
}
