//
//  DatabaseLoader.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 8/2/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import UIKit
import GTFSStations

class DatabaseLoader: NSObject {
    static var isDatabaseReady: Bool = false
    static var stationManager: StationManager!
    static let NYCDatabaseLoadedNotification = "NYCDatabaseLoadedNotification"
    
    class func loadDb() {
        stationManager = StationManager(filename: "gtfs.db")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.isDatabaseReady = true
            NSNotificationCenter.defaultCenter().postNotificationName(self.NYCDatabaseLoadedNotification, object: nil)
        })
    }
}
