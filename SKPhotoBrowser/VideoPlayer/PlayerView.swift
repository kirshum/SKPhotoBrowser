//
//  PlayerView.swift
//  SKPhotoBrowser
//
//  Created by Шумаков Кирилл Андреевич on 20.04.2020.
//  Copyright © 2020 suzuki_keishi. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

/// A simple `UIView` subclass backed by an `AVPlayerLayer` layer.
class PlayerView: UIView {
    
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    var playerLayer: AVPlayerLayer {
        return (layer as? AVPlayerLayer) ?? AVPlayerLayer()
    }

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
