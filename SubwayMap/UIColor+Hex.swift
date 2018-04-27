//
//  UIColor+Hex.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 4/4/18.
//  Copyright © 2018 Thryv. All rights reserved.
//

import UIKit

extension UIColor {
    open static func primary() -> UIColor {
        return uicolorFromHex(rgbValue: 0x4d55a2)
    }
    
    open static func primaryDark() -> UIColor {
        return uicolorFromHex(rgbValue: 0x333972)
    }
    
    open static func accent() -> UIColor {
        return uicolorFromHex(rgbValue: 0xdf03a6)
    }
    
    static func uicolorFromHex(rgbValue: UInt32) -> UIColor{
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        
        return UIColor(red:red, green:green, blue:blue, alpha:1.0)
    }
}
