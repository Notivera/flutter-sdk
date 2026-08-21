//
//  OfflineContent.swift
//  PushSDKApp
//
//  Created by Dimitrios Tsoumanis on 26/05/2023.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation
import CoreGraphics

struct OfflineContent: Decodable {
    
    let id: String
    let name: String
    let mediaType: OfflineMediaType
    let presentation: String
    let downloadUrl: String
    let width: CGFloat
    let height: CGFloat
    let defaultContent: Bool
    let sortOrder: Int?
    let options: OfflineOptions?
    
}
