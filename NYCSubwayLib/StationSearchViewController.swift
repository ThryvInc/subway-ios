//
//  StationSearchViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 1/25/19.
//  Copyright © 2019 Thryv. All rights reserved.
//

import UIKit
import SubwayStations
import FlexDataSource
import Prelude
import LithoOperators
import LUX

public class StationSearchViewController: UIViewController, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar?
    var stations: [Station]?
    var dataSource = FlexDataSource()

    public override func viewDidLoad() {
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
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        tableView.isHidden = false
        if let stations = Current.stationManager.stationsForSearchString(searchText) {
            let stationToItem: (Station) -> FlexDataSourceItem = configureCellLines >||> LUXModelItem.init
            dataSource.sections = stations |> ((stationToItem >||> map) >>> (itemsToSection >>> arrayOfSingleObject))
            tableView.reloadData()
            self.stations = stations
        }
    }
    
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
    }

}
