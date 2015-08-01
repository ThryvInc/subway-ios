//
//  Prediction.swift
//  GTFS Stations
//
//  Created by Elliot Schrock on 6/10/15.
//  Copyright (c) 2015 Elliot Schrock. All rights reserved.
//

import UIKit

public enum Direction: Int {
    case Uptown = 0
    case Downtown = 1
}

public class Prediction: NSObject, Equatable {
    public var secondsToArrival: Int? {
        if let arrival = timeOfArrival {
            return Int(arrival.timeIntervalSinceNow)
        }else{
            return nil
        }
    }
    public var timeOfArrival: NSDate?
    public var direction: Direction?
    public var route: Route?
    
    init(time: NSDate?) {
        super.init()
        timeOfArrival = time
    }
}
public func ==(lhs: Prediction, rhs: Prediction) -> Bool {
    return lhs.route?.objectId == rhs.route?.objectId && lhs.timeOfArrival == rhs.timeOfArrival && lhs.direction == rhs.direction
}
