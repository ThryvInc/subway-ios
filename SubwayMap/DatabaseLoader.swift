//
//  DatabaseLoader.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 8/2/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import UIKit
import GTFSStations
import SubwayStations
import ZipArchive

class DatabaseLoader: NSObject {
    static var isDatabaseReady: Bool = false
    static var stationManager: StationManager!
    static let NYCDatabaseLoadedNotification = "NYCDatabaseLoadedNotification"
    static var documentsDirectory: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
    }
    static var destinationPath: String {
        return self.documentsDirectory + "/" + "gtfs.db"
    }
    
    class func loadDb() {
        unzipDBToDocDirectoryIfNeeded()
        do {
            stationManager = try NYCStationManager(sourceFilePath: destinationPath)
            DispatchQueue.main.async (execute: { () -> Void in
                self.isDatabaseReady = true
                NotificationCenter.default.post(name: Notification.Name(rawValue: self.NYCDatabaseLoadedNotification), object: nil)
            })
        }catch let error as NSError{
            print(error.debugDescription)
        }
    }
    
    class func unzipDBToDocDirectoryIfNeeded(){
        if !FileManager.default.fileExists(atPath: destinationPath) {
            let sourcePath = Bundle.main.path(forResource: "gtfs.db", ofType: "zip")
            var error: NSError?
            let unzipper = ZipArchive()
            unzipper.unzipOpenFile(sourcePath)
            unzipper.unzipFile(to: documentsDirectory, overWrite: false)
            let fileUrl = URL(fileURLWithPath: destinationPath)
            do {
                try (fileUrl as NSURL).setResourceValue(NSNumber(value: true as Bool), forKey: URLResourceKey.isExcludedFromBackupKey)
            } catch let error1 as NSError {
                error = error1
            }
        }
    }
}
