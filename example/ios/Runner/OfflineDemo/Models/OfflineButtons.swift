//
//  OfflineButtons.swift
//  PushSDKApp
//
//  Created by Dimitrios Tsoumanis on 26/05/2023.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation

struct OfflineButtons: Codable {
    
    let displayName: String?
    let url: String?
    let linkHandling: String?
    let text: String?
    let textColor: String?
    let font: String?
    let fontSize: String?
    let backgroundColor: String?
    let position: OfflinePosition?
    let buttonAppear: Double?
    let buttonDisappear: Double?
    let fullScreen: Bool?
    
}
