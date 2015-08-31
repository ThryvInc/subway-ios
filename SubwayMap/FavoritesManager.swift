//
//  FavoritesManager.swift
//  SubwayMap
//
//  Created by Cliff Spencer on 8/30/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import Foundation
import GTFSStations

class FavoritesManager: NSObject {
    var favoriteIds: Array<String>
    var stationManager: StationManager
    
    private let defaultsKey = "favorite_stations"
    
    init(stationManager: StationManager) {
        self.stationManager = stationManager
        self.favoriteIds = []

        if let names = NSUserDefaults.standardUserDefaults().stringArrayForKey(defaultsKey) as? Array<String> {
            self.favoriteIds = names
        }
        
        super.init()
    }
    
    // add stations to favorites list
    func addFavorites(stations: Array<Station>) {
        for station in stations {
            if !contains(favoriteIds, station.objectId) {
                favoriteIds.append(station.objectId)
            }
        }
        sync()
    }
    
    // remove stations from favorites list
    func removeFavorites(stations: Array<Station>) {
        for station in stations {
            if contains(favoriteIds, station.objectId) {
                favoriteIds = favoriteIds.filter( { $0 != station.objectId } )
            }
        }
        sync()
    }
    
    // clear all favorites
    func clear() {
        favoriteIds.removeAll(keepCapacity: true)
        sync()
    }
    
    // find favorites by substring
    func findFavorites(name: String?) -> Array<Station>? {
        if name != nil {
            return stationManager.stationsForSearchString(name)!.filter({contains(self.favoriteIds, $0.objectId)})
        } else {
            return stationManager.allStations.filter({contains(self.favoriteIds, $0.objectId)})
        }
    }

    // flush out user defaults
    private func sync() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(favoriteIds, forKey: defaultsKey)
        defaults.synchronize()
    }
}
