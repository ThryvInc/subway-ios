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
    var favoriteIds: [String]!
    var stationManager: StationManager
    var stations: [Station]?
    
    private let defaultsKey = "favorite_stations"
    
    init(stationManager: StationManager) {
        self.stationManager = stationManager
        self.favoriteIds = []

        if let names = NSUserDefaults.standardUserDefaults().stringArrayForKey(defaultsKey) as [String]! {
            self.favoriteIds = names
        }
        
        super.init()
    }
    
    // add stations to favorites list
    func addFavorites(stations: [Station]) {
        for station in stations {
            if !favoriteIds.contains(station.name) {
                favoriteIds.append(station.name)
            }
        }
        sync()
    }
    
    // remove stations from favorites list
    func removeFavorites(stations: [Station]) {
        for station in stations {
            if favoriteIds.contains(station.name) {
                favoriteIds = favoriteIds.filter( { $0 != station.name } )
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
    func findFavorites(name: String?) -> [Station]? {
        if name != nil {
            return stationManager.stationsForSearchString(name)!.filter({self.favoriteIds.contains($0.name)})
        } else {
            return stationManager.allStations.filter({self.favoriteIds.contains($0.name)})
        }
    }
    
    // get all favorites
    func favoriteStations() -> [Station]? {
        return findFavorites(nil)
    }
    
    //check if current station exists in favorites
    func isFavorite(name: String?) -> Bool {
        let stations: [Station]? = findFavorites(name)
        var isInArray: Bool = false
        for station in stations! {
            if station.name == name {
                isInArray = true
            }
        }
        return isInArray
    }

    // flush out user defaults
    private func sync() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(favoriteIds, forKey: defaultsKey)
        defaults.synchronize()
    }
}
