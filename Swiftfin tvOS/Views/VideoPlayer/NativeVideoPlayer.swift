//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import AVKit
import Combine
import Defaults
import JellyfinAPI
import SwiftUI
import KSPlayer
import UIKit

struct NativeVideoPlayer: View {
 
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
        NativeVideoPlayerView(videoPlayerManager: videoPlayerManager)
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

struct NativeVideoPlayerView: UIViewControllerRepresentable {

    let videoPlayerManager: VideoPlayerManager

    func makeUIViewController(context: Context) -> UINativeVideoPlayerViewController {
        UINativeVideoPlayerViewController(manager: videoPlayerManager)
    }

    func updateUIViewController(_ uiViewController: UINativeVideoPlayerViewController, context: Context) {}
}

class UINativeVideoPlayerViewController: UIViewController {

    let videoPlayerManager: VideoPlayerManager

    private var rateObserver: NSKeyValueObservation!
    private var timeObserverToken: Any!
    
    private var playerView: VideoPlayerView!

    init(manager: VideoPlayerManager) {
        
        self.videoPlayerManager = manager

        super.init(nibName: nil, bundle: nil)
        
        view.backgroundColor = .black
        
        KSOptions.secondPlayerType = KSMEPlayer.self
        playerView = VideoPlayerView()
        view.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.readableContentGuide.topAnchor),
            playerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            playerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        let options = KSOptions()
        options.isAutoPlay = true
        
        playerView.set(url: manager.currentViewModel.playbackURL, options: options)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stop()
//        guard let timeObserverToken else { return }
//        player?.removeTimeObserver(timeObserverToken)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        playerView.seek(time: TimeInterval(Int64(videoPlayerManager.currentViewModel.item.startTimeSeconds - Defaults[.VideoPlayer.resumeOffset]))) { _ in
        }

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

    private func createMetadata() -> [AVMetadataItem] {
        let allMetadata: [AVMetadataIdentifier: Any?] = [
            .commonIdentifierTitle: videoPlayerManager.currentViewModel.item.displayTitle,
            .iTunesMetadataTrackSubTitle: videoPlayerManager.currentViewModel.item.subtitle,
        ]

        return allMetadata.compactMap { createMetadataItem(for: $0, value: $1) }
    }

    private func createMetadataItem(
        for identifier: AVMetadataIdentifier,
        value: Any?
    ) -> AVMetadataItem? {
        guard let value else { return nil }
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        // Specify "und" to indicate an undefined language.
        item.extendedLanguageTag = "und"
        return item.copy() as? AVMetadataItem
    }

    private func play() {
//        player?.play()

        videoPlayerManager.sendStartReport()
    }

    private func stop() {
//        player?.pause()

        videoPlayerManager.sendStopReport()
    }
}
