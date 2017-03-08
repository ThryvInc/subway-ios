//
//  AppDelegate.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 5/9/16.
//  Copyright © 2016 Thryv. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import NagController
import GTFSStationsParis
import SubwayStations

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, NagControllerDelegate {
    let LastNaggedKey = "LastNaggedKey"
    var window: UIWindow?
    var nagger: NagController!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Fabric.with([Crashlytics()])
        
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = UIColor(red: 58.0/255.0, green: 58.0/255.0, blue: 58.0/255.0, alpha: 1)
        UINavigationBar.appearance().tintColor = UIColor(red: 248.0/255.0, green: 248.0/255.0, blue: 248.0/255.0, alpha: 1)
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName : UIFont(name: "AvenirNext-Regular", size: 20)!, NSForegroundColorAttributeName : UIColor(red: 248.0/255.0, green: 248.0/255.0, blue: 248.0/255.0, alpha: 1)]
        
        DispatchQueue.global( priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { () -> Void in
            DatabaseLoader.loadDb()
        })
        var appOpens = UserDefaults.standard.integer(forKey: "numberOfAppOpens")
        appOpens += 1
        UserDefaults.standard.set(appOpens, forKey: "numberOfAppOpens")
        
        if appOpens % 3 == 0 {
            if let lastTime = lastNagged() {
                if lastTime.isBefore(Date().increment(NSCalendar.Unit.day, amount: -2)!) {
                    nag()
                }
            }else{
                nag()
            }
        }
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let mapVC = MapViewController(nibName: "MapViewController", bundle: nil)
        
        let navVC = AdNavigationController(rootViewController: mapVC)
        window?.rootViewController = navVC;
        window?.makeKeyAndVisible()
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    class func colorManager() -> RouteColorManager {
        return PARRouteColorManager()
    }
    
    func nag() {
        nagger = NagController()
        nagger.delegate = self
        nagger.ratingURLStr = "https://itunes.apple.com/us/app/metro-paris-plan-du-metro/id1132267822?ls=1&mt=8"
        nagger.startNag()
    }
    
    func lastNagged() -> Date? {
        return UserDefaults.standard.object(forKey: LastNaggedKey) as? Date
    }
    
    // MARK: Nag Delegate
    
    func didPerformNag(_ eventName: String!, with response: NagResponse) {
        UserDefaults.standard.set(Date(), forKey: LastNaggedKey)
    }
    
}
