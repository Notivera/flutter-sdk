import Foundation
import UserNotifications
import UIKit

enum OfflineDemoSchedulerError: LocalizedError {
  case unknownCategory(String)
  case missingResource(String)

  var errorDescription: String? {
    switch self {
    case .unknownCategory(let id):
      return "Unknown offline category: \(id)"
    case .missingResource(let name):
      return "Missing offline resource: \(name)"
    }
  }
}

/// Mirrors ios-sdk OfflineNotificationViewModel: post a local UNNotification.
enum OfflineDemoScheduler {
  static func schedule(categoryIdentifier: String) throws {
    let content = UNMutableNotificationContent()
    content.sound = .default

    switch categoryIdentifier {
    case "VideoWithButtonOne":
      try fillVideo(
        content: content,
        jsonName: "OfflineVideoWithButtonOne",
        category: categoryIdentifier
      )
    case "VideoWithButtonTwo":
      try fillVideo(
        content: content,
        jsonName: "OfflineVideoWithButtonTwo",
        category: categoryIdentifier
      )
    case "Poll":
      try fillVideo(
        content: content,
        jsonName: "OfflineVideoWithNoButtons",
        category: categoryIdentifier
      )
    case "CategoryExtension":
      try fillCarousel(content: content)
    default:
      throw OfflineDemoSchedulerError.unknownCategory(categoryIdentifier)
    }

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )
    UNUserNotificationCenter.current().add(request)
    NSLog("[OfflineDemo] Scheduled local notification category=%@", categoryIdentifier)
  }

  private static func fillVideo(
    content: UNMutableNotificationContent,
    jsonName: String,
    category: String
  ) throws {
    let payload = try loadJSON(named: jsonName)
    content.title = payload.title
    content.subtitle = payload.subtitle ?? ""
    content.body = payload.message
    content.categoryIdentifier = category

    guard let basename = payload.mediaBasenames.first else {
      throw OfflineDemoSchedulerError.missingResource("video basename")
    }
    guard let url = Bundle.main.url(forResource: basename, withExtension: "mp4") else {
      throw OfflineDemoSchedulerError.missingResource("\(basename).mp4")
    }
    content.attachments = [try attachmentCopying(url: url, identifier: basename)]
  }

  private static func fillCarousel(content: UNMutableNotificationContent) throws {
    let payload = try loadJSON(named: "OfflineCarouselTiles")
    content.title = payload.title
    content.subtitle = payload.subtitle ?? ""
    content.body = payload.message
    content.categoryIdentifier = "CategoryExtension"

    var attachments: [UNNotificationAttachment] = []
    for basename in payload.mediaBasenames {
      guard let url = Bundle.main.url(forResource: basename, withExtension: "png") else {
        continue
      }
      if let attachment = try? attachmentCopying(url: url, identifier: basename) {
        attachments.append(attachment)
      }
    }
    content.attachments = attachments
  }

  /// UNNotificationAttachment requires a movable file copy (not a raw bundle URL).
  private static func attachmentCopying(
    url: URL,
    identifier: String
  ) throws -> UNNotificationAttachment {
    let temp = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension(url.pathExtension)
    try FileManager.default.copyItem(at: url, to: temp)
    return try UNNotificationAttachment(identifier: identifier, url: temp, options: nil)
  }

  private static func loadJSON(named name: String) throws -> OfflineJSONPayload {
    guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
      throw OfflineDemoSchedulerError.missingResource("\(name).json")
    }
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(OfflineJSONPayload.self, from: data)
  }
}

struct OfflineJSONPayload: Decodable {
  struct Notification: Decodable {
    let title: String
    let subTitle: String?
    let message: String
    let contents: [Content]
  }

  struct Content: Decodable {
    let downloadUrl: String
    let options: Options?
  }

  struct Options: Decodable {
    let buttons: [Button]?
  }

  struct Button: Decodable {
    let url: String?
    let displayName: String?
  }

  let notification: Notification

  var title: String { notification.title }
  var subtitle: String? { notification.subTitle }
  var message: String { notification.message }
  var mediaBasenames: [String] { notification.contents.map(\.downloadUrl) }
  var firstButtonURL: URL? {
    guard let raw = notification.contents.first?.options?.buttons?.first?.url else {
      return nil
    }
    return URL(string: raw)
  }
}
