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
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
    }
    static var destinationPath: String {
        return self.documentsDirectory + "/" + "gtfs.db"
    }
    
    class func loadDb() {
        unzipDBToDocDirectoryIfNeeded()
        do {
            stationManager = try StationManager(sourceFilePath: destinationPath)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.isDatabaseReady = true
                NSNotificationCenter.defaultCenter().postNotificationName(self.NYCDatabaseLoadedNotification, object: nil)
            })
        }catch let error as NSError{
            print(error.debugDescription)
        }
    }
    
    class func unzipDBToDocDirectoryIfNeeded(){
        if !NSFileManager.defaultManager().fileExistsAtPath(destinationPath) {
            let sourcePath = NSBundle.mainBundle().pathForResource("gtfs.db", ofType: "zip")
            var error: NSError?
            let unzipper = ZipArchive()
            unzipper.UnzipOpenFile(sourcePath)
            unzipper.UnzipFileTo(documentsDirectory, overWrite: false)
            let fileUrl = NSURL(fileURLWithPath: destinationPath)
            do {
                try fileUrl.setResourceValue(NSNumber(bool: true), forKey: NSURLIsExcludedFromBackupKey)
            } catch let error1 as NSError {
                error = error1
            }
        }
    }
}
