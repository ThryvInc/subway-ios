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
import FlexDataSource
import Prelude
import LithoOperators
import PlaygroundVCHelpers
import Combine

public func pdfMapVC() -> PDFMapViewController {
    let vc = PDFMapViewController.makeFromXIB()
    vc.onDatabaseLoaded = onDatabaseLoaded(vc:)
    return vc
}

func onDatabaseLoaded(vc: PDFMapViewController) {
    vc.loading = false
    vc.setupBarButtons()
    vc.setupStationTap()
    UIView.animate(withDuration: 0.5, animations: { () -> Void in
        vc.searchBar?.alpha = 1
        vc.loadingImageView.alpha = 0
    })
}

public class PDFMapViewController: StationSearchViewController, PDFMapper, UITableViewDelegate {
    @IBOutlet public weak var pdfView: PDFView!
    @IBOutlet weak var loadingImageView: UIImageView!
    @IBOutlet weak var buttonBottomConstaint: NSLayoutConstraint!
    
    var loading = false
    var onDatabaseLoaded: ((PDFMapViewController) -> Void)?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackgroundColor(view)
        setupBackgroundColor(pdfView)
        
        edgesForExtendedLayout = UIRectEdge()
        
        title = Bundle.main.infoDictionary!["AppTitle"] as? String
        navigationController?.navigationBar.barStyle = UIBarStyle.black
        
        let pdf = PDFDocument(url: URL(fileURLWithPath: Bundle(for: Self.self).path(forResource: "subway", ofType:"pdf") ?? ""))
        pdfView.document = pdf
        setupPdfMap()
        disableLongPresses()
        setupStationTap()
        pdfView.documentView?.addTapGestureRecognizer(numberOfTaps: 2, action: zoomIn)
        
        setupTableView(tableView)
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 216, right: 0)
        
        if !DatabaseLoader.isDatabaseReady {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(PDFMapViewController.databaseLoaded),
                                                   name: NSNotification.Name(rawValue: DatabaseLoader.NYCDatabaseLoadedNotification),
                                                   object: nil)
            searchBar?.alpha = 0
            startLoading()
        }else{
            databaseLoaded()
        }
        
        #if targetEnvironment(simulator)
        pdfView.documentView ?> Current.pdfTouchConverter.addStopDots(to:)
        #endif
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if Current.adsEnabled {
            buttonBottomConstaint.constant = 50
        } else {
            buttonBottomConstaint.constant = 0
        }
        view.updateConstraints()
    }
    
    func setupStationTap() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(PDFMapViewController.openStationAt))
        singleTap.numberOfTapsRequired = 1
        pdfView.documentView?.addGestureRecognizer(singleTap)
    }
    
    @objc func openStationAt(_ recognizer: UITapGestureRecognizer) {
        if !isZoomedOut {
            let touch = recognizer.location(in: pdfView.documentView)
            
            let vAdjustment = Current.pdfTouchConverter.verticalAdjustment
            let hAdjustment = Current.pdfTouchConverter.horizontalAdjustment
            let vScaleFactor = Current.pdfTouchConverter.verticalScaleFactor
            let hScaleFactor = Current.pdfTouchConverter.horizontalScaleFactor
            
            let x = touch.x * hScaleFactor / pdfView.documentView!.bounds.size.width - hAdjustment
            let y = touch.y * vScaleFactor / pdfView.documentView!.bounds.size.height - vAdjustment
            
            if let id = Current.pdfTouchConverter.fuzzyCoordToId(coord: (Int(x), Int(y)), fuzziness: Int(Current.pdfTouchConverter.fuzzyRadius)) {
                openStation(Current.stationManager.allStations.filter { $0.stops.filter { $0.objectId == id }.count > 0 }.first)
            }
        }
    }
    
    func setupBarButtons() {
        setupFavoritesButton()
        setupVisitsButton()
    }
    
    func setupVisitsButton() {
        let visitsButton = UIButton()
        visitsButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        visitsButton.setImage(UIImage(named: "eye_white")?.withRenderingMode(.alwaysOriginal), for: UIControl.State())
        visitsButton.addTarget(self, action: #selector(PDFMapViewController.openVisits), for: .touchUpInside)
        
        let visitsBarButton = UIBarButtonItem()
        visitsBarButton.customView = visitsButton
        if var items = self.navigationItem.rightBarButtonItems {
            items.append(visitsBarButton)
            self.navigationItem.rightBarButtonItems = items
        }
    }
    
    @objc func openVisits() {
        let barButton = UIBarButtonItem()
        barButton.title = ""
        navigationItem.backBarButtonItem = barButton
        
        let visitsVC = userReportsVC()
        navigationController?.pushViewController(visitsVC, animated: true)
    }
    
    func setupFavoritesButton() {
        let favButton = UIButton()
        favButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        favButton.setImage(UIImage(named: "star_white_24pt")?.withRenderingMode(.alwaysOriginal), for: UIControl.State())
        favButton.addTarget(self, action: #selector(PDFMapViewController.openFavorites), for: .touchUpInside)
        
        let favBarButton = UIBarButtonItem()
        favBarButton.customView = favButton
        self.navigationItem.rightBarButtonItems = [favBarButton]
    }
    
    @objc func openFavorites() {
        let barButton = UIBarButtonItem()
        barButton.title = ""
        navigationItem.backBarButtonItem = barButton
        
        let favoritesVC = FavoritesViewController.makeFromXIB()
        navigationController?.pushViewController(favoritesVC, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func databaseLoaded() {
        onDatabaseLoaded?(self)
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
            barButton.title = " "
            navigationItem.backBarButtonItem = barButton
            
            let vc = stationVC(for: station)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    //MARK: table delegate
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let stationArray = stations {
            openStation(stationArray[indexPath.row])
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
