//  UIView+Nib.swift
//  VideoPlayerTest
//
//  Created by Шумаков Кирилл Андреевич on 15.04.2020.
//  Copyright © 2020 kirshum. All rights reserved.
//
import UIKit

func LoadFromNib<T: UIView>(viewOfClass _: T.Type) -> T {
    let nibName = String(describing: T.self)
    let bundle = Bundle(for: SKPhotoBrowser.self)
    guard let nib =  bundle.loadNibNamed(nibName, owner: nil, options: nil)
        , let firstView = nib.first
        , let view = firstView as? T
        else {
            preconditionFailure("Не удалось получить view из nib. nibName: \(nibName)")
    }
    return view
}
