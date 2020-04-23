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
    vc.onViewDidLoad = { funcVC in
        if let stationVC = funcVC as? StationViewController {
            configure(stationVC, with: station)
            style(stationVC, with: station)
            setupTableView(stationVC.tableView)
            setupActionButtonPosition(stationVC.actionButtonBottomConstraint)
            setupBarButtons(stationVC, station)

            stationVC.startLoading()
            stationVC.hideLineViews()
        }
    }
    vc.onOpenRoutes = { $0.pushAnimated(routesVC(station)) }
    vc.onActionPressed = { $0.pushAnimated(chooseVC($0, station)) }
    vc.onToggleFavoriteStation = station >||> toggleFavStation
    
    return vc
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
    
    let itemsPub = filteredPVMPub.map((configurePredictionCell >||> LUXModelItem.init) >||> map).map { $0 as [FlexDataSourceItem] }
    
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
        prediction.estimates = estimates.filter  { $0.routeId == prediction.routeId && $0.directionId == prediction.direction.rawValue }
    }
    
    return predictionModels
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

func style(_ stationVC: StationViewController, with station: Station) {
    stationVC.title = station.name
    stationVC.view.backgroundColor = UIColor.primaryDark()
    stationVC.edgesForExtendedLayout = UIRectEdge()
    
    stationVC.actionButton ?> setupCircleCappedView
}

func lines(from predictions: [PredictionViewModel]) -> [LineViewModel] {
    let routeIds = predictions.compactMap(\PredictionViewModel.routeId) |> Set.init |> [String].init
    return lines(from: routeIds)
}

func setupTableView(_ tableView: UITableView?) {
    tableView?.rowHeight = UITableView.automaticDimension
    tableView?.tableFooterView = UIView()
}

func setupActionButtonPosition(_ actionButtonBottomConstraint: NSLayoutConstraint?) { actionButtonBottomConstraint?.constant = Current.adsEnabled ? 62 : 12 }

func setupBarButtons(_ stationVC: StationViewController, _ station: Station) {
    stationVC.navigationItem.rightBarButtonItems = [favoriteButton(stationVC, station), navButton(stationVC, station)]
}

func favoriteButton(_ stationVC: StationViewController, _ station: Station) -> UIBarButtonItem {
    let image = Current.favManager.isFavorite(station.name) ? UIImage(named: "star_white_24pt") : UIImage(named: "star_border_white_24pt")
    return UIBarButtonItem(image: image?.withRenderingMode(.alwaysOriginal), style: .plain, target: stationVC, action: #selector(StationViewController.toggleFavoriteStation))
}

func navButton(_ stationVC: StationViewController, _ station: Station) -> UIBarButtonItem {
    return UIBarButtonItem(image: UIImage(named: "navigation_white_24pt"), style: .plain, target: stationVC, action: #selector(StationViewController.openRoutes))
}

func toggleFavStation(_ stationVC: StationViewController, _ station: Station) {
    Current.favManager.isFavorite(station.name) ? Current.favManager.removeFavorites([station]) : Current.favManager.addFavorites([station])
    setupBarButtons(stationVC, station)
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

func configurePredictionCell(_ model: PredictionViewModel, _ cell: EstimateTableViewCell) {
    if let prediction = model.prediction {
        cell.deltaLabel.text = prediction.deltaString()
        if let route = prediction.route {
            cell.routeLabel.text = route.objectId
            cell.routeLabel.backgroundColor = Current.colorManager.colorForRouteId(route.objectId)
            cell.timeLabel.text = Current.directionProvider.directionName(for: prediction.direction!.rawValue, routeId: route.objectId)
            cell.routeImage.image = image(for: Current.directionProvider.directionEnum(for: prediction.direction!.rawValue, routeId: route.objectId))
        }
        cell.visitImageView.isHidden = true
        cell.visitLabel.isHidden = true
        if let visits = model.visits, visits.filter({ ($0.stopsAway ?? -1) > 0 }).count > 0 {
            let image = UIImage(named: "baseline_remove_red_eye_black_48")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            cell.visitImageView.image = image
            cell.visitImageView.tintColor = UIColor.accent()
            if let visit = visits.filter({ ($0.stopsAway ?? -1) > 0 && $0.timeAgoSeconds() > 0 }).first {
                cell.visitImageView.isHidden = false
                cell.visitLabel.isHidden = false
                let stopString = visit.stopsAway == 1 ? "stop" : "stops"
                let timeAgo: Int = visit.timeAgoSeconds()
                cell.visitLabel.text = "\(visit.stopsAway!) \(stopString) away as of \(timeAgo)m ago"
            }
        }
    }
    
    cell.contentView.updateConstraints();
}

func image(for direction: ImageDirection) -> UIImage? {
    switch direction {
    case .left: return UIImage(named: "ic_arrow_back_black_24dp")
    case .right: return UIImage(named: "ic_arrow_forward_black_24dp")
    case .up: return UIImage(named: "ic_arrow_upward_black_24dp")
    case .down: return UIImage(named: "ic_arrow_downward_black_24dp")
    }
}

extension Station {
    func stopIdsFilterString() -> String {
        return self.stops.map{ $0.objectId }.joined(separator: ",")
    }
}

extension Prediction {
    func deltaString() -> String? {
        if let arrivalTime = self.timeOfArrival {
            return "\((Int(arrivalTime.timeIntervalSince(Current.timeProvider()))) / 60)m"
        }
        return nil
    }
}

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}
