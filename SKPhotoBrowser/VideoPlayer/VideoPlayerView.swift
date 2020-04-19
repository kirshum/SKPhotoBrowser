//
//  VideoPlayerView.swift
//  VideoPlayerTest
//
//  Created by Шумаков Кирилл Андреевич on 15.04.2020.
//  Copyright © 2020 kirshum. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation

class SKVideoPlayerView: UIView {
    
    var contentOffset: CGPoint {
        return .zero
    }
    
    var presentableType: MediaType {
        return .video
    }
    
    var imageFrame: CGRect {
        return self.frame
    }
    
    var captionView: SKCaptionView!
    
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
            let asset: AVURLAsset
            if videoURL.isFileURL {
                asset = AVURLAsset(url: videoURL)
            } else {
                let header = SKPhotoBrowserOptions.sessionConfiguration.httpAdditionalHeaders
                asset = AVURLAsset.init(url: videoURL, options: ["AVURLAssetHTTPHeaderFieldsKey": header as Any])
                
            }
            
            self.loadPropertyValues(forAsset: asset)
        }
    }
    
    
    //MARK: - Private properties
    
    private weak var browser: SKPhotoBrowser?
    
    private var playbackControlsView: VideoPlaybackControlsView? {
        return self.browser?.playbackControlsView
    }
    
    private lazy var activityIndicator: UIActivityIndicatorView = self.produceActivityIndicator()
    
    private let player = AVPlayer()
    
    private var wasPlayingBeforeSliderDrag: Bool?
    
    private let videoView = PlayerView()
    
    private var currentSeconds: Double? {
        guard let currentTime = self.player.currentItem?.currentTime() else { return nil }
        return Double(CMTimeGetSeconds(currentTime))
    }
    
    private var areControlsHidden: Bool {
        return (self.playbackControlsView?.alpha ?? 0) == 0.0
    }
    
    
    //MARK: - NSKeyValueObservation values
    
    private var timeObserverToken: Any?
    
    private var playerItemStatusObserver: NSKeyValueObservation?
    
    private var playerTimeControlStatusObserver: NSKeyValueObservation?
    
    
    // MARK: - Init
    
    convenience init(frame: CGRect, browser: SKPhotoBrowser) {
        self.init(frame: frame)
        self.browser = browser
        self.setupUI()
    }
    
    deinit {
        self.browser = nil
        self.captionView = nil
        self.removeObservers()
        self.browser?.hidePlaybackControls()
    }
    
    open override func layoutSubviews() {
        self.activityIndicator.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
        super.layoutSubviews()
        self.videoView.frame = bounds
        self.playbackControlsView?.frame = self.calculateFrameForPlayback()
    }
    
    
    // MARK: - Private
    
    private func setupUI() {
        self.backgroundColor = .black
        self.setupPlaybackControlsView()
        self.addTapGesture()
        self.activityIndicator.startAnimating()
    }
    
    private func addPlayerView() {
        self.videoView.player = self.player
        self.videoView.frame = bounds
        self.addSubview(videoView)
    }
    
    private func setupPlaybackControlsView() {
        self.showControls()
        self.playbackControlsView?.forwardButtonDidTouch = { [weak self] in
            self?.playForward()
        }
        
        self.playbackControlsView?.rewindButtonDidTouch = { [weak self]  in
            self?.playRewind()
        }
        
        self.playbackControlsView?.playPauseButtonDidTouch = { [weak self] in
            self?.togglePlayPause()
            self?.hideControlsWithDelayIfNeeded()
        }
        
        self.playbackControlsView?.timeSliderBeginEditing = { [weak self] in
            guard let self = self
                , self.player.timeControlStatus == .playing
                , self.wasPlayingBeforeSliderDrag == nil
                else { return }
            self.wasPlayingBeforeSliderDrag = true
            self.player.pause()
        }
        
        self.playbackControlsView?.timeSliderChangedValue = { [weak self] value in
            guard let self = self else { return }
            self.sliderValueChaned(value: value)
            self.cancelPreviousScheduledAnimation()
            
        }
        
        self.playbackControlsView?.timeSliderEndEditing = { [weak self] in
            guard self?.wasPlayingBeforeSliderDrag ?? false
                else { return }
            self?.player.play()
            self?.wasPlayingBeforeSliderDrag = nil
        }
    }
    
    private func togglePlayPause() {
        switch player.timeControlStatus {
        case .playing:
            self.player.pause()
        case .paused:
            let currentItem = self.player.currentItem
            if currentItem?.currentTime() == currentItem?.duration {
                currentItem?.seek(to: .zero, completionHandler: nil)
            }
            self.player.play()
            
        default:
            self.player.pause()
        }
    }
    
    private func playRewind() {
        guard let currentSeconds = self.currentSeconds else { return }
        let destinationTime = CMTime(seconds: currentSeconds - Constants.secondsForSeeking,
                                     preferredTimescale: Constants.preferredTimescale)
        self.player.currentItem?.seek(to: destinationTime, completionHandler: nil)
    }
    
    private func playForward() {
        guard let currentSeconds = self.currentSeconds else { return }
        let destinationTime = CMTime(seconds: currentSeconds + Constants.secondsForSeeking,
                                     preferredTimescale: Constants.preferredTimescale)
        self.player.currentItem?.seek(to: destinationTime, completionHandler: nil)
    }
    
    private func sliderValueChaned(value: Float) {
        let newTime = CMTime(seconds: Double(value), preferredTimescale: Constants.preferredTimescale)
        self.player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    private func produceActivityIndicator() -> UIActivityIndicatorView {
        let spinner =  UIActivityIndicatorView(style: .whiteLarge)
        spinner.hidesWhenStopped = true
        spinner.color = #colorLiteral(red: 0.7333333333, green: 0.7529411765, blue: 0.7803921569, alpha: 1)
        spinner.layer.zPosition = .infinity
        self.addSubview(spinner)
        spinner.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
        return spinner
    }
    
    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.singleTap(tap:)))
        self.addGestureRecognizer(tap)
    }
    
    @objc private func singleTap(tap: UITapGestureRecognizer) {
        self.toggleControls()
    }
    
    private func toggleControls() {
        self.cancelPreviousScheduledAnimation()
        self.areControlsHidden
            ? self.showControls()
            : self.hideControls()
    }
    
    private func showControls() {
        self.browser?.showControls()
        self.browser?.showPlaybackControls()
    }
    
    @objc private func hideControls() {
        self.browser?.hideControls()
        self.browser?.hidePlaybackControls()
    }
    
    private func hideControlsWithDelayIfNeeded() {
        /// если плеер на паузе то скрывать не надо
        guard self.player.timeControlStatus != .paused else { return }
        self.perform(#selector(self.hideControls), with: nil, afterDelay: Constants.delayForHidingControls)
    }
    
    private func cancelPreviousScheduledAnimation() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideControls), object: nil)
    }
    
    private func calculateFrameForPlayback() -> CGRect  {
        let frameWidth = self.bounds.width
        let playbacksWidth = frameWidth > Constants.playbackConstrolsOtherDevicesWidth
            ? Constants.playbackConstrolsOtherDevicesWidth
            : Constants.playbackConstrolsForSeWidth
        
        let freeSpace: CGFloat = frameWidth - playbacksWidth
        let minY = self.videoView.frame.maxY
            - Constants.playbackControlsViewBottomConstant
            - (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0)
            - Constants.playbackControlsViewHeightConstant
        
        return CGRect(x: self.videoView.frame.minX + (freeSpace / 2),
                      y: minY,
                      width: playbacksWidth,
                      height: Constants.playbackControlsViewHeightConstant)
    }
    
    @objc func playButtonDidToch() {
        let currentItem = self.player.currentItem
        if currentItem?.currentTime() == currentItem?.duration {
            currentItem?.seek(to: .zero, completionHandler: nil)
        }
        self.player.play()
        self.hideControls()
    }
    
    // MARK: - Asset Property Handling
    
    private func loadPropertyValues(forAsset newAsset: AVURLAsset) {
        self.playbackControlsView?.setupEmptyState()
        let assetKeysRequiredToPlay = [
            "playable",
            "hasProtectedContent"
        ]
        newAsset.loadValuesAsynchronously(forKeys: assetKeysRequiredToPlay) {
            DispatchQueue.main.async {
                if self.validateValues(forKeys: assetKeysRequiredToPlay, forAsset: newAsset) {
                    let playerItem = AVPlayerItem(asset: newAsset)
                    self.player.replaceCurrentItem(with: playerItem)
                    self.setupPlayerObservers()
                    self.addPlayerView()
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    private func validateValues(forKeys keys: [String], forAsset newAsset: AVAsset) -> Bool {
        for key in keys {
            var error: NSError?
            if newAsset.statusOfValue(forKey: key, error: &error) == .failed {
                return false
            }
        }
        if !newAsset.isPlayable || newAsset.hasProtectedContent {
            return false
        }
        return true
    }
    
    
    // MARK: - Key-Value Observing
    
    func setupPlayerObservers() {
        
        self.playerTimeControlStatusObserver = self.player
            .observe(
                \AVPlayer.timeControlStatus,
                options: [.initial, .new]) { [weak self] _, _ in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        self.playbackControlsView?.setPlayPauseButtonImage(for: self.player.timeControlStatus)
                        self.updateSpinner()
                    }
        }
        
        let interval = CMTime(value: 1, timescale: 20)
        timeObserverToken = self.player
            .addPeriodicTimeObserver(
                forInterval: interval,
                queue: .main) { [weak self] time in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        let timeElapsed = Float(time.seconds)
                        self.playbackControlsView?.update(currentime: timeElapsed) }
        }
        
        playerItemStatusObserver = self.player
            .observe(
                \AVPlayer.currentItem?.status,
                options: [.new, .initial]) { [weak self] _, _ in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        self.updateUIforPlayerItemStatus()
                    }
        }
        
    }
    
    private func updateUIforPlayerItemStatus() {
        guard let currentItem = player.currentItem else { return }
        switch currentItem.status {
        case .failed:
            self.playbackControlsView?.disable()
            
        case .readyToPlay:
            self.playbackControlsView?.enable()
            let newDurationSeconds = Float(currentItem.duration.seconds)
            let currentTime = Float(CMTimeGetSeconds(player.currentTime()))
            self.playbackControlsView?.setup(duration: newDurationSeconds, currentime: currentTime)
            
        default:
            self.playbackControlsView?.disable()
            
        }
    }
    
    private func updateSpinner() {
        switch self.player.timeControlStatus {
            
        case .paused:
            self.activityIndicator.stopAnimating()
            
        case .waitingToPlayAtSpecifiedRate:
            self.activityIndicator.startAnimating()
            
        case .playing:
            self.activityIndicator.stopAnimating()
            
        @unknown default:
            self.activityIndicator.stopAnimating()
        }
    }
    
    private func removeObservers() {
        self.player.pause()
        self.timeObserverToken = nil
        self.playerItemStatusObserver = nil
        self.playerTimeControlStatusObserver = nil
    }
}


