//
//  StationSearchViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 1/25/19.
//  Copyright © 2019 Thryv. All rights reserved.
//

import UIKit
import SubwayStations
import MultiModelTableViewDataSource
import Prelude

class StationSearchViewController: UIViewController, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar?
    var stationManager: StationManager!
    var stations: [Station]?
    var dataSource = MultiModelTableViewDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar?.delegate = self
        
        dataSource.tableView = tableView
        tableView.dataSource = dataSource
    }
    
    func dismissKeyboard() {
        searchBar?.resignFirstResponder()
        searchBar?.text = ""
        searchBar?.setShowsCancelButton(false, animated: true)
        tableView.isHidden = true
    }
    
    //MARK: search bar delegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        tableView.isHidden = false
        if let stations = stationManager.stationsForSearchString(searchText) {
            let stationToItem: (Station) -> StationItem = stationManager >||> StationItem.item
            dataSource.sections = stations |> ((stationToItem >||> map) >>> (MultiModelTableViewDataSourceSection.itemsToSection >>> arrayOfSingleObject))
            tableView.reloadData()
            self.stations = stations
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
    }

}
