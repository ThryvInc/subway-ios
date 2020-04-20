//
//  RouteViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 4/21/18.
//  Copyright © 2018 Thryv. All rights reserved.
//

import UIKit
import FlexDataSource
import SubwayStations
import GTFSStations

class RouteViewController: UIViewController, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    let dataSource = FlexDataSource()
    var stationManager: NYCStationManager!
    var stations: [Station]!
    var trips: [Trip]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let routeIds = trips.map { $0.routeId }
        
        if let routeId = routeIds.first as? String, let route = stationManager.routeForRouteId(routeId) {
            let routeColorManager = NYCRouteColorManager()
            let items = stations.map { RouteItem(station: $0, route: route, colorManager: routeColorManager) }
            items.first?.position = .first
            items.last?.position = .last
            
            var routeIdIndex = 0
            for i in 1..<items.count {
                let item = items[i]
                let previous = items[i-1]
                if item.station.stops.map({ $0.objectId! }).sorted() == previous.station.stops.map({ $0.objectId! }).sorted() {
                    routeIdIndex += 1
                    item.isTransfer = true
                }
                if let route = stationManager.routes.filter({ $0.objectId == routeIds[routeIdIndex] }).first {
                    item.route = route
                }
            }
            
            let section = FlexDataSourceSection()
            section.items = items
            dataSource.sections = [section]
        }
        
        dataSource.tableView = tableView
        tableView.dataSource = dataSource
        tableView.delegate = self
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension StationManager {
    func routeForRouteId(_ routeId: String) -> Route? {
        return routes.filter { $0.objectId == routeId }.first
    }
}
