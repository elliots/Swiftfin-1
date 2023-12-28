//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import KSPlayer
import UIKit

class KSCustomVideoPlayerView: VideoPlayerView {
    
    var actionClose: (() -> Void)?
    private lazy var closeButton: UIButton = {
        $0.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        $0.isHidden = true
        return $0
    }(UIButton())
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        controllerView.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .primaryActionTriggered)
    }
     
    private func setupConstraints() {
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
                closeButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
                closeButton.widthAnchor.constraint(equalToConstant: 50),
                closeButton.heightAnchor.constraint(equalToConstant: 50)
                
            ])
    }
    
    
    // State
    override func player(layer: KSPlayerLayer, state: KSPlayerState) {
        super.player(layer: layer, state: state)
        switch state {
        case .error, .paused:
            closeButton.isHidden = false
        default:
            closeButton.isHidden = true
        }
        
    }
    
    // time info
    override func player(layer: KSPlayerLayer, currentTime: TimeInterval, totalTime: TimeInterval) {
        super.player(layer: layer, currentTime: currentTime, totalTime: totalTime)
        
    }
    
    @objc private func closeButtonTapped() {
        actionClose?()
    }
    
}
