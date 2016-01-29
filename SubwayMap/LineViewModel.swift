//
//  LineViewModel.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 11/4/15.
//  Copyright © 2015 Thryv. All rights reserved.
//

import UIKit

class LineViewModel: NSObject {
    var routeIds: [String] = [String]()
    var color: UIColor!
    
    func routesString() -> String {
        var routesString = ""
        if routeIds.count > 0 {
            routeIds.sortInPlace({$0 < $1})
            routesString = routeIds.joinWithSeparator(", ")
        }
        return routesString
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let obj = object {
            if obj.isKindOfClass(LineViewModel.self) {
                let line = obj as! LineViewModel
                return line.color.isEqual(self.color)
            }
        }
        return false
    }
}
