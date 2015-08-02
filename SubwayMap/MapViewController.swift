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
    var stations: Array<Station>?
    var loading = false

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = UIRectEdge.None
        
        title = "SUBWAY:NYC"
        navigationController?.navigationBar.barStyle = UIBarStyle.Black
        
        searchBar.delegate = self
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        
        if !DatabaseLoader.isDatabaseReady {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "databaseLoaded", name: DatabaseLoader.NYCDatabaseLoadedNotification, object: nil)
            searchBar.alpha = 0
            startLoading()
        }else{
            databaseLoaded()
        }
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
            var barButton = UIBarButtonItem()
            barButton.title = ""
            navigationItem.backBarButtonItem = barButton
            
            let stationVC = StationViewController(nibName: "StationViewController", bundle: nil)
            stationVC.stationManager = stationManager
            stationVC.station = stationArray[indexPath.row]
            navigationController?.pushViewController(stationVC, animated: true)
        }
    }

}
