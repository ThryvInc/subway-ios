//
//  LineViewModel.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 11/4/15.
//  Copyright © 2015 Thryv. All rights reserved.
//

import UIKit
import SubwayStations

class LineViewModel: NSObject {
    var routeIds: [String] = [String]()
    var color: UIColor!
    
    func routesString() -> String {
        var routesString = ""
        if routeIds.count > 0 {
            routeIds.sort(by: {$0 < $1})
            routesString = routeIds.joined(separator: ", ")
        }
        return routesString
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let obj = object {
            if (obj as AnyObject).isKind(of: LineViewModel.self) {
                let line = obj as! LineViewModel
                return line.color.isEqual(self.color)
            }
        }
        return false
    }
}

extension StationManager {
    func linesForStation(_ station: Station) -> [LineViewModel]? {
        var lineModels = [LineViewModel]()
        let routeIds = routeIdsForStation(station)
        
        for routeId in routeIds {
            let lineModel = LineViewModel()
            lineModel.routeIds = [routeId]
            lineModel.color = AppDelegate.colorManager().colorForRouteId(routeId)
            let lineIndex = lineModels.index(of: lineModel)
            if let index = lineIndex {
                if !lineModels[index].routeIds.contains(routeId) {
                    lineModels[index].routeIds.append(routeId)
                }
            }else{
                lineModels.append(lineModel)
            }
        }
        return lineModels
    }
}
