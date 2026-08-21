//
//  CarouselNotificationContentViewModel.swift
//  PushSDKApp
//
//  Created by Phil on 20/03/2023.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation
import UserNotificationsUI

protocol OfflineCarouselNotificationContentViewModel: AnyObject {
    
    var currentIndex: Int { get set }
    var isFirstTimeViewed: Bool { get set }
    var notificationID: UUID? { get }
    
    func didReceive(_ notification: UNNotification)
    func didReceive(
        _ response: UNNotificationResponse,
        completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void
    )
    
}
