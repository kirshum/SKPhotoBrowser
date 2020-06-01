//
//  UIImage+GIF.swift
//  SKPhotoBrowser
//
//  Created by MIP9 on 01.06.2020.
//  Copyright © 2020 suzuki_keishi. All rights reserved.
//

import UIKit
import ImageIO

extension UIImage {
    
    public class func gif(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        return UIImage.animatedImageWithSource(source)
    }
    
    
    public class func gif(at path: String) -> UIImage? {
        guard let url = URL(string: path) else {
            return nil
        }
        guard let imageData = try? Data(contentsOf: url) else {
            return nil
        }
        return gif(from: imageData)
    }
    
    /// Расчет длительности кадра
    internal class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        // дефолтное значение длительности кадра
        var delay = 0.1
        
        // Получаем все проперти сорса
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifPropertiesPointer = UnsafeMutablePointer<UnsafeRawPointer?>
            .allocate(capacity: 0)
        
        defer {
            gifPropertiesPointer.deallocate()
        }
        
        // кастуем ключ к словарю пропертей гиф картинки
        let unsafePointer = Unmanaged
            .passUnretained(kCGImagePropertyGIFDictionary)
            .toOpaque()
        // проверяем, есть ли в пропертях сорса значенме по ключу unsafePointer.
        // Если есть, то будет true и значение запишется в gifPropertiesPointer
        if CFDictionaryGetValueIfPresent(cfProperties, unsafePointer, gifPropertiesPointer) == false {
            return delay
        }
        
        // кастуем вытащенные проперти в словарь
        let gifProperties: CFDictionary = unsafeBitCast(
            gifPropertiesPointer.pointee,
            to: CFDictionary.self)
        
        // Для каждого кадра время нахождения на экране может отличаться, поэтому надо их вычислать из пропертей.
        // Сначала надо вычислить 'неограниченное' время, если кадр показывается на экране очень быстро
        // (по ключу kCGImagePropertyGIFUnclampedDelayTime)
        // Если  оно == 0, то берем другое время, которое зависит от нижней границы времени кадра
        // (по ключу kCGImagePropertyGIFDelayTime)
        // Из описания примерный перевод: если значение времени меньше или рабно 50мс, то значение
        // по данному ключу будет 100мс)
        
        let unclampedProtperty = CFDictionaryGetValue(
            gifProperties,
            Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque())
        var delayObject: AnyObject = unsafeBitCast(unclampedProtperty, to: AnyObject.self)
        
        if delayObject.doubleValue == 0 {
            let clampedProperty = CFDictionaryGetValue(
                gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque())
            delayObject = unsafeBitCast(clampedProperty, to: AnyObject.self)
        }
        
        // Проверим на всякий случай, что значение больше 0
        if let delayObject = delayObject as? Double, delayObject > 0 {
            delay = delayObject
        } else {
            delay = 0.1
        }
        
        return delay
    }
    
    /// Найти наибольший общий делитель (НОД) для двух чисел
    internal class func gcdForPair(_ lhs: Int?, _ rhs: Int?) -> Int {
        guard var lhsValue = lhs, var rhsValue = rhs else {
            if let rVal = rhs {
                return rVal
            } else if let lVal = lhs {
                return lVal
            } else {
                return 0
            }
        }
        
        if lhsValue < rhsValue {
            (lhsValue, rhsValue) = (rhsValue, lhsValue)
        }
        
        var rest: Int
        while true {
            rest = lhsValue % rhsValue
            
            if rest == 0 {
                return rhsValue
            } else {
                lhsValue = rhsValue
                rhsValue = rest
            }
        }
    }
    
    /// Найти НОД для массива чисел
    internal class func gcdForArray(_ array: [Int]) -> Int {
        if array.isEmpty {
            return 1
        }
        var gcd = array[0]
        for val in array {
            // по правилам, найти НОД нескольких чисел можно следующим образом
            // НОД(х1, х2, х3) = НОД(НОД(х1, х2), х3)
            gcd = UIImage.gcdForPair(val, gcd)
        }
        return gcd
    }
    
    
    internal class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        // получаем количество кор графикс картинок в гифке
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()
        
        for index in 0..<count {
            // Получаем картинку по индексу и добавляем в массив
            if let image = CGImageSourceCreateImageAtIndex(source, index, nil) {
                images.append(image)
            }
            
            // получаем длительность картинки в секундах
            let delaySeconds = UIImage.delayForImageAtIndex(
                index,
                source: source)
            // переводим в милисекунды
            let ms = Int(delaySeconds * 1000.0)
            delays.append(ms)
        }
        
        // вычисляем полную длительность
        let duration: Int = {
            var sum = 0
            
            for val: Int in delays {
                sum += val
            }
            
            return sum
        }()
        
        // Кор графикс картинки преобразуем в UIImage
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()
        
        var frame: UIImage
        var frameCount: Int
        for index in 0..<count {
            frame = UIImage(cgImage: images[index])
            frameCount = Int(delays[index] / gcd)
            
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        
        // Из фреймов собираем анимированную картинку
        let animation = UIImage.animatedImage(
            with: frames,
            duration: Double(duration) / 1000.0)
        
        return animation
    }
}

