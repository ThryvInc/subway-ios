//
//  MapViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 7/29/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import UIKit
import GTFSStations
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

        edgesForExtendedLayout = UIRectEdge.None
        
        title = "SUBWAY:NYC"
        navigationController?.navigationBar.barStyle = UIBarStyle.Black
        setupFavoritesButton()
        searchBar.delegate = self
        
        tableView.registerNib(UINib(nibName: "StationTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView() //removes cell separators between empty cells
        
        if !DatabaseLoader.isDatabaseReady {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MapViewController.databaseLoaded), name: DatabaseLoader.NYCDatabaseLoadedNotification, object: nil)
            searchBar.alpha = 0
            startLoading()
        }else{
            databaseLoaded()
        }
    }
    
    func setupFavoritesButton() {
        let favButton = UIButton()
        favButton.frame = CGRectMake(0, 0, 30, 30)
        favButton.setImage(UIImage(named: "Hover")?.imageWithRenderingMode(.AlwaysOriginal), forState: .Normal)
        favButton.setImage(UIImage(named: "Pressed")?.imageWithRenderingMode(.AlwaysOriginal), forState: UIControlState.Selected.union(.Highlighted))
        favButton.addTarget(self, action: #selector(MapViewController.openFavorites), forControlEvents: .TouchUpInside)
        
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
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func databaseLoaded() {
        stationManager = DatabaseLoader.stationManager
        
        loading = false
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.searchBar.alpha = 1
            self.loadingImageView.alpha = 0
        })
    }
    
    func startLoading() {
        if !loading {
            loading = true
            spinLoadingImage(UIViewAnimationOptions.CurveLinear)
        }
    }
    
    func spinLoadingImage(animOptions: UIViewAnimationOptions) {
        UIView.animateWithDuration(1.5, delay: 0.0, options: animOptions, animations: {
            self.loadingImageView.transform = CGAffineTransformRotate(self.loadingImageView.transform, CGFloat(M_PI))
            return
            }, completion: { finished in
                if finished {
                    if self.loading {
                        self.spinLoadingImage(UIViewAnimationOptions.CurveLinear)
                    }else if animOptions != UIViewAnimationOptions.CurveEaseOut{
                        self.spinLoadingImage(UIViewAnimationOptions.CurveEaseOut)
                    }
                }
        })
    }
    
    func dismissKeyboard() {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        searchBar.setShowsCancelButton(false, animated: true)
        tableView.hidden = true
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
                        let image = UIImage(named: "dot")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate);
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
    
    //MARK: scroll delegate
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return subwayImageView
    }
    
    //MARK: search bar delegate
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        tableView.hidden = false
        stations = stationManager.stationsForSearchString(searchText)
        tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        dismissKeyboard()
    }
    
    //MARK: table data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (stations ?? [Station]()).count
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
        if let stationArray = stations {
            let barButton = UIBarButtonItem()
            barButton.title = ""
            navigationItem.backBarButtonItem = barButton
            
            let stationVC = StationViewController(nibName: "StationViewController", bundle: nil)
            stationVC.stationManager = stationManager
            stationVC.station = stationArray[indexPath.row]
            navigationController?.pushViewController(stationVC, animated: true)
        }
    }
}
