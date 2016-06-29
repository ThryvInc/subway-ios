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
        
        if ["1","2","3"].contains(routeId) {
            color = UIColor(rgba: "#ED3B43")
        }
        
        if ["4","5","5X","6","6X"].contains(routeId) {
            color = UIColor(rgba: "#00A55E")
        }
        
        if ["7","7X"].contains(routeId) {
            color = UIColor(rgba: "#A23495")
        }
        
        if ["A","C","E"].contains(routeId) {
            color = UIColor(rgba: "#006BB7")
        }
        
        if ["B","D","F","M"].contains(routeId) {
            color = UIColor(rgba: "#F58120")
        }
        
        if ["N","Q","R"].contains(routeId) {
            color = UIColor(rgba: "#FFD51D")
        }
        
        if ["JZ"].contains(routeId) {
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
            let index   = rgba.startIndex.advancedBy(1)
            let hex     = rgba.substringFromIndex(index)
            let scanner = NSScanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            if scanner.scanHexLongLong(&hexValue) {
                switch (hex.characters.count) {
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
                    print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8", terminator: "")
                }
            } else {
                print("Scan hex error")
            }
        } else {
            print("Invalid RGB string, missing '#' as prefix", terminator: "")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}