//MARK: - Constants

private extension SKVideoPlayerView {
    private struct Constants {
        static let playbackControlsViewLeadingConstant: CGFloat = 44
        static let playbackControlsViewTrailingConstant: CGFloat = -44
        static let playbackControlsViewBottomConstant: CGFloat = 70
        static let playbackControlsViewHeightConstant: CGFloat = 80
        static let secondsForSeeking: Double = 15
        static let preferredTimescale: Int32 = 600
        static let delayForHidingControls: Double = 2
        static let animationTime: Double = 0.35
        static let iphoneSeScreenWidth = 320
        static let playbackConstrolsForSeWidth: CGFloat = 280
        static let playbackConstrolsOtherDevicesWidth: CGFloat = 320
        static let playButtonImage =  UIImage(named: "SKPhotoBrowser.bundle/images/ic_PlayVideo",
                                               in: Bundle(for: SKPhotoBrowser.self),
                                               compatibleWith: nil)
    }
}


// MARK: SkPresentableViewType extension

extension SKVideoPlayerView: PresentableViewType {
    
    
    func prepareForReuse() {
        self.removeObservers()
        self.videoView.removeFromSuperview()
        self.browser?.hidePlaybackControls()
    }
    
    func setMaxMinZoomScalesForCurrentBounds() {
        
    }
    
    func displayImage(_ image: UIImage) {
        
    }
    
    func displayImageFailure() {
        
    }
    
    func displayImage(complete flag: Bool) {
        
    }
}
