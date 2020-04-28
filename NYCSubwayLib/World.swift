//
//  World.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 1/29/20.
//  Copyright © 2020 Thryv. All rights reserved.
//

import LUX
import SubwayStations
import GTFSStations

public var Current = paid

let free = World().configure {
    #if targetEnvironment(simulator)
    $0.isAdmin = true
    #else
    $0.isAdmin = false
    #endif
    $0.serverConfig = NYCServerConfiguration.production
    $0.adsEnabled = true
    LUXJsonProvider.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Seconds)
}

let paid = World().configure {
    #if targetEnvironment(simulator)
    $0.isAdmin = true
    #else
    $0.isAdmin = false
    #endif
    $0.serverConfig = NYCServerConfiguration.production
    $0.adsEnabled = false
    LUXJsonProvider.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Seconds)
}

let testing = World().configure {
    $0.serverConfig = NYCServerConfiguration.testing
    $0.adsEnabled = false
    $0.timeProvider = mockTime
    $0.uuidProvider = mockUuid
    LUXJsonProvider.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Seconds)
}

public struct World {
    public var isAdmin: Bool = false
    public var serverConfig = NYCServerConfiguration.production
    public var colorManager: RouteColorManager = NYCRouteColorManager()
    public var adsEnabled: Bool = false
    public var stationManager: StationManager!
    public var navManager: StationManager!
    public var favManager: FavoritesManager = FavoritesManager()
    public var directionProvider: DirectionProvider = NYCDirectionNameProvider()
    public var pdfTouchConverter: PDFTouchConverter = NYCPDFTouchConverter()
    public var timeProvider: () -> Date = currentTime
    public var uuidProvider: () -> String = fetchUuid
}
extension World: Configure {}
extension World {
    var nycStationManager: NYCStationManager? { get { self.navManager as? NYCStationManager }}
}

extension DateFormatter: Configure {}
