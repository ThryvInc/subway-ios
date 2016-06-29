//
//  FavoritesViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 10/28/15.
//  Copyright © 2015 Thryv. All rights reserved.
//

import UIKit
import GTFSStations
import CoreGraphics

class FavoritesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var stationManager: StationManager!
    var favManager: FavoritesManager!
    var stations: [Station]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge.None
        
        title = "FAVORITES"
        favManager = FavoritesManager(stationManager: stationManager)
        stations = favManager.favoriteStations()
        
        tableView.registerNib(UINib(nibName: "StationTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        favManager = FavoritesManager(stationManager: stationManager)
        stations = favManager.favoriteStations()
        tableView.reloadData()
    }
    
    func configureCellLines(cell: StationTableViewCell, station: Station){
        cell.stationNameLabel?.text = station.name
        for imageView in cell.orderedLineImageViews! {
            imageView.image = nil
        }
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            let optionalLines = self.linesForStation(station)
            if let lines = optionalLines {
                dispatch_async(dispatch_get_main_queue()) {
                    for line in lines {
                        let image = UIImage(named: "Grey")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate);
                        if cell.firstLineImageView.image == nil {
                            cell.firstLineImageView.image = image
                            cell.firstLineImageView.tintColor = line.color
                        }else if cell.secondLineImageView.image == nil {
                            cell.secondLineImageView.image = image
                            cell.secondLineImageView.tintColor = line.color
                        }else if cell.thirdLineImageView.image == nil {
                            cell.thirdLineImageView.image = image
                            cell.thirdLineImageView.tintColor = line.color
                        }else if cell.fourthLineImageView.image == nil {
                            cell.fourthLineImageView.image = image
                            cell.fourthLineImageView.tintColor = line.color
                        }
                    }
                };
            }
        }
    }
    
    func linesForStation(station: Station) -> [LineViewModel]? {
        var lineModels = [LineViewModel]()
        do {
            let routeIds = try stationManager.routeIdsForStation(station)
            
            for routeId in routeIds {
                let lineModel = LineViewModel()
                lineModel.routeIds = [routeId]
                lineModel.color = NYCRouteColorManager.colorForRouteId(routeId)
                let lineIndex = lineModels.indexOf(lineModel)
                if let index = lineIndex {
                    if !lineModels[index].routeIds.contains(routeId) {
                        lineModels[index].routeIds.append(routeId)
                    }
                }else{
                    lineModels.append(lineModel)
                }
            }
        }catch{
            
        }
        return lineModels
    }
    
    //MARK: table data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stations!.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell")! as! StationTableViewCell
        if let stationArray = stations {
            let station = stationArray[indexPath.row]
            configureCellLines(cell, station: station)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let station = self.stations![indexPath.row]
        let barButton = UIBarButtonItem()
        barButton.title = ""
        navigationItem.backBarButtonItem = barButton
        
        let stationVC = StationViewController(nibName: "StationViewController", bundle: nil)
        stationVC.stationManager = stationManager
        stationVC.station = station
        navigationController?.pushViewController(stationVC, animated: true)
    }
}


