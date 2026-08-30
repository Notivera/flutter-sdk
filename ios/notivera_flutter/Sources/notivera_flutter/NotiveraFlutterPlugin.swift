import Flutter
import NotiveraSDK
import UIKit
import UserNotifications

public class NotiveraFlutterPlugin: NSObject, FlutterPlugin, NotiveraHostApi {
  private struct BufferedRemoteNotification {
    let application: UIApplication
    let userInfo: [AnyHashable: Any]
    let completionHandler: (UIBackgroundFetchResult) -> Void
  }

  private struct BufferedBackgroundURLSession {
    let application: UIApplication
    let identifier: String
    let completionHandler: () -> Void
  }

  private struct BufferedNotificationTap {
    let userInfo: [AnyHashable: Any]
    let categoryIdentifier: String
  }

  /// Process-lifetime SDK. Flutter tears down plugin instances on engine detach /
  /// hot restart; releasing `Notivera`/`DefaultSDK` in that path crashes inside
  /// native SDK deinit. Match Android: keep the native SDK for the process.
  private static var retainedSdk: Notivera?

  /// Cold-start tap from a killed app — may arrive before the plugin instance exists.
  private static var pendingLaunchTap: BufferedNotificationTap?

  private var sdk: Notivera?
  private var flutterApi: NotiveraFlutterApi?
  private var eventObservers: [Any] = []
  private var bufferedDeviceToken: Data?
  private var bufferedRegistrationError: Error?
  private var bufferedRemoteNotifications: [BufferedRemoteNotification] = []
  private var bufferedBackgroundURLSessions: [BufferedBackgroundURLSession] = []

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NotiveraFlutterPlugin()
    instance.sdk = retainedSdk
    instance.flutterApi = NotiveraFlutterApi(binaryMessenger: registrar.messenger())
    NotiveraHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    registrar.publish(instance)
    registrar.addApplicationDelegate(instance)
  }

  /// Call from the host `AppDelegate` when a notification is opened so cold-start
  /// taps are not lost before Dart `initialize()` (UIScene / FlutterImplicitEngine).
  @objc public static func captureNotificationResponse(_ response: UNNotificationResponse) {
    let userInfo = response.notification.request.content.userInfo
    let category = response.notification.request.content.categoryIdentifier
    guard isNotiveraTap(userInfo: userInfo, categoryIdentifier: category) else {
      return
    }
    pendingLaunchTap = BufferedNotificationTap(
      userInfo: userInfo,
      categoryIdentifier: category
    )
    NSLog(
      "[NotiveraFlutterPlugin] Captured launch notification tap category=%@",
      category
    )
  }

  /// Replay a buffered cold-start Notivera tap after the UI can present.
  /// Safe to call more than once; no-ops when nothing is pending.
  @objc public static func flushPendingNotificationResponse(delaySeconds: Double = 0.5) {
    guard let tap = pendingLaunchTap else {
      return
    }
    guard let sdk = retainedSdk else {
      NSLog(
        "[NotiveraFlutterPlugin] Pending tap kept — SDK not initialized yet"
      )
      return
    }
    pendingLaunchTap = nil
    DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) {
      NSLog(
        "[NotiveraFlutterPlugin] Flushing launch notification tap category=%@",
        tap.categoryIdentifier
      )
      deliverNotificationTap(tap, using: sdk)
    }
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    tearDownFlutterBindings(binaryMessenger: registrar.messenger())
  }

  deinit {
    // Engine detach should already have run; keep this as a safety net.
    stopObservingEvents()
    flutterApi = nil
  }

  public func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    if let sdk {
      NSLog(
        "[NotiveraFlutterPlugin] APNs device token received; handling immediately (%d bytes)",
        deviceToken.count
      )
      sdk.application(
        application,
        didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
      )
    } else {
      bufferedDeviceToken = deviceToken
      // A valid token supersedes any pre-init registration failure.
      bufferedRegistrationError = nil
      NSLog(
        "[NotiveraFlutterPlugin] APNs device token received; buffering until initialize (%d bytes)",
        deviceToken.count
      )
    }
  }

  public func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    if let sdk {
      NSLog(
        "[NotiveraFlutterPlugin] APNs registration failed; handling immediately: %@",
        error.localizedDescription
      )
      sdk.application(
        application,
        didFailToRegisterForRemoteNotificationsWithError: error,
        completion: nil
      )
    } else {
      bufferedRegistrationError = error
      NSLog(
        "[NotiveraFlutterPlugin] APNs registration failed; buffering until initialize: %@",
        error.localizedDescription
      )
    }
  }

  public func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) -> Bool {
    if let sdk {
      guard sdk.isNotiveraNotification(userInfo: userInfo) else {
        return false
      }
      NSLog("[NotiveraFlutterPlugin] Remote notification received; handling immediately")
      sdk.application(
        application,
        didReceiveRemoteNotification: userInfo,
        fetchCompletionHandler: completionHandler
      )
      return true
    }

    guard isPotentialNotiveraNotification(userInfo: userInfo) else {
      return false
    }
    bufferedRemoteNotifications.append(
      BufferedRemoteNotification(
        application: application,
        userInfo: userInfo,
        completionHandler: completionHandler
      )
    )
    NSLog(
      "[NotiveraFlutterPlugin] Remote notification received; buffering until initialize (queued=%d)",
      bufferedRemoteNotifications.count
    )
    return true
  }

  public func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) -> Bool {
    guard let sdk else {
      bufferedBackgroundURLSessions.append(
        BufferedBackgroundURLSession(
          application: application,
          identifier: identifier,
          completionHandler: completionHandler
        )
      )
      NSLog(
        "[NotiveraFlutterPlugin] Background URL session callback received; buffering until initialize (queued=%d)",
        bufferedBackgroundURLSessions.count
      )
      return true
    }
    NSLog("[NotiveraFlutterPlugin] Background URL session callback received; handling immediately")
    sdk.application(
      application,
      handleEventsForBackgroundURLSession: identifier,
      completionHandler: completionHandler
    )
    return true
  }

  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    let category = response.notification.request.content.categoryIdentifier
    if let sdk, Self.isNotiveraTap(userInfo: userInfo, categoryIdentifier: category) {
      Self.pendingLaunchTap = nil
      NSLog("[NotiveraFlutterPlugin] Notification tap; handling immediately")
      Self.deliverNotificationTap(
        BufferedNotificationTap(userInfo: userInfo, categoryIdentifier: category),
        using: sdk
      )
    } else {
      Self.captureNotificationResponse(response)
    }
    completionHandler()
  }

  func initialize(config: NotiveraConfig) throws {
    // config.pushTheme is Android-only (resource names → NotiveraPushTheme).
    // The iOS SDK has no theme parameter on init; icons come from the app bundle.
    let instance: Notivera
    if let existing = Self.retainedSdk {
      instance = existing
      NSLog("[NotiveraFlutterPlugin] Reusing process-lifetime Notivera SDK")
    } else {
      instance = Notivera(
        apiKey: config.apiKey,
        apiSecret: config.apiSecret,
        inAppOpenDelay: Int(config.inAppOpenDelayMs ?? 0),
        tenantID: config.tenantId
      )
      Self.retainedSdk = instance
    }
    instance.customerID = config.customerId
    sdk = instance
    flushBufferedLifecycleEvents(using: instance)
    // Re-assert after Flutter/Firebase plugins may have claimed the center.
    instance.setNotiveraUserNotificationDelegate(
      delegate: NotiveraUserNotificationDelegate(sdk: instance)
    )
    startObservingEvents()
    // Cold-start Notivera taps (video / carousel / poll) buffered via
    // captureNotificationResponse / AppDelegate.
    Self.flushPendingNotificationResponse(delaySeconds: 0.75)
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

  private func flushBufferedLifecycleEvents(using sdk: Notivera) {
    let token = bufferedDeviceToken
    let registrationError = bufferedRegistrationError
    let remoteNotifications = bufferedRemoteNotifications
    let backgroundSessions = bufferedBackgroundURLSessions

    // Clear first to make flush idempotent if initialize is re-entered.
    bufferedDeviceToken = nil
    bufferedRegistrationError = nil
    bufferedRemoteNotifications.removeAll()
    bufferedBackgroundURLSessions.removeAll()

    var flushedTokenCount = 0
    var flushedErrorCount = 0
    var flushedRemoteCount = 0
    var flushedBackgroundSessionCount = 0

    if let token {
      sdk.application(
        UIApplication.shared,
        didRegisterForRemoteNotificationsWithDeviceToken: token
      )
      flushedTokenCount = 1
      NSLog(
        "[NotiveraFlutterPlugin] Flushed buffered APNs device token (%d bytes)",
        token.count
      )
    } else if let registrationError {
      sdk.application(
        UIApplication.shared,
        didFailToRegisterForRemoteNotificationsWithError: registrationError,
        completion: nil
      )
      flushedErrorCount = 1
      NSLog("[NotiveraFlutterPlugin] Flushed buffered APNs registration failure")
    }

    for notification in remoteNotifications {
      guard sdk.isNotiveraNotification(userInfo: notification.userInfo) else {
        NSLog("[NotiveraFlutterPlugin] Skipped non-Notivera buffered notification")
        notification.completionHandler(.noData)
        continue
      }
      sdk.application(
        notification.application,
        didReceiveRemoteNotification: notification.userInfo,
        fetchCompletionHandler: notification.completionHandler
      )
      flushedRemoteCount += 1
    }

    for session in backgroundSessions {
      sdk.application(
        session.application,
        handleEventsForBackgroundURLSession: session.identifier,
        completionHandler: session.completionHandler
      )
      flushedBackgroundSessionCount += 1
    }

    NSLog(
      "[NotiveraFlutterPlugin] Pre-init flush complete token=%d error=%d remote=%d background=%d",
      flushedTokenCount,
      flushedErrorCount,
      flushedRemoteCount,
      flushedBackgroundSessionCount
    )
  }

  private func isPotentialNotiveraNotification(userInfo: [AnyHashable: Any]) -> Bool {
    guard
      let aps = userInfo["aps"] as? [AnyHashable: Any],
      let category = aps["category"] as? String
    else {
      return false
    }
    return category == "NSDKNotification" || category == "PushologiesCarouselNotification"
  }

  private static func isNotiveraTap(
    userInfo: [AnyHashable: Any],
    categoryIdentifier: String
  ) -> Bool {
    if categoryIdentifier == "NSDKNotification"
      || categoryIdentifier == "PushologiesCarouselNotification"
    {
      return true
    }
    if let aps = userInfo["aps"] as? [AnyHashable: Any],
      let category = aps["category"] as? String
    {
      return category == "NSDKNotification" || category == "PushologiesCarouselNotification"
    }
    return false
  }

  private static func deliverNotificationTap(
    _ tap: BufferedNotificationTap,
    using sdk: Notivera
  ) {
    var info = tap.userInfo
    // Historical key spelling inside NotiveraSDK.
    info["handleTargertURL"] = true
    sdk.application(
      UIApplication.shared,
      didReceiveRemoteNotification: info,
      fetchCompletionHandler: { _ in }
    )
  }

  private func tearDownFlutterBindings(binaryMessenger: FlutterBinaryMessenger) {
    stopObservingEvents()
    // Drop the notification-center delegate owned by this plugin/bindings so it
    // cannot outlive the Flutter messenger. Keep `retainedSdk` alive.
    sdk?.setNotiveraUserNotificationDelegate(delegate: nil)
    if UNUserNotificationCenter.current().delegate is NotiveraUserNotificationDelegate {
      UNUserNotificationCenter.current().delegate = nil
    }
    NotiveraHostApiSetup.setUp(binaryMessenger: binaryMessenger, api: nil)
    flutterApi = nil
    sdk = nil
    NSLog("[NotiveraFlutterPlugin] Flutter bindings torn down; native SDK retained")
  }

  private func stopObservingEvents() {
    eventObservers.forEach { NotificationCenter.default.removeObserver($0) }
    eventObservers.removeAll()
  }

  private func startObservingEvents() {
    stopObservingEvents()

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
