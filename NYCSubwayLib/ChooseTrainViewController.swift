//
//  ChooseTrainViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 6/14/18.
//  Copyright © 2018 Thryv. All rights reserved.
//

import UIKit
import SubwayStations
import GTFSStations
import PlaygroundVCHelpers

class ChooseTrainViewController: UIViewController, UICollectionViewDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    var routesDataSource = RouteCollectionViewDataSource()
    var callingViewController: UIViewController?
    var station: Station!
    var stationManager: StationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "You spotted a train!"
        
        let routeIds = stationManager.routeIdsForStation(station)
        routesDataSource.routeIds = routeIds

        collectionView.register(UINib(nibName: "RouteCollectionViewCell", bundle: Bundle(for: Self.self)), forCellWithReuseIdentifier: "routeCell")
        collectionView.dataSource = routesDataSource
        collectionView.delegate = self
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let routeId = routesDataSource.routeIds![indexPath.row]
        let directionVC = ChooseDirectionViewController.makeFromXIB()
        directionVC.routeId = routeId
        directionVC.callingViewController = callingViewController
        directionVC.station = station
        directionVC.stationManager = stationManager
        navigationController?.pushViewController(directionVC, animated: true)
    }
}
