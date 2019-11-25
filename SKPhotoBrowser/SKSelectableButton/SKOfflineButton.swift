//
//  SKOfflineButton.swift
//  SKPhotoBrowser
//
//  Created by Шумаков Кирилл Андреевич on 25.11.2019.
//  Copyright © 2019 suzuki_keishi. All rights reserved.
//

import Foundation
import UIKit

public class SKOfflineButton: SKSelectableButton {
    convenience init() {
        let filledImage = UIImage(named: "SKPhotoBrowser.bundle/images/btn_offline_filled_wh",
                                        in: Bundle(for: SKPhotoBrowser.self),
                                        compatibleWith: nil) ?? UIImage()

        let clearImage = UIImage(named: "SKPhotoBrowser.bundle/images/btn_offline_wh",
                                        in: Bundle(for: SKPhotoBrowser.self),
                                        compatibleWith: nil) ?? UIImage()
        
        self.init(filledImage: filledImage, clearImage: clearImage)
    }
}
