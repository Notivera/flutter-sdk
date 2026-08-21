//
//  NotificationIdentifier.swift
//  PushSDKApp
//
//  Created by Phil on 16/03/2023.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation

enum NotificationIdentifier {
    
    case videoWithButtonOne(OfflineVideoNotificationsResponse? = nil)
    case videoWithButtonTwo(OfflineVideoNotificationsResponse? = nil)
    case poll(OfflineVideoNotificationsResponse? = nil)
    case carousel(OfflineVideoNotificationsResponse? = nil)
    
}

extension NotificationIdentifier: RawRepresentable {

    public typealias RawValue = String
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "VideoWithButtonOne": self = .videoWithButtonOne(Bundle.main.decode(from: "OfflineVideoWithButtonOne.json"))
        case "VideoWithButtonTwo": self = .videoWithButtonTwo(Bundle.main.decode(from: "OfflineVideoWithButtonTwo.json"))
        case "Poll": self = .poll(Bundle.main.decode(from:"OfflineVideoWithNoButtons.json"))
        case "CategoryExtension": self = .carousel(Bundle.main.decode(from:"OfflineCarouselTiles.json"))
        default:
            return nil
        }
    }

    public var rawValue: RawValue {
        switch self {
        case .videoWithButtonOne: return "VideoWithButtonOne"
        case .videoWithButtonTwo: return "VideoWithButtonTwo"
        case .poll: return "Poll"
        case .carousel: return "CategoryExtension"
        }
    }

}
