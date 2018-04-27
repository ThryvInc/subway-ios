//
//  StationViewController.swift
//  SubwayMap
//
//  Created by Elliot Schrock on 7/27/15.
//  Copyright (c) 2015 Thryv. All rights reserved.
//

import UIKit
import SubwayStations
import CoreGraphics
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
    var station: Station!
    var stationManager: StationManager!
    var predictions: [Prediction]?
    var predictionModels: [PredictionViewModel]?
    var filteredPredictionModels: [PredictionViewModel]?
    var routes: [Route] = [Route]()
    var lineModels: [LineViewModel] = [LineViewModel]()
    var lineViews = [LineChoiceView]()
    var favManager: FavoritesManager!
    var loading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.primaryDark()
        
        self.edgesForExtendedLayout = UIRectEdge()
        
        tableView.register(UINib(nibName: "PredictionTableViewCell", bundle: nil), forCellReuseIdentifier: "predCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView() //removes cell separators between empty cells
        
        title = station.name
        favManager = FavoritesManager(stationManager: stationManager)
        setupFavoritesButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        refresh()
    }
    
    func setupFavoritesButton() {
        let favButton = UIButton()
        favButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        if favManager.isFavorite(station.name){
            favButton.setImage(UIImage(named: "STARyellow")?.withRenderingMode(.alwaysOriginal), for: UIControlState())
        } else {
            favButton.setImage(UIImage(named: "STARgrey")?.withRenderingMode(.alwaysOriginal), for: UIControlState())
        }
        
        favButton.addTarget(self, action: #selector(StationViewController.toggleFavoriteStation), for: .touchUpInside)
        
        let favBarButton = UIBarButtonItem()
        favBarButton.customView = favButton
        self.navigationItem.rightBarButtonItem = favBarButton
    }

    func toggleFavoriteStation() {
        if favManager.isFavorite(station.name) {
            favManager.removeFavorites([self.station])
        } else {
            favManager.addFavorites([station])
        }
        setupFavoritesButton()
    }

    @IBAction func favoriteThisStation() {
        favManager.addFavorites([station])
        setupFavoritesButton()
    }
    
    func startLoading() {
        if !loading {
            loading = true
            spinLoadingImage(UIViewAnimationOptions.curveLinear)
        }
    }
    
    func stopLoading() {
        loading = false
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.loadingImageView.alpha = 0
        })
    }
    
    func spinLoadingImage(_ animOptions: UIViewAnimationOptions) {
        self.loadingImageView.alpha = 1
        UIView.animate(withDuration: 1.0, delay: 0.0, options: animOptions, animations: {
            self.loadingImageView.transform = self.loadingImageView.transform.rotated(by: CGFloat(M_PI))
            return
            }, completion: { finished in
                if finished {
                    if self.loading {
                        self.spinLoadingImage(UIViewAnimationOptions.curveLinear)
                    }else if animOptions != UIViewAnimationOptions.curveEaseOut{
                        self.spinLoadingImage(UIViewAnimationOptions.curveEaseOut)
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
        
        for prediction in uptown ?? [Prediction]() {
            let model = PredictionViewModel(routeId: prediction.route?.objectId, direction: prediction.direction)
            if !predictionModels!.contains(model) {
                model.setupWithPredictions(predictions)
                predictionModels?.append(model)
            }
        }
        
        for prediction in downtown ?? [Prediction]() {
            let model = PredictionViewModel(routeId: prediction.route?.objectId, direction: prediction.direction)
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
                let image = UIImage(named: "Grey")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate);
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
        let prediction = model.prediction
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.none
        formatter.timeStyle = DateFormatter.Style.short
        cell.timeLabel.text = formatter.string(from: (prediction?.timeOfArrival!)!).lowercased()
        cell.deltaLabel.text = "\((prediction?.secondsToArrival!)! / 60)m"
        
        if let route = prediction?.route {
            cell.routeLabel.text = route.objectId
            let image = UIImage(named: "Train")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate);
            cell.routeImage.image = image
            cell.routeImage.tintColor = AppDelegate.colorManager().colorForRouteId(route.objectId)
        }
        
        if prediction?.direction == .uptown {
            cell.routeImage.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
            cell.routeLabelOffset.constant = 5
        }else{
            cell.routeImage.transform = CGAffineTransform(rotationAngle: 0)
            cell.routeLabelOffset.constant = -5
        }
        
        if let nextPrediction = model.onDeckPrediction {
            cell.onDeckLabel.text = formatter.string(from: nextPrediction.timeOfArrival!).lowercased()
        }
        
        if let finalPrediction = model.inTheHolePrediction {
            cell.inTheHoleLabel.text = formatter.string(from: finalPrediction.timeOfArrival!).lowercased()
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
