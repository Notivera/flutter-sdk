//
//  OfflineVideoViewModel.swift
//  PushSDKApp
//
//  Created by Dimitrios Tsoumanis on 13/03/2023.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation

protocol OfflineVideoViewModel {
    
    var isFinishedPlaying: Bool { get set }
    var isVideoWithPoll: Bool { get }
    var notificationIdentifier: NotificationIdentifier { get }
    var videoState: VideoState { get }
    
}

final class DefaultVideoViewModel: OfflineVideoViewModel {
    
    var isFinishedPlaying: Bool = false
    let isVideoWithPoll: Bool
    let notificationIdentifier: NotificationIdentifier
    let videoState: VideoState

    init(isVideoWithPoll: Bool, notificationIdentifier: NotificationIdentifier) {
        self.isVideoWithPoll = isVideoWithPoll
        self.notificationIdentifier = notificationIdentifier
        switch notificationIdentifier {
        case .videoWithButtonOne(let response):
            videoState = VideoState(
                linkURL: URL(string: (response?.notification.contents.first?.options?.buttons?.first?.url ?? "")),
                resourceURL: URL(
                    fileURLWithPath: Bundle.main.path(
                        forResource: response?.notification.contents.first?.downloadUrl,
                        ofType:"mp4"
                    ) ?? ""
                )
            )
        case.videoWithButtonTwo(let response):
            videoState = VideoState(
                linkURL: URL(string: (response?.notification.contents.first?.options?.buttons?.first?.url ?? "")),
                resourceURL: URL(
                    fileURLWithPath: Bundle.main.path(
                        forResource: response?.notification.contents.first?.downloadUrl,
                        ofType:"mp4"
                    ) ?? ""
                )
            )
        case .poll(let response):
            videoState = VideoState(
                linkURL: nil,
                resourceURL: URL(
                    fileURLWithPath: Bundle.main.path(
                        forResource: response?.notification.contents.first?.downloadUrl,
                        ofType:"mp4"
                    ) ?? ""
                )
            )
        default:
            videoState = VideoState(
                linkURL: nil,
                resourceURL: nil
            )
            break
       }
    }
    
}
