//
//  Visit.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 6/17/18.
//  Copyright © 2018 Thryv. All rights reserved.
//

import UIKit

class Visit: NSObject, Codable {
    var stationId: String?
    var routeId: String?
    var directionId: Int? = 2
    var latitude: Double?
    var longitude: Double?
    var isAuto: Bool? = false
    var platform: String? = "ios"
    var time: String? = DateFormatter.iso8601Seconds.string(from: Date().addingTimeInterval(TimeInterval(TimeZone.current.secondsFromGMT())))
    var uuidIdentifier: String? = UuidProvider.fetch()
    var numberOfStopsBetween: Int64? = -1
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case uuidIdentifier = "identifier"
        case routeId = "route_id"
        case isAuto = "is_auto"
        case platform
        case directionId = "direction_id"
        case longitude
        case time
        case stationId = "station_id"
    }
}

extension Visit {
    func timeAgoDate() -> Date {
        return DateFormatter.iso8601Full.date(from: time!)!.addingTimeInterval(TimeInterval(-TimeZone.current.secondsFromGMT()))
    }
    
    func timeAgoSeconds() -> Int {
        return Int((Date().timeIntervalSince1970 - timeAgoDate().timeIntervalSince1970) / 60)
    }
}

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    static let iso8601Seconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
