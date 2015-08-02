//
//  NYCRouteColorManager.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 8/1/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import UIKit
import GTFSStations

class NYCRouteColorManager: RouteColorManager {
    
    override class func colorForRouteId(routeId: String!) -> UIColor {
        var color: UIColor = UIColor.darkGrayColor()
        
        if contains(["1","2","3"], routeId) {
            color = UIColor(rgba: "#ED3B43")
        }
        
        if contains(["4","5","5X","6"], routeId) {
            color = UIColor(rgba: "#00A55E")
        }
        
        if contains(["7","7X"], routeId) {
            color = UIColor(rgba: "#A23495")
        }
        
        if contains(["A","C","E"], routeId) {
            color = UIColor(rgba: "#006BB7")
        }
        
        if contains(["B","D","F","M"], routeId) {
            color = UIColor(rgba: "#F58120")
        }
        
        if contains(["N","Q","R"], routeId) {
            color = UIColor(rgba: "#FFD51D")
        }
        
        if contains(["JZ"], routeId) {
            color = UIColor(rgba: "#B1730E")
        }
        
        return color
    }
   
}
extension UIColor {
    public convenience init(rgba: String) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        
        if rgba.hasPrefix("#") {
            let index   = advance(rgba.startIndex, 1)
            let hex     = rgba.substringFromIndex(index)
            let scanner = NSScanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            if scanner.scanHexLongLong(&hexValue) {
                switch (count(hex)) {
                case 3:
                    red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                    green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                    blue  = CGFloat(hexValue & 0x00F)              / 15.0
                case 4:
                    red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                    green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                    blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                    alpha = CGFloat(hexValue & 0x000F)             / 15.0
                case 6:
                    red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
                case 8:
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
                default:
                    print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8")
                }
            } else {
                println("Scan hex error")
            }
        } else {
            print("Invalid RGB string, missing '#' as prefix")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}
