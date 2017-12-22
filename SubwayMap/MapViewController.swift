//
//  MapViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 7/29/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import UIKit
import SubwayStations
import SBTextInputView

class MapViewController: UIViewController, UIScrollViewDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var subwayImageView: UIImageView!
    @IBOutlet weak var loadingImageView: UIImageView!
    var stationManager: StationManager!
    var stations: [Station]?
    var loading = false

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = UIRectEdge()
        
        title = Bundle.main.infoDictionary!["AppTitle"] as? String
        navigationController?.navigationBar.barStyle = UIBarStyle.black
        setupFavoritesButton()
        searchBar.delegate = self
        
        tableView.register(UINib(nibName: "StationTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView() //removes cell separators between empty cells
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 216, 0)
        
        if !DatabaseLoader.isDatabaseReady {
            NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.databaseLoaded), name: NSNotification.Name(rawValue: DatabaseLoader.NYCDatabaseLoadedNotification), object: nil)
            searchBar.alpha = 0
            startLoading()
        }else{
            databaseLoaded()
        }
    }
    
    func setupFavoritesButton() {
        let favButton = UIButton()
        favButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        favButton.setImage(UIImage(named: "STARgrey")?.withRenderingMode(.alwaysOriginal), for: UIControlState())
        favButton.setImage(UIImage(named: "STARyellow")?.withRenderingMode(.alwaysOriginal), for: UIControlState.selected.union(.highlighted))
        favButton.addTarget(self, action: #selector(MapViewController.openFavorites), for: .touchUpInside)
        
        let favBarButton = UIBarButtonItem()
        favBarButton.customView = favButton
        self.navigationItem.rightBarButtonItem = favBarButton
    }
    
    func openFavorites() {
        let barButton = UIBarButtonItem()
        barButton.title = ""
        navigationItem.backBarButtonItem = barButton
        
        let favoritesVC = FavoritesViewController(nibName: "FavoritesViewController", bundle: nil)
        favoritesVC.stationManager = stationManager
        navigationController?.pushViewController(favoritesVC, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func databaseLoaded() {
        stationManager = DatabaseLoader.stationManager
        
        loading = false
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.searchBar.alpha = 1
            self.loadingImageView.alpha = 0
        })
    }
    
    func startLoading() {
        if !loading {
            loading = true
            spinLoadingImage(UIViewAnimationOptions.curveLinear)
        }
    }
    
    func spinLoadingImage(_ animOptions: UIViewAnimationOptions) {
        UIView.animate(withDuration: 1.5, delay: 0.0, options: animOptions, animations: {
            self.loadingImageView.transform = self.loadingImageView.transform.rotated(by: CGFloat(M_PI))
            return
            }, completion: { finished in
                if finished {
                    if self.loading {
                        self.spinLoadingImage(UIViewAnimationOptions.curveLinear)
                    }else if animOptions != UIViewAnimationOptions.curveEaseOut{
                        self.spinLoadingImage(UIViewAnimationOptions.curveEaseOut)
                    }
                }
        })
    }
    
    func dismissKeyboard() {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        searchBar.setShowsCancelButton(false, animated: true)
        tableView.isHidden = true
    }
    
    func configureCellLines(_ cell: StationTableViewCell, station: Station){
        cell.stationNameLabel?.text = station.name
        for imageView in cell.orderedLineImageViews! {
            imageView.image = nil
        }
        if let shouldShowLines = Bundle.main.infoDictionary!["ShowLines"] as? Bool {
            if shouldShowLines {
                let priority = DispatchQueue.GlobalQueuePriority.default
                DispatchQueue.global(priority: priority).async {
                    let optionalLines = self.stationManager.linesForStation(station)
                    if let lines = optionalLines {
                        DispatchQueue.main.async {
                            cell.firstLineImageView.image = nil
                            cell.secondLineImageView.image = nil
                            cell.thirdLineImageView.image = nil
                            cell.fourthLineImageView.image = nil
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
                };
            }
        }
    }
    
    //MARK: scroll delegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return subwayImageView
    }
    
    //MARK: search bar delegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        tableView.isHidden = false
        stations = stationManager.stationsForSearchString(searchText)
        tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
    }
    
    //MARK: table data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (stations ?? [Station]()).count
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
        if let stationArray = stations {
            let barButton = UIBarButtonItem()
            barButton.title = ""
            navigationItem.backBarButtonItem = barButton
            
            let stationVC = StationViewController(nibName: "StationViewController", bundle: nil)
            stationVC.stationManager = stationManager
            stationVC.station = stationArray[indexPath.row]
            navigationController?.pushViewController(stationVC, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
