//
//  StationViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 7/27/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import LUX
import FunNet
import LithoOperators
import Prelude
import LUX
import FlexDataSource
import SubwayStations
import GTFSStations
import CoreGraphics
import Combine
import PlaygroundVCHelpers
import SwiftDate

func stationVC(for station: Station) -> StationViewController {
    let vc = StationViewController.makeFromXIB()
    let setStationName = set(\UIViewController.title, station.name)
    let setupStationVC: (UIViewController) -> Void = optionalCast >>> union(^\StationViewController.tableView >>> setupTableView,
                                                                            ^\StationViewController.actionButtonBottomConstraint >>> setupActionButtonPosition,
                                                                            ^\StationViewController.actionButton >?> setupCircleCappedView,
                                                                            station >||> configure(_:with:),
                                                                            station >||> setupBarButtons,
                                                                            initializeStationVC) >||> ifExecute
    vc.onViewDidLoad = union(setStationName, setupStationVC, setupEdges, set(\UIViewController.view.backgroundColor, .primaryDark()))
    vc.onOpenRoutes = { $0.pushAnimated(routesVC(station)) }
    vc.onActionPressed = { $0.pushAnimated(chooseVC($0, station)) }
    vc.onToggleFavoriteStation = station >||> toggleFavStation
    
    return vc
}

let initializeStationVC = { (stationVC: StationViewController) in
    stationVC.startLoading()
    stationVC.hideLineViews()
}

func setupBarButtons(_ stationVC: StationViewController, _ station: Station) {
    stationVC.navigationItem.rightBarButtonItems = [favoriteButton(stationVC, station), navButton(stationVC, station)]
}

func favoriteButton(_ stationVC: StationViewController, _ station: Station) -> UIBarButtonItem {
    let image = Current.favManager.isFavorite(station.name) ? UIImage(named: "star_white_24pt") : UIImage(named: "star_border_white_24pt")

    let favButton = UIButton()
    favButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
    favButton.setImage(image, for: .normal)
    favButton.addTarget(stationVC, action: #selector(StationViewController.toggleFavoriteStation), for: .touchUpInside)
    
    let buttonItem = UIBarButtonItem()
    buttonItem.customView = favButton
    return buttonItem
}

func navButton(_ stationVC: StationViewController, _ station: Station) -> UIBarButtonItem {
    let navButton = UIButton()
    navButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
    navButton.setImage(UIImage(named: "navigation_white_24pt"), for: .normal)
    navButton.addTarget(stationVC, action: #selector(StationViewController.openRoutes), for: .touchUpInside)
    
    let buttonItem = UIBarButtonItem()
    buttonItem.customView = navButton
    return buttonItem
}

func toggleFavStation(_ stationVC: StationViewController, _ station: Station) {
    Current.favManager.isFavorite(station.name) ? Current.favManager.removeFavorites([station]) : Current.favManager.addFavorites([station])
    setupBarButtons(stationVC, station)
}

func configure(_ vc: StationViewController, with station: Station) {
    let dbRefresher = DBPredictionRefresher(station)
    let predictionPub = dbRefresher.$predictions.skipNils().map { preds in preds.sorted(by: { $0.secondsToArrival < $1.secondsToArrival }) }.skipNils()
    
    let visitsCall = getVisitsCall()
    let visitsRefresher = LUXRefreshNetCallsManager(visitsCall)
    visitsCall.endpoint.addGetParams(params: filterParams(for: station))
    let visitsPub = unwrappedModelPublisher(from: visitsCall.publisher.$data.eraseToAnyPublisher(), ^\VisitsResponse.visits)
        .skipNils().map(station >|> calcVisitsStopsAway(from:_:))
    
    let estimatesCall = getEstimatesCall()
    let estimatesRefresher = LUXRefreshNetCallsManager(estimatesCall)
    estimatesCall.endpoint.addGetParams(params: estimateFilterParams(for: station))
    let estimatesPub = unwrappedModelPublisher(from: estimatesCall.publisher.$data.eraseToAnyPublisher(), ^\EstimatesResponse.estimates)
        .skipNils()
    
    let predictionVMPub = predictionPub.combineLatest(visitsPub, estimatesPub).map(models(from:visits:estimates:))
    let filteredPVMPub = predictionVMPub.combineLatest(vc.$chosenColor).map(~filter(predictions:by:))
    
    let itemsPub = filteredPVMPub.map(item(from:) >||> map)
    
    let refresher = LUXMetaRefresher(dbRefresher, visitsRefresher, estimatesRefresher)
    
    let vm = LUXItemsTableViewModel(refresher, itemsPublisher: itemsPub.eraseToAnyPublisher())
    vm.setupEndRefreshing(from: visitsCall)
    if let ds = vm.dataSource as? FlexDataSource {
        let delegate = LUXFunctionalTableDelegate()
        delegate.onSelect = ds.tappableOnSelect
        vm.tableDelegate = delegate
    }
    vm.tableView = vc.tableView
    vm.refresh()
    
    predictionVMPub.map(lines(from:)).sink { vc.lineModels = $0 }.store(in: &vc.cancelBag)
    
    itemsPub.sink { _ in
        vc.stopLoading()
    }.store(in: &vc.cancelBag)
}

func lines(from predictions: [PredictionViewModel]) -> [LineViewModel] {
    let routeIds = predictions.compactMap(\PredictionViewModel.routeId) |> Set.init |> [String].init
    return lines(from: routeIds)
}

class StationViewController: LUXFunctionalTableViewController, LineChoiceViewDelegate {
    @IBOutlet weak var lineChoice1: LineChoiceView?
    @IBOutlet weak var lineChoice2: LineChoiceView?
    @IBOutlet weak var lineChoice3: LineChoiceView?
    @IBOutlet weak var lineChoice4: LineChoiceView?
    @IBOutlet weak var loadingImageView: UIImageView?
    @IBOutlet weak var actionButton: UIButton?
    @IBOutlet weak var actionButtonBottomConstraint: NSLayoutConstraint?
    var lineViews = [LineChoiceView?]()
    var lineModels: [LineViewModel] = [LineViewModel]() { didSet { setLineViews() }}
    var cancelBag = Set<AnyCancellable>()
    
    var isLoading = false { didSet { toggleLoadingAnimations() }}
    @Published var chosenColor: UIColor?
    
    var onToggleFavoriteStation: ((StationViewController) -> Void)?
    var onOpenRoutes: ((StationViewController) -> Void)?
    var onActionPressed: ((StationViewController) -> Void)?

    @objc func toggleFavoriteStation() { onToggleFavoriteStation?(self) }
    @objc func openRoutes() { onOpenRoutes?(self) }
    @IBAction func actionButtonPressed() { onActionPressed?(self) }
    
    func startLoading() {
        if !isLoading {
            isLoading = true
        }
    }
    
    func stopLoading() {
        isLoading = false
    }
    
    func toggleLoadingAnimations() {
        if isLoading {
            spinLoadingImage(UIView.AnimationOptions.curveLinear)
        } else {
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                self.loadingImageView?.alpha = 0
            })
        }
    }
    
    func spinLoadingImage(_ animOptions: UIView.AnimationOptions) {
        self.loadingImageView?.alpha = 1
        UIView.animate(withDuration: 1.0, delay: 0.0, options: animOptions, animations: {
            if let imageView = self.loadingImageView {
                imageView.transform = imageView.transform.rotated(by: .pi)
            }
        }, completion: { finished in
                if finished {
                    if self.isLoading {
                        self.spinLoadingImage(UIView.AnimationOptions.curveLinear)
                    }else if animOptions != UIView.AnimationOptions.curveEaseOut{
                        self.spinLoadingImage(UIView.AnimationOptions.curveEaseOut)
                        self.stopLoading()
                    }
                }
        })
    }
    
    func setLineViews(){
        lineViews = [lineChoice1, lineChoice2, lineChoice3, lineChoice4]
        var count = 0
        while count < lineViews.count {
            if let lineView = lineViews[count] {
                if count < lineModels.count {
                    lineView.isHidden = false
                    lineView.lineLabel.text = lineModels[count].routesString()
                    let image = UIImage(named: "Grey")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
                    lineView.dotImageView.image = image
                    lineView.dotImageView.tintColor = lineModels[count].color
                } else {
                    lineView.isHidden = true
                }
                lineView.delegate = self
                lineView.updateConstraints()
                lineView.setNeedsLayout()
                lineView.layoutIfNeeded()
                count += 1
            }
        }
    }
    
    func hideLineViews() {
        lineViews = [lineChoice1, lineChoice2, lineChoice3, lineChoice4]
        for lineChoice in lineViews {
            lineChoice?.isHidden = true
        }
    }
    
    //MARK: line choice delegate
    
    func didSelectLineWithColor(_ color: UIColor) {
        for lineView in lineViews {
            if lineView?.dotImageView.tintColor != color {
                lineView?.isSelected = false
            }
        }
        
        chosenColor = color
    }
    
    func didDeselectLineWithColor(_ color: UIColor) { chosenColor = nil }
}

