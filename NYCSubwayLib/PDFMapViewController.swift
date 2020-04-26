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
import PlaygroundVCHelpers
import Combine

public func pdfMapVC() -> PDFMapViewController {
    let vc = PDFMapViewController.makeFromXIB()
    vc.onDatabaseLoaded = onDatabaseLoaded(vc:)
    return vc
}

func onDatabaseLoaded(vc: PDFMapViewController) {
    vc.loading = false
    UIView.animate(withDuration: 0.5, animations: { () -> Void in
        vc.searchBar?.alpha = 1
        vc.loadingImageView.alpha = 0
    })
}

public class PDFMapViewController: StationSearchViewController, UITableViewDelegate {
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var loadingImageView: UIImageView!
    @IBOutlet weak var buttonBottomConstaint: NSLayoutConstraint!
    
    var dots = [UIView]()
    
    var loading = false
    var onDatabaseLoaded: ((PDFMapViewController) -> Void)?
    var documentsDirectory: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    var isZoomedOut: Bool {
        get {
            return pdfView.scaleFactor <= pdfView.scaleFactorForSizeToFit
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackgroundColor(view)
        setupBackgroundColor(pdfView)
        
        edgesForExtendedLayout = UIRectEdge()
        
        title = Bundle.main.infoDictionary!["AppTitle"] as? String
        navigationController?.navigationBar.barStyle = UIBarStyle.black
        
        let pdf = PDFDocument(url: URL(fileURLWithPath: Bundle(for: Self.self).path(forResource: "subway", ofType:"pdf") ?? ""))
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
        setupVisitsButton()
        
        tableView.delegate = self
        tableView.tableFooterView = UIView() //removes cell separators between empty cells
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
        addStopDots()
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
    
    @objc func zoomIn(_ recognizer: UITapGestureRecognizer) {
        let touch = recognizer.location(in: pdfView.documentView)
        pdfView.scaleFactor = isZoomedOut ? pdfView.maxScaleFactor : pdfView.scaleFactorForSizeToFit
        
        let scaledWindowWidth = pdfView.bounds.size.width * pdfView.scaleFactorForSizeToFit / 2
        let x = touch.x - scaledWindowWidth
        
        let scaledWindowHeight = pdfView.bounds.size.height * pdfView.scaleFactorForSizeToFit / 2
        let centeredY = touch.y - scaledWindowHeight
        let pdfYCoord = (pdfView.documentView?.bounds.size.height ?? 0) - centeredY
        
        pdfView.go(to: CGRect(x: x, y: pdfYCoord, width: 1, height: 1), on: pdfView.currentPage!)
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
    
    func addStopDots() {
        dots.forEach { $0.removeFromSuperview() }
        
        for coord in Current.pdfTouchConverter.coordToIdMap.keys {
            let x = pdfView.documentView!.bounds.size.width * (CGFloat(coord.values.0) + Current.pdfTouchConverter.horizontalAdjustment) / Current.pdfTouchConverter.horizontalScaleFactor
            let y = pdfView.documentView!.bounds.size.height * (CGFloat(coord.values.1) + Current.pdfTouchConverter.verticalAdjustment) / Current.pdfTouchConverter.verticalScaleFactor
            
            let dot = UIView(frame: CGRect(x: x, y: y, width: 1, height: 1))
            dot.backgroundColor = .red
            
            let radius: CGFloat = 30.0
            let frame = CGRect(x: Int(x) - Int(radius / 2),
                               y: Int(y) - Int(radius / 2), width: Int(radius), height: Int(radius))
            let tapZone = UILabel(frame: frame)
            tapZone.backgroundColor = UIColor.init(displayP3Red: 1.0, green: 0, blue: 0, alpha: 0.5)
            tapZone.layer.cornerRadius = tapZone.frame.size.height / 2
            tapZone.clipsToBounds = true
            tapZone.font = .systemFont(ofSize: 5)
            tapZone.text = Current.pdfTouchConverter.coordToIdMap[coord]
            tapZone.textAlignment = .center
            
            pdfView.documentView?.addSubview(tapZone)
            pdfView.documentView?.addConstraints(toSubview: tapZone, given: tapZone.frame)
            
            pdfView.documentView?.addSubview(dot)
            pdfView.documentView?.addConstraints(toSubview: dot, given: dot.frame)
            
            dots.append(dot)
            dots.append(tapZone)
        }
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

extension UIView {
    func addConstraints(toSubview view: UIView, given frame: CGRect) {
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: self.topAnchor, constant: frame.origin.y),
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: frame.origin.x)
        ])
        
        view.addConstraint(NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: frame.size.width))
        view.addConstraint(NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: frame.size.height))
    }
}
