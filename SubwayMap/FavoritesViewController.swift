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
        
        tableView.registerNib(UINib(nibName: "StationTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        
        title = "FAVORITES"
        favManager = FavoritesManager(stationManager: stationManager)
        self.stations = favManager.favoriteStations()
        tableView.reloadData()
        tableView.tableFooterView = UIView()
    }
    
    func configureCellLines(cell: StationTableViewCell, station: Station){
        cell.stationNameLabel?.text = station.name
        for imageView in cell.orderedLineImageViews! {
            imageView.image = nil
        }
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
        let station = self.stations![indexPath.row]
        configureCellLines(cell, station: station)
        if let stationArray = stations {
            let station = stationArray[indexPath.row]
            configureCellLines(cell, station: station)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
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


