//
//  SKToolbar.swift
//  SKPhotoBrowser
//
//  Created by keishi_suzuki on 2017/12/20.
//  Copyright © 2017年 suzuki_keishi. All rights reserved.
//

import Foundation

// helpers which often used
private let bundle = Bundle(for: SKPhotoBrowser.self)

// TODO: [refactoring] make toolbar more customizable

class SKToolbar: UIToolbar {
    
    open var isLiked: Bool = false {
        didSet {
            self.likeButton?.isSelected = self.isLiked
        }
    }
    
    open var isOffline: Bool = false {
        didSet {
            self.offlineButtin?.isSelected = self.isOffline
        }
    }
    
    var toolActionButton: UIBarButtonItem!
    
    fileprivate weak var browser: SKPhotoBrowser?
    
    fileprivate weak var likeButton: SKSelectableButton?
    
    fileprivate weak var offlineButtin: SKSelectableButton?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, browser: SKPhotoBrowser) {
        self.init(frame: frame)
        self.browser = browser
        
        setupApperance()
        setupToolbar()
    }
}

extension SKToolbar {
    
    func setControlsHidden(hidden: Bool) {
        let alpha: CGFloat = hidden ? 0.0 : 1.0
        
        UIView.animate(withDuration: 0.35,
                       animations: { self.alpha = alpha },
                       completion: nil)
    }
}

private extension SKToolbar {
    func setupApperance() {
        backgroundColor = .clear
        clipsToBounds = true
        isTranslucent = true
        setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
    }
    
    func setupToolbar() {
        var items = [UIBarButtonItem]()
        
        self.toolActionButton = self.barBattonItem(imageName: "SKPhotoBrowser.bundle/images/btn_common_action_wh",
                                                   selector: #selector(actionButtonPressed))
        
        let likeItem = self.getSkSelectButton(of: .like,
                                              selector: #selector(likeButtonPressed(_:)))
        
        let offlineItem = self.getSkSelectButton(of: .offline,
                                                 selector: #selector(self.offlineButtonPressed(_:)))
        
        let deleteItem = self.barBattonItem(imageName: "SKPhotoBrowser.bundle/images/btn_common_delete_wh",
                                            selector: #selector(deleteButtonPressed(_:)))
        
        items.append(contentsOf: [toolActionButton,
                                  UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                                  UIBarButtonItem(customView: likeItem),
                                  UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                                  UIBarButtonItem(customView: offlineItem),
                                  UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
                                  deleteItem])
        
        self.setItems(items, animated: false)
        
    }
    
    @objc func offlineButtonPressed(_ sender: SKOfflineButton) {
        guard let browser = self.browser else { return }
        browser.delegate?.addItemToOffline?(browser, index: browser.currentPageIndex, sender: sender)
    }
    
    @objc func likeButtonPressed(_ sender: SKLikeButton) {
        guard let browser = self.browser else { return }
        browser.delegate?.changeLikedState?(browser, index: browser.currentPageIndex, sender: sender)
    }
    
    @objc func deleteButtonPressed(_ sender: UIButton) {
        guard let browser = self.browser else { return }
        browser.delegate?.removePhoto?(browser, index: browser.currentPageIndex) { [weak self] in
            self?.browser?.deleteImage()
        }
    }
    
    @objc func actionButtonPressed(_ sender: UIButton) {
        guard let browser = self.browser else { return }
        browser.delegate?.shareMedia?(browser)
    }
    
    private func barBattonItem(imageName: String, selector: Selector) -> UIBarButtonItem {
        let bundle = Bundle.init(for: SKToolbar.self)
        let buttonImage = UIImage(named: imageName, in: bundle, compatibleWith: nil)?
            .withRenderingMode(.alwaysTemplate)
        let button = UIButton(type: .custom)
        button.addTarget(self, action: selector, for: .touchUpInside)
        button.setImage(buttonImage, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        button.tintColor = .white
        return UIBarButtonItem(customView: button)
    }
    
    private func getSkSelectButton(of type: SKSelectableButtonType, selector: Selector) -> UIButton {
        let button: SKSelectableButton
        switch type {
        case .like:
            button = SKLikeButton()
            self.likeButton = button
        case .offline:
            button = SKOfflineButton()
            self.offlineButtin = button
        }
        button.addTarget(self, action: selector, for: .touchUpInside)
        button.imageView?.contentMode = .scaleAspectFit
        button.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        button.tintColor = .white
        return button
    }
}

