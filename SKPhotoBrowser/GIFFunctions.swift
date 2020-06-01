//
//  GIFFunctions.swift
//  SKPhotoBrowser
//
//  Created by MIP9 on 01.06.2020.
//  Copyright © 2020 suzuki_keishi. All rights reserved.
//

import Foundation
import MobileCoreServices

private let gifType: CFString = kUTTypeGIF

/// Check data is GIF
public func DataIsGif(_ data: Data) -> Bool {
    var byte: UInt8 = 0
    data.copyBytes(to: &byte, count: 1)
    return byte == 0x47
}

/// Check type of file from URL
public func FileIsGIF(at path: URL) -> Bool {
    guard let resources = try? path.resourceValues(forKeys: [.typeIdentifierKey])
        , let utType = resources.typeIdentifier else {
        return false
    }
    return UTTypeConformsTo(utType as CFString, gifType)
}
