//
//  FavoritesManagerTest.swift
//  SubwayMap
//
//  Created by Cliff Spencer on 8/30/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import Quick
import Nimble
import GTFSStations


class FavoritesSpec: QuickSpec {
    override func spec() {
        describe("Favorites", { () -> Void in
            let stationManager: StationManager! = StationManager(filename: "gtfs.db")
            let favoritesManager: FavoritesManager! = FavoritesManager(stationManager: stationManager)
            
            it("can clear all favorites") {
                let stationName = "Astor Pl"
                let stations: Array<Station>? = stationManager.stationsForSearchString(stationName)
                expect(stations).toNot(beNil())
                expect(stations!.count == 1).to(beTruthy())
                
                favoritesManager.addFavorites(stations!)
                let favorites: Array<Station>? = favoritesManager.findFavorites(nil)
                expect(favorites!.count).to(beTruthy())
                
                favoritesManager.clear()
                let emptyFavorites = favoritesManager.findFavorites(nil)
                expect(stations).toNot(beNil())
                expect(emptyFavorites!.isEmpty).to(beTruthy())
            }
            
            it("can add a favorite") {
                let allStations = stationManager.allStations
                let station = allStations.first
                favoritesManager.addFavorites([station!])
                
                let favorites: Array<Station>? = favoritesManager.findFavorites(nil)
                expect(favorites).toNot(beNil())
                expect(favorites!.count).to(beTruthy())
                expect(favorites).to(contain(station))
            }
            
            it("can remove a favorite") {
                let stations = Array(stationManager.allStations[0...2])
                expect(stations.count == 3).to(beTrue())
                favoritesManager.addFavorites(stations)
                
                favoritesManager.removeFavorites([stations[1]])
                var favorites: Array<Station>? = favoritesManager.findFavorites(nil)
                expect(favorites).toNot(contain(stations[1]))
            }
            
            it ("can find a favorite") {
                favoritesManager.clear()
                let stationName = "Astor Pl"
                let stations: Array<Station>? = stationManager.stationsForSearchString(stationName)
                expect(stations).toNot(beNil())
                expect(stations!.count == 1).to(beTruthy())
                
                let favorites: Array<Station>? = favoritesManager.findFavorites(stationName)
                
                expect(stations).toNot(beNil())
                expect(stations!.count == 1).to(beTrue())
                expect(stations![0].name == stationName).to(beTruthy())
            }
            
            it ("can find multiple favorites") {
                favoritesManager.clear()
                let stationName = "Astor"
                let stations: Array<Station>? = stationManager.stationsForSearchString(stationName)
                expect(stations).toNot(beNil())
                expect(stations!.count == 3).to(beTruthy())
                
                favoritesManager.addFavorites(stations!)

                let favorites: Array<Station>? = favoritesManager.findFavorites(stationName)
                expect(stations).toNot(beNil())
                expect(stations!.count == 3).to(beTrue())
                
                for stationName in ["Astor Pl", "Astoria Blvd", "Astoria - Ditmars Blvd"] {
                    let station = favorites!.filter( { $0.name == stationName } )
                    expect(station).toNot(beNil())
                    expect(station.count == 1).to(beTrue())
                    println("station: \(stationName)")
                    expect(station[0].name == stationName).to(beTruthy())

                }
            }
            
            it ("can save and restore favorites") {
                favoritesManager.clear()
                let stationName = "Astor Pl"
                let stations: Array<Station>? = stationManager.stationsForSearchString(stationName)
                expect(stations).toNot(beNil())
                expect(stations!.count == 1).to(beTruthy())
                
                favoritesManager.addFavorites(stations!)
                
                let newFavoritesManager: FavoritesManager! = FavoritesManager(stationManager: stationManager)
                

                let favorites: Array<Station>? = newFavoritesManager.findFavorites(stationName)
                
                expect(favorites).toNot(beNil())
                expect(favorites!.count == 1).to(beTrue())
                expect(favorites![0].name == stationName).to(beTruthy())
            }
            
        })
    }
}