func filter(predictions: [PredictionViewModel], by color: UIColor?) -> [PredictionViewModel] {
    return predictions.filter { color == nil || Current.colorManager.colorForRouteId($0.routeId) == color }
}

func calcVisitsStopsAway(from station: Station, _ visits: [Visit]) -> [Visit] {
    for visit in visits {
        if visit.stopsAway == -1 {
            visit.stopsAway = Current.nycStationManager?.numberOfStopsBetween(station, visit.stationId!, visit.routeId!, Int64(visit.directionId!))
        }
    }
    return visits
}

func item(from model: PredictionViewModel) -> FlexDataSourceItem {
    return (model.estimates?.filter { $0.timeSeconds() > -1 }.count ?? 0) > 0 ? LUXModelItem(model, configureEstimateCell) : LUXModelItem(model, configurePredictionCell)
}

func models(from predictions: [Prediction], visits: [Visit], estimates: [Estimate]) -> [PredictionViewModel] {
    let uptown = predictions.filter { $0.direction == .uptown }
    let downtown = predictions.filter { $0.direction == .downtown }
    
    var predictionModels = [PredictionViewModel]()
    
    for prediction in uptown {
        let model = PredictionViewModel(routeId: prediction.route?.objectId, direction: prediction.direction!)
        if !predictionModels.contains(model) {
            model.setupWithPredictions(predictions)
            predictionModels.append(model)
        }
    }
    
    for prediction in downtown {
        let model = PredictionViewModel(routeId: prediction.route?.objectId, direction: prediction.direction!)
        if !predictionModels.contains(model) {
            model.setupWithPredictions(predictions)
            predictionModels.append(model)
        }
    }
    
    predictionModels.sort { $0.prediction.secondsToArrival < $1.prediction.secondsToArrival }
    
    for prediction in predictionModels {
        prediction.visits = visits.filter { $0.routeId == prediction.routeId && $0.directionId == prediction.direction.rawValue }
        prediction.estimates = estimates.filter  { $0.routeId == prediction.routeId && $0.directionId == prediction.direction.rawValue && $0.timeSeconds() > -1 }
    }
    
    return predictionModels
}

func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}
