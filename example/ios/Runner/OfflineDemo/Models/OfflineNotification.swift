//
//  OfflineNotification.swift
//  PushSDKApp
//
//  Created by Dimitrios Tsoumanis on 26/05/2023.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation

struct OfflineNotification: Decodable {
    
    let id: String
    let title: String
    let subTitle: String?
    let message: String
    let type: OfflineNotificationType
    let contents: [OfflineContent]
    
}
