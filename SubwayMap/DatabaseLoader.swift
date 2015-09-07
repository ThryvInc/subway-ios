//
//  DatabaseLoader.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 8/2/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import UIKit
import GTFSStations
import ZipArchive

class DatabaseLoader: NSObject {
    static var isDatabaseReady: Bool = false
    static var stationManager: StationManager!
    static let NYCDatabaseLoadedNotification = "NYCDatabaseLoadedNotification"
    static var documentsDirectory: String {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    }
    static var destinationPath: String {
        return self.documentsDirectory + "/" + "gtfs.db"
    }
    
    class func loadDb() {
        unzipDBToDocDirectoryIfNeeded()
        stationManager = StationManager(sourceFilePath: destinationPath)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.isDatabaseReady = true
            NSNotificationCenter.defaultCenter().postNotificationName(self.NYCDatabaseLoadedNotification, object: nil)
        })
    }
    
    class func unzipDBToDocDirectoryIfNeeded(){
        if !NSFileManager.defaultManager().fileExistsAtPath(destinationPath) {
            let sourcePath = NSBundle.mainBundle().pathForResource("gtfs.db", ofType: "zip")
            var error: NSError?
            var unzipper = ZipArchive()
            unzipper.UnzipOpenFile(sourcePath)
            unzipper.UnzipFileTo(documentsDirectory, overWrite: false)
            let fileUrl = NSURL(fileURLWithPath: destinationPath)
            fileUrl?.setResourceValue(NSNumber(bool: true), forKey: NSURLIsExcludedFromBackupKey, error: &error)
        }
    }
}
