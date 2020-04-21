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
    $0.serverConfig = NYCServerConfiguration.production
    $0.adsEnabled = true
    LUXJsonProvider.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Seconds)
}

let paid = World().configure {
    $0.serverConfig = NYCServerConfiguration.production
    $0.adsEnabled = false
    LUXJsonProvider.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Seconds)
}

let testing = World().configure {
    $0.serverConfig = NYCServerConfiguration.testing
    $0.adsEnabled = false
    $0.timeProvider = mockTime
    LUXJsonProvider.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Seconds)
}

public struct World {
    public var serverConfig = NYCServerConfiguration.production
    public var colorManager: RouteColorManager = NYCRouteColorManager()
    public var adsEnabled: Bool = false
    public var timeProvider: () -> Date = currentTime
}
extension World: Configure {}

extension DateFormatter: Configure {}
