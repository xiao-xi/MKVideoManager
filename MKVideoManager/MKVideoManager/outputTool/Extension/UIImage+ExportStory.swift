//
//  UIImage+TLStory.swift
//  TLStoryCamera
//
//  Created by GarryGuo on 2017/5/10.
//  Copyright © 2017年 GarryGuo. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    public static func imageWithFilter(named:String) -> UIImage? {
        let bundlePath = Bundle.main.path(forResource: "TLStoryCameraResources", ofType: "bundle")
        let bundle = Bundle.init(path: bundlePath!)
        let path = bundle?.path(forResource: named, ofType: "png", inDirectory: "TLStoryCameraFilter")

        return UIImage.init(contentsOfFile: path!)
    }
}

extension UIImage {
    public func imageMontage(img:UIImage, bgColor:UIColor?, size:CGSize) -> UIImage {
        let newImg = self.scale(x: size.width / self.size.width)
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        
        if let c = bgColor {
            c.set()
            UIRectFill(CGRect.init(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        newImg.draw(in: CGRect.init(x: (size.width - newImg.size.width) / 2, y: (size.height - newImg.size.height) / 2, width: newImg.size.width, height: newImg.size.height), blendMode: CGBlendMode.normal, alpha: 1.0)
        img.draw(in: CGRect.init(x: 0, y: 0, width: size.width, height: size.height), blendMode: CGBlendMode.normal, alpha: 1.0)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
    
    public func addWatermark(img:UIImage?, p:UIEdgeInsets) -> UIImage {
        guard let watermark = img else {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        
        self.draw(in: CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height))
        
        if p.bottom != 0, p.left != 0 {
            watermark.draw(in: CGRect.init(x: p.left, y: self.size.height - p.bottom - watermark.size.height, width: watermark.size.width, height: watermark.size.height))
        }else if p.bottom != 0, p.right != 0 {
            watermark.draw(in: CGRect.init(x: self.size.width - p.right - watermark.size.width, y: self.size.height - p.bottom - watermark.size.height, width: watermark.size.width, height: watermark.size.height))
        }else if p.top != 0, p.left != 0 {
            watermark.draw(in: CGRect.init(x: p.left, y: p.top, width: watermark.size.width, height: watermark.size.height))
        }else if p.top != 0, p.right != 0 {
            watermark.draw(in: CGRect.init(x: self.size.height - p.bottom - watermark.size.height, y: p.top, width: watermark.size.width, height: watermark.size.height))
        }else {
            assert(false, "Watermark position error")
        }
                
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
    
    public func scale(x:CGFloat) -> UIImage {
        if x == 1.0 {
            return self
        }
        
        let newSize = CGSize.init(width: self.size.width * x, height: self.size.height * x)
        
        UIGraphicsBeginImageContext(newSize)
        self.draw(in: CGRect.init(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return img!
    }
}