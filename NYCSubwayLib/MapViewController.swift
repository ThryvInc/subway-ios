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
import FlexDataSource
import Prelude
import PlaygroundVCHelpers

class MapViewController: StationSearchViewController, UIScrollViewDelegate, UITableViewDelegate {
    @IBOutlet weak var subwayImageView: UIImageView!
    @IBOutlet weak var loadingImageView: UIImageView!
    var loading = false

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = UIRectEdge()
        
        title = Bundle.main.infoDictionary!["AppTitle"] as? String
        navigationController?.navigationBar.barStyle = UIBarStyle.black
        setupFavoritesButton()
        
        tableView.delegate = self
        tableView.tableFooterView = UIView() //removes cell separators between empty cells
        tableView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 216, right: 0)
        
        if !DatabaseLoader.isDatabaseReady {
            NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.databaseLoaded), name: NSNotification.Name(rawValue: DatabaseLoader.NYCDatabaseLoadedNotification), object: nil)
            searchBar?.alpha = 0
            startLoading()
        }else{
            databaseLoaded()
        }
    }
    
    func setupFavoritesButton() {
        let favButton = UIButton()
        favButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        favButton.setImage(UIImage(named: "STARgrey")?.withRenderingMode(.alwaysOriginal), for: UIControl.State())
        favButton.setImage(UIImage(named: "STARyellow")?.withRenderingMode(.alwaysOriginal), for: UIControl.State.selected.union(.highlighted))
        favButton.addTarget(self, action: #selector(MapViewController.openFavorites), for: .touchUpInside)
        
        let favBarButton = UIBarButtonItem()
        favBarButton.customView = favButton
        self.navigationItem.rightBarButtonItem = favBarButton
    }
    
    @objc func openFavorites() {
        let barButton = UIBarButtonItem()
        barButton.title = ""
        navigationItem.backBarButtonItem = barButton
        
        let favoritesVC = FavoritesViewController.makeFromXIB()
        favoritesVC.stationManager = stationManager
        navigationController?.pushViewController(favoritesVC, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func databaseLoaded() {
        stationManager = DatabaseLoader.stationManager
        
        loading = false
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.searchBar?.alpha = 1
            self.loadingImageView.alpha = 0
        })
    }
    
    func startLoading() {
        if !loading {
            loading = true
            spinLoadingImage(UIView.AnimationOptions.curveLinear)
        }
    }
    
    func spinLoadingImage(_ animOptions: UIView.AnimationOptions) {
        UIView.animate(withDuration: 1.5, delay: 0.0, options: animOptions, animations: {
            self.loadingImageView.transform = self.loadingImageView.transform.rotated(by: CGFloat(M_PI))
            return
            }, completion: { finished in
                if finished {
                    if self.loading {
                        self.spinLoadingImage(UIView.AnimationOptions.curveLinear)
                    }else if animOptions != UIView.AnimationOptions.curveEaseOut{
                        self.spinLoadingImage(UIView.AnimationOptions.curveEaseOut)
                    }
                }
        })
    }
    
    //MARK: scroll delegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return subwayImageView
    }
    
    //MARK: table delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let stationArray = stations {
            let barButton = UIBarButtonItem()
            barButton.title = ""
            navigationItem.backBarButtonItem = barButton
            
            let stationVC = StationViewController.makeFromXIB()
            stationVC.stationManager = stationManager
            stationVC.station = stationArray[indexPath.row]
            navigationController?.pushViewController(stationVC, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
