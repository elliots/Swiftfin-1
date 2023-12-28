//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI
import KSPlayer
import Foundation

struct KSVideoPlayer: View {

    @Environment(\.scenePhase)
    var scenePhase

    @EnvironmentObject
    private var router: VideoPlayerCoordinator.Router

    @ObservedObject
    private var videoPlayerManager: VideoPlayerManager

    init(manager: VideoPlayerManager) {
        self.videoPlayerManager = manager
    }

    @ViewBuilder
    private var playerView: some View {
        KSVideoPlayerView(videoPlayerManager: videoPlayerManager)
    }

    var body: some View {
        Group {
            if let _ = videoPlayerManager.currentViewModel {
                playerView
            } else {
//                VideoPlayer.LoadingView()
                Text("Loading")
            }
        }
        .environmentObject(videoPlayerManager)
        .navigationBarHidden(true)
        .ignoresSafeArea()
    }
}

struct KSVideoPlayerView: UIViewControllerRepresentable {

    let videoPlayerManager: VideoPlayerManager

    func makeUIViewController(context: Context) -> UIKSVideoPlayerViewController {
        UIKSVideoPlayerViewController(manager: videoPlayerManager)
    }

    func updateUIViewController(_ uiViewController: UIKSVideoPlayerViewController, context: Context) {}
}

class UIKSVideoPlayerViewController: UIViewController {
    
    private lazy var playerView: KSCustomVideoPlayerView = {
        $0.actionClose = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
        return $0
    }(KSCustomVideoPlayerView())
    
    let videoPlayerManager: VideoPlayerManager

    private var isPlaying = false

    init(manager: VideoPlayerManager) {
        self.videoPlayerManager = manager
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPlayer()
    }
    
    private func setupPlayer() {
        
        KSOptions.secondPlayerType = KSMEPlayer.self
        view.addSubview(playerView)
        playerView.frame = view.bounds
        
        // for ios and ipad
        playerView.backBlock = { [unowned self] in
//            if UIApplication.shared.statusBarOrientation.isLandscape {
//                self.playerView.updateUI(isLandscape: false)
//            } else {
//                self.navigationController?.popViewController(animated: true)
            
        }
        
        let options = KSOptions()
        options.isAutoPlay = true
        
        // setup URL
        playerView.set(url: self.videoPlayerManager.currentViewModel.playbackURL, options: options)
        // saved time progress
        playerView.playTimeDidChange = {[weak self] (currentTime: TimeInterval, totalTime: TimeInterval) in
            print(currentTime)
            
            if currentTime >= 0 {
                let newSeconds = Int(currentTime)
                print(newSeconds)
                let progress = CGFloat(newSeconds) / CGFloat(self?.videoPlayerManager.currentViewModel.item.runTimeSeconds ?? 1)
                self?.videoPlayerManager.currentProgressHandler.progress = progress
                self?.videoPlayerManager.currentProgressHandler.scrubbedProgress = progress
                self?.videoPlayerManager.currentProgressHandler.seconds = newSeconds
                self?.videoPlayerManager.currentProgressHandler.scrubbedSeconds = newSeconds
            }
            self?.isPlaying = true
         }
        playerView.play()
        // set time progress if needed
        if self.videoPlayerManager.currentViewModel.item.startTimeSeconds > 0 {
            playerView.seek(time: TimeInterval(self.videoPlayerManager.currentViewModel.item.startTimeSeconds), completion: { _ in })
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stop()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func play() {
        playerView.play()
        self.videoPlayerManager.onStateUpdated(newState: .playing)
        videoPlayerManager.sendStartReport()
    }

    private func stop() {
        self.videoPlayerManager.onStateUpdated(newState: .paused)
        playerView.pause()
        isPlaying = false
        videoPlayerManager.sendStopReport()
    }
    
    private func tapPlayPause() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }
    
    private func tapMenu() {
        if isPlaying {
            tapPlayPause()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    /// Need if player stop focused, work on simulator
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        for press in presses {
            switch press.type {
            case .playPause:
                tapPlayPause()
            case .menu:
                tapMenu()
            default:
                break
            }
        }
    }
}
