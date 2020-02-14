//
//  World.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 1/29/20.
//  Copyright © 2020 Thryv. All rights reserved.
//

import LUX

public var Current = World().configure { _ in
    LUXJsonProvider.jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Seconds)
}

public struct World {
    public var serverConfig = NYCServerConfiguration.current
}
extension World: Configure {}

extension DateFormatter: Configure {}
