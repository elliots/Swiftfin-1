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
        KSNativeVideoPlayerView(videoPlayerManager: videoPlayerManager)
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
        .navigationBarHidden(true)
        .ignoresSafeArea()
    }
}

struct KSNativeVideoPlayerView: UIViewControllerRepresentable {

    let videoPlayerManager: VideoPlayerManager

    func makeUIViewController(context: Context) -> UIKSVideoPlayerViewController {
        UIKSVideoPlayerViewController(manager: videoPlayerManager)
    }

    func updateUIViewController(_ uiViewController: UIKSVideoPlayerViewController, context: Context) {}
}


class UIKSVideoPlayerViewController: UIViewController {
    
    private lazy var playerView: VideoPlayerView = {
        
        return $0
    }(VideoPlayerView())

    let videoPlayerManager: VideoPlayerManager

    private var rateObserver: NSKeyValueObservation!
    private var timeObserverToken: Any!

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
        setupViews()
    }
    
    private func setupViews() {
        view.backgroundColor = .yellow
        KSOptions.secondPlayerType = KSMEPlayer.self
//        playerView = VideoPlayerView()
        view.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.readableContentGuide.topAnchor),
            playerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            playerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        playerView.backBlock = { [unowned self] in
//            if UIApplication.shared.statusBarOrientation.isLandscape {
//                self.playerView.updateUI(isLandscape: false)
//            } else {
//                self.navigationController?.popViewController(animated: true)
            
        }
//        manager.currentViewModel.hlsPlaybackURL)
        playerView.set(url: self.videoPlayerManager.currentViewModel.playbackURL, options: KSOptions())
        playerView.playTimeDidChange = { (currentTime: TimeInterval, totalTime: TimeInterval) in
            print("playTimeDidChange currentTime: \(currentTime) totalTime: \(totalTime)")
        }
        
        playerView.play()
        
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stop()
        guard let timeObserverToken else { return }
//        player?.removeTimeObserver(timeObserverToken)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        player?.seek(
//            to: CMTimeMake(
//                value: Int64(videoPlayerManager.currentViewModel.item.startTimeSeconds - Defaults[.VideoPlayer.resumeOffset]),
//                timescale: 1
//            ),
//            toleranceBefore: .zero,
//            toleranceAfter: .zero,
//            completionHandler: { _ in
//                self.play()
//            }
//        )
    }

//    private func createMetadata() -> [AVMetadataItem] {
//        let allMetadata: [AVMetadataIdentifier: Any?] = [
//            .commonIdentifierTitle: videoPlayerManager.currentViewModel.item.displayTitle,
//            .iTunesMetadataTrackSubTitle: videoPlayerManager.currentViewModel.item.subtitle,
//        ]
//
//        return allMetadata.compactMap { createMetadataItem(for: $0, value: $1) }
//    }
//
//    private func createMetadataItem(
//        for identifier: AVMetadataIdentifier,
//        value: Any?
//    ) -> AVMetadataItem? {
//        guard let value else { return nil }
//        let item = AVMutableMetadataItem()
//        item.identifier = identifier
//        item.value = value as? NSCopying & NSObjectProtocol
//        // Specify "und" to indicate an undefined language.
//        item.extendedLanguageTag = "und"
//        return item.copy() as? AVMetadataItem
//    }

    private func play() {
//        player?.play()

        videoPlayerManager.sendStartReport()
    }

    private func stop() {
//        player?.pause()

        videoPlayerManager.sendStopReport()
    }
    /// dismiss native player
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if press.type == .menu {
                dismiss(animated: true, completion: nil)
            }
        }
    }
}

