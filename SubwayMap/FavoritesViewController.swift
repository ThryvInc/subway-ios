//
//  FavoritesViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 10/28/15.
//  Copyright © 2015 Thryv. All rights reserved.
//

import UIKit
import SubwayStations
import CoreGraphics

class FavoritesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var stationManager: StationManager!
    var favManager: FavoritesManager!
    var stations: [Station]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge()
        
        title = "FAVORITES"
        favManager = FavoritesManager(stationManager: stationManager)
        stations = favManager.favoriteStations()
        
        tableView.register(UINib(nibName: "StationTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        favManager = FavoritesManager(stationManager: stationManager)
        stations = favManager.favoriteStations()
        tableView.reloadData()
    }
    
    func configureCellLines(_ cell: StationTableViewCell, station: Station){
        cell.stationNameLabel?.text = station.name
        for imageView in cell.orderedLineImageViews! {
            imageView.image = nil
        }
        let priority = DispatchQueue.GlobalQueuePriority.default
        DispatchQueue.global(priority: priority).async {
            let optionalLines = self.stationManager.linesForStation(station)
            if let lines = optionalLines {
                DispatchQueue.main.async {
                    for line in lines {
                        let image = UIImage(named: "Grey")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate);
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
    
    //MARK: table data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stations!.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as! StationTableViewCell
        if let stationArray = stations {
            let station = stationArray[indexPath.row]
            configureCellLines(cell, station: station)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
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


