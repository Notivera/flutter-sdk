//
//  OfflineOptions.swift
//  PushSDKApp
//
//  Created by Dimitrios Tsoumanis on 26/05/2023.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation

struct OfflineOptions: Decodable {
    
    let orientation: String?
    let zoomMode: String?
    let useEmbeddedPlayer: Bool?
    let allowPreview: Bool?
    let fullScreen: Bool?
    let buttons: [OfflineButtons]?
    let allowSharing: Bool?
    let allowScrubbing: Bool?
    
}
