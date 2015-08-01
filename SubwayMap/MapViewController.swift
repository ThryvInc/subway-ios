//
//  MapViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 7/29/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import UIKit
import GTFSStations

class MapViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    var stationManager: StationManager!
    var stations: Array<Station>?

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = UIRectEdge.None
        
        searchBar.delegate = self
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        stations = stationManager.stationsForSearchString(searchText)
        tableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (stations ?? Array<Station>()).count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell") as! UITableViewCell
        if let stationArray = stations {
            cell.textLabel?.text = stationArray[indexPath.row].name
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let stationArray = stations {
            let stationVC = StationViewController(nibName: "StationViewController", bundle: nil)
            stationVC.stationManager = stationManager
            stationVC.station = stationArray[indexPath.row]
            navigationController?.pushViewController(stationVC, animated: true)
        }
    }

}
