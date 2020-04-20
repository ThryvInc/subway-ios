//
//  RoutesViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 4/21/18.
//  Copyright © 2018 Thryv. All rights reserved.
//

import UIKit
import SubwayStations
import GTFSStations
import PlaygroundVCHelpers

class RoutesViewController: StationSearchViewController, UITableViewDelegate {
    @IBOutlet weak var fromSearchBar: UISearchBar!
    @IBOutlet weak var toSearchBar: UISearchBar!
    @IBOutlet weak var tableTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var goButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var fromStation: Station?
    var toStation: Station?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Navigate to"
        
        spinner.alpha = 0
        
        goButton.layer.cornerRadius = goButton.bounds.height / 2
        goButton.clipsToBounds = true
        
        fromSearchBar.text = fromStation?.name
        
        fromSearchBar.delegate = self
        toSearchBar.delegate = self
        
        tableView.delegate = self
        tableView.tableFooterView = UIView() //removes cell separators between empty cells
    }
    
    //MARK: search delegate
    
    override func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        self.searchBar = searchBar
        tableView.isHidden = false
    }
    
    override func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
        if searchBar == fromSearchBar {
            fromStation = nil
        }
        if searchBar == toSearchBar {
            toStation = nil
        }
    }
    
    @IBAction func goPressed() {
        let nav: NYCNavigator = NYCNavigator()
        nav.transferStations = (stationManager as! NYCStationManager).transferStations
        
        goButtonWidthConstraint.constant = goButton.bounds.height
        UIView.animate(withDuration: 0.5) {
            self.spinner.alpha = 1
            self.goButton.setTitle("", for: .normal)
            self.view.updateConstraints()
            self.view.layoutIfNeeded()
        }
        DispatchQueue.global(qos: .default).async(execute: {
            if let first = self.fromStation, let second = self.toStation {
                let (stations, trips) = nav.getStationsAndTripsBetween(first, second, nil)
                DispatchQueue.main.async {
                    self.goButtonWidthConstraint.constant = 63
                    UIView.animate(withDuration: 0.5) {
                        self.spinner.alpha = 0
                        self.goButton.setTitle("Go!", for: .normal)
                        self.view.updateConstraints()
                        self.view.layoutIfNeeded()
                    }
                    self.gotoRoute(stations, trips)
                }
            }
        })
    }
    
    func gotoRoute(_ stations: [Station], _ trips: [Trip]) {
        let routeVC = RouteViewController.makeFromXIB()
        routeVC.stationManager = stationManager as! NYCStationManager
        routeVC.stations = stations
        routeVC.trips = trips
        navigationController?.pushViewController(routeVC, animated: true)
    }
    
    //MARK: table delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let station = stations?[indexPath.row] {
            searchBar?.text = station.name
            if searchBar == fromSearchBar {
                fromStation = station
                toSearchBar.becomeFirstResponder()
                searchBar = toSearchBar
            }
            if searchBar == toSearchBar {
                toStation = station
                toSearchBar.resignFirstResponder()
                tableView.isHidden = true
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
