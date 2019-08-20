//
//  PDFMapViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 4/4/18.
//  Copyright © 2018 Thryv. All rights reserved.
//

import UIKit
import PDFKit
import SubwayStations
import SBTextInputView
import MultiModelTableViewDataSource
import Prelude

class PDFMapViewController: StationSearchViewController, UITableViewDelegate {
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var loadingImageView: UIImageView!
    var loading = false
    var documentsDirectory: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    var isZoomedOut: Bool {
        get {
            return pdfView.scaleFactor <= pdfView.scaleFactorForSizeToFit
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = UIRectEdge()
        
        title = Bundle.main.infoDictionary!["AppTitle"] as? String
        navigationController?.navigationBar.barStyle = UIBarStyle.black
        
        let pdf = PDFDocument(url: URL(fileURLWithPath: Bundle.main.path(forResource: "subway", ofType:"pdf") ?? ""))
        pdfView.document = pdf
        pdfView.autoScales = true
        pdfView.maxScaleFactor = 3.0
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(PDFMapViewController.openStationAt))
        singleTap.numberOfTapsRequired = 1
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(PDFMapViewController.zoomIn))
        doubleTap.numberOfTapsRequired = 2
        
        if let recognizers = pdfView.gestureRecognizers {
            for recognizer in recognizers where recognizer is UILongPressGestureRecognizer {
                recognizer.isEnabled = false
            }
        }
        pdfView.documentView?.addGestureRecognizer(singleTap)
        pdfView.documentView?.addGestureRecognizer(doubleTap)
        
        setupFavoritesButton()
        
        tableView.delegate = self
        tableView.tableFooterView = UIView() //removes cell separators between empty cells
        tableView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 216, right: 0)
        
        if !DatabaseLoader.isDatabaseReady {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(MapViewController.databaseLoaded),
                                                   name: NSNotification.Name(rawValue: DatabaseLoader.NYCDatabaseLoadedNotification),
                                                   object: nil)
            searchBar?.alpha = 0
            startLoading()
        }else{
            databaseLoaded()
        }
    }
    
    @objc func zoomIn(_ recognizer: UITapGestureRecognizer) {
        let touch = recognizer.location(in: pdfView.documentView)
        pdfView.scaleFactor = isZoomedOut ? pdfView.maxScaleFactor : pdfView.scaleFactorForSizeToFit
        pdfView.go(to: CGRect(x: touch.x, y: (pdfView.documentView?.bounds.size.height ?? 0) - touch.y, width: 1, height: 1), on: pdfView.currentPage!)
    }
    
    @objc func openStationAt(_ recognizer: UITapGestureRecognizer) {
        if !isZoomedOut {
            let touch = recognizer.location(in: pdfView.documentView)
            
            let scaleFactor = 3.34296 as CGFloat
            
            let x = touch.x * scaleFactor
            let y = touch.y * scaleFactor
            
            if let id = PDFTouchConverter.fuzzyCoordToId(coord: (Int(x), Int(y)), fuzziness: Int(10 * scaleFactor)) {
                openStation(stationManager.allStations.filter { $0.stops.filter { $0.objectId == id }.count > 0 }.first)
            }
        }
    }
    
    func setupFavoritesButton() {
        let favButton = UIButton()
        favButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        favButton.setImage(UIImage(named: "STARgrey")?.withRenderingMode(.alwaysOriginal), for: UIControl.State())
        favButton.setImage(UIImage(named: "STARyellow")?.withRenderingMode(.alwaysOriginal), for: UIControl.State.selected.union(.highlighted))
        favButton.addTarget(self, action: #selector(PDFMapViewController.openFavorites), for: .touchUpInside)
        
        let favBarButton = UIBarButtonItem()
        favBarButton.customView = favButton
        self.navigationItem.rightBarButtonItem = favBarButton
    }
    
    @objc func openFavorites() {
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
            self.loadingImageView.transform = self.loadingImageView.transform.rotated(by: CGFloat(Double.pi))
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
    
    func openStation(_ station: Station?) {
        if let station = station {
            let barButton = UIBarButtonItem()
            barButton.title = ""
            navigationItem.backBarButtonItem = barButton
            
            let stationVC = StationViewController(nibName: "StationViewController", bundle: nil)
            stationVC.stationManager = stationManager
            stationVC.station = station
            navigationController?.pushViewController(stationVC, animated: true)
        }
    }
    
    //MARK: table delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let stationArray = stations {
            openStation(stationArray[indexPath.row])
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
