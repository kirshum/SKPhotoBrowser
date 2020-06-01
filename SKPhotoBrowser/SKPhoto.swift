//
//  SKPhoto.swift
//  SKViewExample
//
//  Created by suzuki_keishi on 2015/10/01.
//  Copyright © 2015 suzuki_keishi. All rights reserved.
//

import UIKit

// MARK: - SKPhoto
open class SKPhoto: NSObject, SKPhotoProtocol {
    
    open var index: Int = 0
    open var underlyingImage: UIImage!
    open var caption: String?
    open var contentMode: UIView.ContentMode = .scaleAspectFill
    open var shouldCachePhotoURLImage: Bool = false
    open var photoURL: String!
    open var type: MediaType = .image
    
    open var isLiked: Bool = false
    
    open var isOffline: Bool = false
    
    open var videoStreamURL: URL?
    
    override init() {
        super.init()
    }
    
    convenience init(image: UIImage) {
        self.init()
        underlyingImage = image
    }
    
    convenience init(url: String) {
        self.init()
        photoURL = url
    }
    
    convenience init(url: String, holder: UIImage?) {
        self.init()
        photoURL = url
        underlyingImage = holder
    }
    
    open func checkCache() {
        guard let photoURL = photoURL else {
            return
        }
        guard shouldCachePhotoURLImage else {
            return
        }
        
        if SKCache.sharedCache.imageCache is SKRequestResponseCacheable {
            let request = URLRequest(url: URL(string: photoURL)!)
            if let img = SKCache.sharedCache.imageForRequest(request) {
                underlyingImage = img
            }
        } else {
            if let img = SKCache.sharedCache.imageForKey(photoURL) {
                underlyingImage = img
            }
        }
    }
    
    open func loadUnderlyingImageAndNotify() {
        guard photoURL != nil, let url = URL(string: photoURL) else { return }
        
        // Fetch Image
        let session = URLSession(configuration: SKPhotoBrowserOptions.sessionConfiguration)
        var task: URLSessionTask?
        task = session.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
            guard let self = self else { return }
            defer { session.finishTasksAndInvalidate() }
            
            guard error == nil else {
                self.loadUnderlyingImageComplete()
                return
            }
            
            if let data = data, let response = response {
                let maybeImage: UIImage?
                if DataIsGif(data) {
                    maybeImage = UIImage.gif(from: data)
                } else {
                    maybeImage = UIImage(data: data)
                }
                guard let image = maybeImage else {
                    self.loadUnderlyingImageComplete()
                    return
                }
                if self.shouldCachePhotoURLImage {
                    if SKCache.sharedCache.imageCache is SKRequestResponseCacheable {
                        SKCache.sharedCache.setImageData(data, response: response, request: task?.originalRequest)
                    } else {
                        SKCache.sharedCache.setImage(image, forKey: self.photoURL)
                    }
                }
                self.loadUnderlyingImageComplete(image)
            }
            
        })
        task?.resume()
    }
    
    open func loadUnderlyingImageComplete(_ maybeImage: UIImage? = nil) {
        DispatchQueue.main.async {
            if let image = maybeImage {
                self.underlyingImage = image
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: SKPHOTO_LOADING_DID_END_NOTIFICATION), object: self)
        }
    }
    
}

// MARK: - Static Function

extension SKPhoto {
    public static func photoWithImage(_ image: UIImage) -> SKPhoto {
        return SKPhoto(image: image)
    }
    
    public static func photoWithImageURL(_ url: String) -> SKPhoto {
        return SKPhoto(url: url)
    }
    
    public static func photoWithImageURL(_ url: String, holder: UIImage?) -> SKPhoto {
        return SKPhoto(url: url, holder: holder)
    }
}
