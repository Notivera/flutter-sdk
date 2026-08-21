import NotiveraSDK
import UserNotifications

class NotificationServiceExtension: NotiveraServiceExtension {
  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    if request.isNotiveraRequest {
      super.didReceive(request, withContentHandler: contentHandler)
    }
  }
}
