//
//  StationViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 7/27/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import LUX
import LithoOperators
import SubwayStations
import GTFSStations
import CoreGraphics
import Combine

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
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

class StationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, LineChoiceViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lineChoice1: LineChoiceView!
    @IBOutlet weak var lineChoice2: LineChoiceView!
    @IBOutlet weak var lineChoice3: LineChoiceView!
    @IBOutlet weak var lineChoice4: LineChoiceView!
    @IBOutlet weak var loadingImageView: UIImageView!
    @IBOutlet weak var actionButton: UIButton!
    var station: Station!
    var stationManager: StationManager!
    var nycStationManager: NYCStationManager? {
        get {
            return DatabaseLoader.navManager as? NYCStationManager
        }
    }
    var predictions: [Prediction]?
    var predictionModels: [PredictionViewModel]? {
        didSet {
            if let predictions = predictionModels {
                for prediction in predictions {
                    prediction.visits = visits?.filter { $0.routeId == prediction.routeId && $0.directionId == prediction.direction.rawValue }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    var filteredPredictionModels: [PredictionViewModel]?
    var routes: [Route] = [Route]()
    var lineModels: [LineViewModel] = [LineViewModel]()
    var lineViews = [LineChoiceView]()
    var favManager: FavoritesManager!
    var loading = false
    var visitsCall: CombineNetCall?
    var visits: [Visit]? {
        didSet {
            if let visits = visits {
                for visit in visits {
                    visit.numberOfStopsBetween = nycStationManager?.numberOfStopsBetween(station, visit.stationId!, visit.routeId!, Int64(visit.directionId!))
                }
            }
            if let predictions = predictionModels {
                for prediction in predictions {
                    prediction.visits = visits?.filter { $0.routeId == prediction.routeId && $0.directionId == prediction.direction.rawValue }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    private var cancelBag = Set<AnyCancellable?>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let routeIds = nycStationManager?.routeIdsForStation(station)
        let filters = "current_station_ids=\(station.stops.map{ $0.objectId }.joined(separator: ","))&route_ids=\(routeIds!.joined(separator: ","))&after=\(DateFormatter.iso8601Full.string(from: Calendar.current.date(byAdding: .minute, value: -5, to: Date())!.addingTimeInterval(TimeInterval(TimeZone.current.secondsFromGMT()))))"
        visitsCall = getVisitsCall(filters: filters)
        let visitsPub: AnyPublisher<[Visit], Never>? = unwrappedModelPublisher(from: visitsCall?.responder?.$data.eraseToAnyPublisher(), ^\VisitsResponse.visits)
        cancelBag.insert(visitsPub?.sink { (visits) in
            self.visits = visits
        })
//        visitsCall?.visitsSignal.observeValues { visits in
//            self.visits = visits
//        }
        visitsCall?.fire()
        
        view.backgroundColor = UIColor.primaryDark()
        
        self.edgesForExtendedLayout = UIRectEdge()
        
        tableView.register(UINib(nibName: "PredictionTableViewCell", bundle: nil), forCellReuseIdentifier: "predCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView() //removes cell separators between empty cells
        
        actionButton.layer.cornerRadius = actionButton.bounds.size.width / 2
        
        title = station.name
        favManager = FavoritesManager(stationManager: stationManager)
        
        setupBarButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        refresh()
    }
    
    func setupBarButtons() {
        let items = [favoriteButton(), navButton()]
        navigationItem.rightBarButtonItems = items
    }
    
    func favoriteButton() -> UIBarButtonItem {
        let favButton = UIButton()
        favButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        if favManager.isFavorite(station.name){
            favButton.setImage(UIImage(named: "STARyellow")?.withRenderingMode(.alwaysOriginal), for: UIControl.State())
        } else {
            favButton.setImage(UIImage(named: "STARgrey")?.withRenderingMode(.alwaysOriginal), for: UIControl.State())
        }
        
        favButton.addTarget(self, action: #selector(StationViewController.toggleFavoriteStation), for: .touchUpInside)
        
        let favBarButton = UIBarButtonItem()
        favBarButton.customView = favButton
        
        return favBarButton
    }
    
    func navButton() -> UIBarButtonItem {
        return UIBarButtonItem(image: UIImage(named: "ic_navigation_white_24dp"), style: .plain, target: self, action: #selector(StationViewController.openRoutes))
    }

    @objc func toggleFavoriteStation() {
        if favManager.isFavorite(station.name) {
            favManager.removeFavorites([self.station])
        } else {
            favManager.addFavorites([station])
        }
        setupBarButtons()
    }
    
    @objc func openRoutes() {
        let routesVC = RoutesViewController(nibName: "RoutesViewController", bundle: Bundle.main)
        routesVC.stationManager = stationManager
        routesVC.fromStation = station
        navigationController?.pushViewController(routesVC, animated: true)
    }

    @IBAction func favoriteThisStation() {
        favManager.addFavorites([station])
        setupBarButtons()
    }
    
    @IBAction func actionButtonPressed() {
        let chooseVC = ChooseTrainViewController(nibName: "ChooseTrainViewController", bundle: Bundle.main)
        chooseVC.callingViewController = self
        chooseVC.station = station
        chooseVC.stationManager = stationManager
        navigationController?.pushViewController(chooseVC, animated: true)
    }
    
    func startLoading() {
        if !loading {
            loading = true
            spinLoadingImage(UIView.AnimationOptions.curveLinear)
        }
    }
    
    func stopLoading() {
        loading = false
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.loadingImageView.alpha = 0
        })
    }
    
    func spinLoadingImage(_ animOptions: UIView.AnimationOptions) {
        self.loadingImageView.alpha = 1
        UIView.animate(withDuration: 1.0, delay: 0.0, options: animOptions, animations: {
            self.loadingImageView.transform = self.loadingImageView.transform.rotated(by: .pi)
            return
            }, completion: { finished in
                if finished {
                    if self.loading {
                        self.spinLoadingImage(UIView.AnimationOptions.curveLinear)
                    }else if animOptions != UIView.AnimationOptions.curveEaseOut{
                        self.spinLoadingImage(UIView.AnimationOptions.curveEaseOut)
                        self.stopLoading()
                    }
                }
        })
    }
    
    func refresh() {
        startLoading()
        hideLineViews()
        DispatchQueue.global( priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { () -> Void in
            self.refreshSynchronous()
            DispatchQueue.main.async(execute: { () -> Void in
                self.stopLoading()
                self.setLines()
                self.tableView.reloadData()
            })
        })
    }
    
    func refreshSynchronous() {
        predictions = stationManager.predictions(station, time: Date())//timeIntervalSince1970: 1438215977))
        predictions!.sort(by: { $0.secondsToArrival < $1.secondsToArrival })
        
        let uptown = predictions!.filter({ (prediction) -> Bool in
            return prediction.direction == .uptown
        })
        let downtown = predictions!.filter({ (prediction) -> Bool in
            return prediction.direction == .downtown
        })
        
        predictionModels = [PredictionViewModel]()
        
        for prediction in uptown {
            let model = PredictionViewModel(routeId: prediction.route?.objectId, direction: prediction.direction!)
            if !predictionModels!.contains(model) {
                model.setupWithPredictions(predictions)
                predictionModels?.append(model)
            }
        }
        
        for prediction in downtown {
            let model = PredictionViewModel(routeId: prediction.route?.objectId, direction: prediction.direction!)
            if !predictionModels!.contains(model) {
                model.setupWithPredictions(predictions)
                predictionModels?.append(model)
            }
        }
        
        predictionModels?.sort {$0.prediction.secondsToArrival < $1.prediction.secondsToArrival}
        
        filteredPredictionModels = predictionModels
    }
    
    func setLines() {
        lineModels = stationManager.linesForStation(station)!
        setLineViews()
    }
    
    func setLineViews(){
        lineViews = [lineChoice1, lineChoice2, lineChoice3, lineChoice4]
        var count = 0
        while count < lineViews.count {
            let lineView = lineViews[count]
            if count < lineModels.count {
                lineView.isHidden = false
                lineView.lineLabel.text = lineModels[count].routesString()
                let image = UIImage(named: "Grey")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
                lineView.dotImageView.image = image
                lineView.dotImageView.tintColor = lineModels[count].color
            }else{
                lineView.isHidden = true
            }
            lineView.delegate = self
            lineView.updateConstraints()
            lineView.setNeedsLayout()
            lineView.layoutIfNeeded()
            count += 1
        }
    }
    
    func hideLineViews() {
        lineViews = [lineChoice1, lineChoice2, lineChoice3, lineChoice4]
        for lineChoice in lineViews {
            lineChoice.isHidden = true
        }
    }
    
    func configurePredictionCell(_ cell: PredictionTableViewCell, indexPath: IndexPath) {
        let model = filteredPredictionModels![indexPath.row]
        if let prediction = model.prediction {
            cell.deltaLabel.text = "\((prediction.secondsToArrival!) / 60)m"
            if let route = prediction.route {
                cell.routeLabel.text = route.objectId
                cell.routeLabel.backgroundColor = AppDelegate.colorManager().colorForRouteId(route.objectId)
                cell.timeLabel.text = NYCDirectionNameProvider.directionName(for: prediction.direction!.rawValue, routeId: route.objectId)
                let directionEnum = NYCDirectionNameProvider.directionEnum(for: prediction.direction!.rawValue, routeId: route.objectId)
                switch directionEnum {
                case .left:
                    cell.routeImage.image = UIImage(named: "ic_arrow_back_black_24dp")
                    break
                case .right:
                    cell.routeImage.image = UIImage(named: "ic_arrow_forward_black_24dp")
                    break
                case .up:
                    cell.routeImage.image = UIImage(named: "ic_arrow_upward_black_24dp")
                    break
                case .down:
                    cell.routeImage.image = UIImage(named: "ic_arrow_downward_black_24dp")
                    break
                }
            }
            cell.visitImageView.isHidden = true
            cell.visitLabel.isHidden = true
            if let visits = model.visits, visits.filter({ ($0.numberOfStopsBetween ?? -1) > 0 }).count > 0 {
                let image = UIImage(named: "baseline_remove_red_eye_black_48")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
                cell.visitImageView.image = image
                cell.visitImageView.tintColor = UIColor.accent()
                if let visit = visits.filter({ ($0.numberOfStopsBetween ?? -1) > 0 && $0.timeAgoSeconds() > 0 }).first {
                    cell.visitImageView.isHidden = false
                    cell.visitLabel.isHidden = false
                    let stopString = visit.numberOfStopsBetween == 1 ? "stop" : "stops"
                    let timeAgo: Int = visit.timeAgoSeconds()
                    cell.visitLabel.text = "\(visit.numberOfStopsBetween!) \(stopString) away as of \(timeAgo)m ago"
                }
            }
        }
        
        cell.contentView.updateConstraints();
    }
    
    //MARK: line choice delegate
    
    func didSelectLineWithColor(_ color: UIColor) {
        for lineView in lineViews {
            if lineView.dotImageView.tintColor != color {
                lineView.isSelected = false
            }
        }
        
        filteredPredictionModels = predictionModels?.filter({AppDelegate.colorManager().colorForRouteId($0.routeId) == color})
        tableView.reloadData()
    }
    
    func didDeselectLineWithColor(_ color: UIColor) {
        filteredPredictionModels = predictionModels
        tableView.reloadData()
    }
    
    //MARK: table data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (filteredPredictionModels ?? [PredictionViewModel]()).count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "predCell") as! PredictionTableViewCell
        configurePredictionCell(cell, indexPath: indexPath)
        return cell
    }

}
