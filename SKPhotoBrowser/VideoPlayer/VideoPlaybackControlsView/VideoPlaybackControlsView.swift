//
//  VideoPlaybackControlsView.swift
//  VideoPlayerTest
//
//  Created by Шумаков Кирилл Андреевич on 15.04.2020.
//  Copyright © 2020 kirshum. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class VideoPlaybackControlsView: UIView {
    
    var rewindButtonDidTouch: (() -> Void)?
    
    var forwardButtonDidTouch: (() -> Void)?
    
    var playPauseButtonDidTouch: (() -> Void)?
    
    var timeSliderChangedValue: ((Float) -> Void)?
    
    var timeSliderBeginEditing: (() -> Void)?
    
    var timeSliderEndEditing: (() -> Void)?
    
    @IBOutlet private weak var containerView: UIView!
    
    @IBOutlet private weak var timeSlider: UISlider!
    
    @IBOutlet private weak var currentTimeLabel: UILabel!
    
    @IBOutlet private weak var durationLabel: UILabel!
    
    @IBOutlet private weak var rewindButton: UIButton!
    
    @IBOutlet private weak var forwardButton: UIButton!
    
    @IBOutlet private weak var playPauseButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupUI()
        for state: UIControl.State in [.normal, .selected, .application, .reserved] {
            self.timeSlider.setThumbImage(Constants.videoCursor, for: state)
        }
    }
    
    
    //MARK: -IBActions
    
    @IBAction private func rewindButtonDidTouch(_ sender: UIButton) {
        self.rewindButtonDidTouch?()
    }
    
    @IBAction private func forwardButtonDidTouch(_ sender: Any) {
        self.forwardButtonDidTouch?()
    }
    
    @IBAction private func playPauseButtonDidTouch(_ sender: Any) {
        self.playPauseButtonDidTouch?()
    }
    
    @IBAction func timeSliderDidChange(_ sender: UISlider, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
                
            case .began:
                self.timeSliderBeginEditing?()
                self.timeSliderChangedValue?(sender.value)
                
            case .moved:
                self.timeSliderChangedValue?(sender.value)
                
            case .ended:
                self.timeSliderEndEditing?()
                self.timeSliderChangedValue?(sender.value)
                
            default:
                break
            }
        }
    }
    
    
    // MARK: -
    
    func setup(duration: Float?, currentime: Float) {
        guard let duration = duration
            else {
                self.setupEmptyState()
                return
        }
        self.timeSlider.maximumValue = duration
        self.durationLabel.text = self.createTimeString(time: duration)
        self.update(currentime: currentime)
    }
    
    func update(currentime: Float) {
        self.timeSlider.value = currentime
        self.currentTimeLabel.text = self.createTimeString(time: currentime)
    }
    
    func setPlayPauseButtonImage(for state: AVPlayer.TimeControlStatus) {
        let buttonImage: UIImage?
        
        switch state {
            
        case .paused, .waitingToPlayAtSpecifiedRate:
            buttonImage = Constants.playButtonImage
            
        case .playing:
            buttonImage = Constants.pauseButtonImage
            
        @unknown default:
            buttonImage = Constants.pauseButtonImage
        }
        
        guard let image = buttonImage else { return }
        self.playPauseButton.setImage(image, for: .normal)
    }
    
    func disable() {
        self.timeSlider.isEnabled = false
        self.rewindButton.isEnabled = false
        self.forwardButton.isEnabled = false
        self.playPauseButton.isEnabled = false
    }
    
    func enable() {
        self.timeSlider.isEnabled = true
        self.rewindButton.isEnabled = true
        self.forwardButton.isEnabled = true
        self.playPauseButton.isEnabled = true
    }
    
    func setupEmptyState() {
        self.durationLabel.text = Constants.emptyStateDurationText
        self.timeSlider.value = 0
        self.currentTimeLabel.text = Constants.emptyStateCurrentTimeText
        self.setPlayPauseButtonImage(for: .paused)
    }
    
    
    // MARK: - Private
    
    private func setupUI() {
        self.containerView.layer.cornerRadius = Constants.containerViewRadius
        self.setupEmptyState()
        self.disable()
    }
    
    func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
    
    let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }()
}

private extension VideoPlaybackControlsView {
    struct Constants {
        static let containerViewRadius: CGFloat = 10
        static let pauseButtonImage =  UIImage(named: "SKPhotoBrowser.bundle/images/pause",
                                               in: Bundle(for: SKPhotoBrowser.self),
                                               compatibleWith: nil)
        static let playButtonImage =  UIImage(named: "SKPhotoBrowser.bundle/images/play",
                                              in: Bundle(for: SKPhotoBrowser.self),
                                              compatibleWith: nil)
        
        static let videoCursor = UIImage(named: "SKPhotoBrowser.bundle/images/icVedeoCursor",
                                         in: Bundle(for: SKPhotoBrowser.self),
                                         compatibleWith: nil)
        static let emptyStateDurationText = "-/-"
        static let emptyStateCurrentTimeText = "0"
        
    }
}
