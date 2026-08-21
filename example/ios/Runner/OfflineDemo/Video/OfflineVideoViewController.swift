//
//  VideoViewController.swift
//  PushSDKApp
//
//  Created by Dimitrios Tsoumanis on 21/02/2023.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class OfflineVideoViewController: UIViewController {

    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var customButton: UIButton!
    @IBOutlet private weak var pollButtonsStackView: UIStackView!
    @IBOutlet private weak var videoView: UIView!
    
    var viewModel: OfflineVideoViewModel
    
    private var player: AVPlayer?
    private var playerController = AVPlayerViewController()
    private var playerItem: AVPlayerItem?
    
    init?(coder: NSCoder, viewModel: OfflineVideoViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        setUpUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !viewModel.isFinishedPlaying else {
            return
        }
        player?.play()
    }
    //hardcoded, needs to update
    @IBAction private func agreeButtonTapped() {
        if let linkURL = URL(string: "https://www.austinfc.com/") {
            UIApplication.shared.open(linkURL)
        }
    }
    
    @IBAction private func closeButtonTapped() {
        NotificationCenter.default.removeObserver(self)
        dismiss(animated: true)
    }
    //hardcoded, needs to update
    @IBAction private func disagreeButtonTapped() {
        if let linkURL = URL(string: "https://www.houstondynamofc.com/") {
            UIApplication.shared.open(linkURL)
        }
    }
    
    @IBAction private func customButtonTapped() {
        player?.pause()
        guard let linkURL = viewModel.videoState.linkURL else {
            return
        }
        UIApplication.shared.open(linkURL)
    }
    
    private func configure() {
        guard let resourceURL = viewModel.videoState.resourceURL else { return }
        playerItem = AVPlayerItem(url: resourceURL)
        player = AVPlayer(playerItem: playerItem)
        player?.actionAtItemEnd = .pause
        playerController.updatesNowPlayingInfoCenter = false
        playerController.showsPlaybackControls = false
        playerController.player = player
        playerController.videoGravity = .resize
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        let interval = CMTime(
            seconds: 1,
            preferredTimescale: CMTimeScale(NSEC_PER_SEC)
        )
        
        player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak player, weak playerItem, weak self] time in
            guard let timeInDouble = player?.currentTime().seconds, let duration = playerItem?.duration.seconds
                     else {
                return
            }
            guard let viewModel = self?.viewModel else {
                return
            }
            if timeInDouble > duration - 3 {
                self?.pollButtonsStackView.isHidden = !viewModel.isVideoWithPoll
                self?.customButton.isHidden = viewModel.isVideoWithPoll
            }
            else {
                self?.pollButtonsStackView.isHidden = true
                self?.customButton.isHidden = true
            }
        }
    }

    @objc private func playerDidFinishPlaying(note: NSNotification) {
        viewModel.isFinishedPlaying = true
        if let duration = playerItem?.duration, playerItem?.currentTime() == duration {
            player?.seek(to: duration, toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }
    
    private func setUpUI() {
        pollButtonsStackView.isHidden = !viewModel.isVideoWithPoll
        customButton.isHidden = viewModel.isVideoWithPoll
        
        videoView?.addSubview(playerController.view)
        playerController.view.frame = videoView.layer.frame
    }
    
    @objc private func willEnterForeground() {
        if !viewModel.isFinishedPlaying {
            player?.play()
        }
    }
    
    @objc private func willResignActive() {
        if !viewModel.isFinishedPlaying {
            player?.pause()
        }
    }
    
}
