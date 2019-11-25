//
//  SKSelectableButton.swift
//  SKPhotoBrowser
//
//  Created by Шумаков Кирилл Андреевич on 25.11.2019.
//  Copyright © 2019 suzuki_keishi. All rights reserved.
//

import Foundation
import UIKit

public class SKSelectableButton: UIButton {
    
    public override var isSelected: Bool {
        didSet {
            self.setupImage()
        }
    }
    
    public func switchState() {
        self.isSelected.toggle()
    }
    
    private var filledImage: UIImage
    
    private var clearImage: UIImage

    required init(filledImage: UIImage, clearImage: UIImage) {
        self.filledImage = filledImage
        self.clearImage = clearImage
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupImage() {
        self.backgroundColor = .clear
        let image = self.isSelected
            ? self.filledImage
            : self.clearImage
        
        self.setImage(image, for: .normal)
    }
}

enum SKSelectableButtonType {
    /// Кнопка лайка
    case like
    /// Кнопка добавления в оффлайн
    case offline
}
