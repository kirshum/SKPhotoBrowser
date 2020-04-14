//
//  SKVideoPlayerView.swift
//  SKPhotoBrowser
//
//  Created by Елизаров Владимир Алексеевич on 05/06/2019.
//

import Foundation
import AVKit
import AVFoundation

class SKVideoPlayerView: UIView, PresentableViewType {
    
    var imageFrame: CGRect {
        return self.frame
    }
    
    var captionView: SKCaptionView!
    
    var previewImageView: UIImageView = UIImageView()
    
    var photo: SKPhotoProtocol! {
        didSet {
            if photo != nil && photo.underlyingImage != nil {
                displayImage(complete: true)
                return
            }
            if photo != nil {
                displayImage(complete: false)
            }
            guard let video = self.photo
                , let videoURL = video.videoStreamURL else {
                return
            }
            let player: AVPlayer
            if videoURL.isFileURL {
                player = AVPlayer(url: videoURL)
            } else {
                let header = SKPhotoBrowserOptions.sessionConfiguration.httpAdditionalHeaders
                let asset: AVURLAsset = AVURLAsset.init(url: videoURL, options: ["AVURLAssetHTTPHeaderFieldsKey": header as Any])
                let playerItem = AVPlayerItem(asset: asset)
                player = AVPlayer(playerItem: playerItem)
            }

            self.playerController.player = player
            
            self.setObservation(in: self.playerController.player!)
            self.playerController.view.frame = self.bounds
            self.playerController.player?.allowsExternalPlayback = true
        }
    }

    var contentOffset: CGPoint {
        return .zero
    }
    
    var presentableType: MediaType {
        return .video
    }
    
    private weak var browser: SKPhotoBrowser?
    
    private var indicatorView: SKIndicatorView!
    
    private var playerController = AVPlayerViewController()
    
    private var playButton: UIButton!
    
    
    // MARK: -
    
    convenience init(frame: CGRect, browser: SKPhotoBrowser) {
        self.init(frame: frame)
        self.browser = browser
        setup()
    }
    
    deinit {
        self.playerController.player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.rate))
        self.unsubscribeFromPlayToEndNotification()
    }
    
    func setMaxMinZoomScalesForCurrentBounds() {
        
    }
    
    func prepareForReuse() {
        self.playerController.removeFromParent()
        self.playerController.player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.rate))
        self.playerController.player?.pause()
        self.playerController.player = nil
        if self.playButton.isHidden {
            self.playButton.isHidden = false
        }
    }
    
    func displayImage(_ image: UIImage) {
        
    }
    
    func displayImageFailure() {
        
    }

    func displayImage(complete flag: Bool) {
        
        if !flag {
            if photo.underlyingImage == nil {
                indicatorView.startAnimating()
            }
            photo.loadUnderlyingImageAndNotify()
        } else {
            indicatorView.stopAnimating()
        }
        indicatorView.stopAnimating()
        if let image = photo.underlyingImage, photo != nil {
            displayImage(image)
        }
    }
    
    open override func layoutSubviews() {
        self.indicatorView.frame = bounds
        super.layoutSubviews()
    }
    
    
    // MARK: - Private

    private func setObservation(in player: AVPlayer) {
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.rate), options: [.new], context: nil)
        self.unsubscribeFromPlayToEndNotification()
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        player.currentItem?.addObserver(self,
                                        forKeyPath: #keyPath(AVPlayerItem.status),
                                        options: [.old, .new],
                                        context: nil)
        
        self.playerController.addObserver(self, forKeyPath: #keyPath(AVPlayerViewController.isReadyForDisplay),
                                          options: [.old, .new],
                                          context: nil)
    }
    
    private func unsubscribeFromPlayToEndNotification() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc private func playerItemDidPlayToEndTime() {
        self.playerController.player?.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
        self.playButton.isHidden = false
        self.browser?.showControls()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayer.rate) {
            if self.playerController.player?.rate == 0 {
                self.playButton.isHidden = false
            } else {
                self.browser?.hideControls()
                self.playButton.isHidden = true
            }
        } else if keyPath == #keyPath(AVPlayerViewController.isReadyForDisplay) {
            if self.playerController.isReadyForDisplay {
                self.updatePreview()
            }
        }
    }
    
    fileprivate func setupImageView() {
        self.addSubview(previewImageView)
        self.previewImageView.contentMode = .scaleAspectFit
        self.previewImageView.translatesAutoresizingMaskIntoConstraints = false
        self.previewImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.previewImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        self.previewImageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.previewImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        let singleTap = UITapGestureRecognizer(target: self,
                                               action: #selector(self.handleSingleTap))
        let bundle = Bundle(for: SKPhotoBrowser.self)
        let image = UIImage(named: "SKPhotoBrowser.bundle/images/ic_PlayVideo",
                            in: bundle, compatibleWith: nil)

        self.playButton = UIButton(frame:
            CGRect(x: 0,
                   y: 0,
                   width: Consants.playButtonWidth,
                   height: Consants.playButonHeight))
        
        self.playButton.setImage(image, for: .normal)
        self.playButton.addTarget(self,
                                  action: #selector(self.hideAndPlay),
                                  for: .touchUpInside)
        self.addSubview(self.playButton)
        self.playButton.translatesAutoresizingMaskIntoConstraints = false
        self.playButton.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.playButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.playButton.widthAnchor.constraint(equalToConstant: Consants.playButtonWidth).isActive = true
        self.playButton.heightAnchor.constraint(equalToConstant: Consants.playButonHeight).isActive = true
        self.bringSubviewToFront(self.playButton)
        self.addGestureRecognizer(singleTap)
    }
    
    @objc private func handleSingleTap() {
        self.playButton.isHidden = false
        self.browser?.showControls()
    }
    
    private func setup() {
        self.playerController.videoGravity = .resizeAspect
        if #available(iOS 11.0, *) {
            self.playerController.exitsFullScreenWhenPlaybackEnds = true
        }
        self.setupImageView()
        self.indicatorView = SKIndicatorView(frame: frame)
        addSubview(self.indicatorView)
    }
    
    private func playVideo() {
        guard let playURL = self.photo.videoStreamURL else {
            return
        }
        
        if let oldPlayer = self.playerController.player {
            oldPlayer.play()
            return
        }
        
        let player = AVPlayer(url: playURL)
        self.playerController.player = player
        UIView.performWithoutAnimation {
            self.playerController.player?.play()
        }
    }
    
    @objc private func hideAndPlay() {
        self.playButton.isHidden = true
        self.browser?.hideControls()
        self.browser?.present(self.playerController, animated: true, completion:{ [weak self]  in
            self?.playVideo()
        })
    }
    
    private func createPreview() -> UIImage? {
        guard let player = self.playerController.player
            , let asset = player.currentItem?.asset
            else { return nil }
        
        let currentTime: CMTime = player.currentTime()
        let currentTimeInSecs: Float64 = CMTimeGetSeconds(currentTime)
        let actionTime: CMTime = CMTimeMake(value: Int64(currentTimeInSecs), timescale: 1)
        
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        guard let imageRef =  try? imageGenerator.copyCGImage(at: actionTime, actualTime: nil)
            else { return nil }
        return  UIImage(cgImage: imageRef)
        
    }
    
    private func updatePreview() {
        guard let preivew = self.createPreview() else { return }
        self.previewImageView.image = preivew
    }
}


// MARK: - Constants

private extension SKVideoPlayerView {
    struct Consants {
        static let playButtonWidth: CGFloat = 44
        static let playButonHeight: CGFloat = 44
    }
}
