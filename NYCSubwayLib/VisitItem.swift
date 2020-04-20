//
//  VisitItem.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 1/30/20.
//  Copyright © 2020 Thryv. All rights reserved.
//

import FlexDataSource
import SubwayStations
import LithoOperators
import LUX

class VisitItem: SwipableItem<VisitTableViewCell> {
    let visit: Visit
    
    init(_ visit: Visit, _ stationManager: StationManager, _ onSwipe: @escaping () -> Void) {
        self.visit = visit
        super.init(identifier: "visitCell", visit >||> (stationManager >|||> VisitItem.configureCell(_:_:_:)), onSwipe)
    }

    static func configureCell(_ cell: UITableViewCell, _ visit: Visit, _ stationManager: StationManager) {
        if let cell = cell as? VisitTableViewCell {
            configureVisit(cell, visit, stationManager)
        }
    }
    
    static func configureVisit(_ cell: VisitTableViewCell, _ visit: Visit, _ stationManager: StationManager) {
        if false == visit.isAuto {
            configureManual(cell, visit, stationManager)
        } else {
            configureAuto(cell, visit, stationManager)
        }
    }
    
    static func configureAuto(_ cell: VisitTableViewCell, _ visit: Visit, _ stationManager: StationManager) {
        
    }
    
    static func configureManual(_ cell: VisitTableViewCell, _ visit: Visit, _ stationManager: StationManager) {
        cell.routeLabel.layer.cornerRadius = 18
        cell.routeLabel.clipsToBounds = true
        if let routeId = visit.routeId {
            cell.routeLabel.text = routeId
            cell.routeLabel.backgroundColor = Current.colorManager.colorForRouteId(routeId)
            if let direction = visit.directionId {
                let directionEnum = NYCDirectionNameProvider.directionEnum(for: direction, routeId: routeId)
                switch directionEnum {
                case .left:
                    cell.routeImage.image = UIImage(named: "ic_arrow_back_black_24dp")
                    break
                case .right:
                    cell.routeImage.image = UIImage(named: "ic_arrow_forward_black_24dp")
                    break
                case .up:
                    cell.routeImage.image = UIImage(named: "ic_arrow_upward_black_24dp")
                    break
                case .down:
                    cell.routeImage.image = UIImage(named: "ic_arrow_downward_black_24dp")
                    break
                }
            }
        }
        if let stationId = visit.stationId {
            let stationName = stationManager.allStations.first { $0.stops.filter { $0.objectId == stationId }.count > 0 }?.name
            cell.stationLabel.text = stationName
        }
        cell.timeLabel.text = visit.time
        if let timeString = visit.time, let initDate = DateFormatter.iso8601Seconds.date(from: timeString) {
            let date = initDate.addingTimeInterval(TimeInterval(-TimeZone.current.secondsFromGMT()))
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d @ h:mm a"
            cell.timeLabel.text = formatter.string(from: date)
        }
        if let identifier = visit.identifier {
            var index = identifier.addedUp()
            if index < 0 { index = -index }
            index = index % allEmojis.count
            cell.emojiLabel.text = allEmojis[index]
        }
    }
}